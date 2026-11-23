import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs.dart';
import 'account.dart';

/// 판매 상품 하나(가격은 스토어가 정한다 — [krw] 는 스토어 가격을 못 받았을 때의 참고가).
/// 가격·상품 ID 규칙 = Talkverse 공통(2026-11-09 사용자 최종 확정, ~/talkverse/PRICING.md 앱 정가/할인가): 언어 1개 `lang_<코드>_1m`·`_3m`·`_1y`(자동 갱신 구독)·`_life`(비소모성),
/// 종합 패키지(모든 언어) `all_1y`·`all_life`. 앱 안에서는 사이트 가격을 안내·유도하지 않는다(스토어 규정).
class Plan {
  final String id;
  final int months; // 0 = 평생
  final bool bundle;
  final int krw; // 앱 할인가(스토어 판매가) — 스토어 가격을 못 받았을 때 표시
  final int listKrw; // 앱 정가(취소선 표기용, ~/talkverse/PRICING.md)
  const Plan(this.id, this.months, this.krw, {this.listKrw = 0, this.bundle = false});
  bool get lifetime => months == 0;
  bool get discounted => listKrw > krw;
  int get discountPct => discounted ? ((1 - krw / listKrw) * 100).round() : 0;
}

/// 이 앱의 판매 상품(~/talkverse/PRICING.md 앱 할인가·정가, 2026-11-09 확정). 스토어 등록 목록 = docs/store/STORE_PRODUCTS.md.
const kPlans = [
  Plan('lang_fa_1m', 1, 3900, listKrw: 5500),
  Plan('lang_fa_3m', 3, 9000, listKrw: 12900),
  Plan('lang_fa_1y', 12, 19900, listKrw: 28500),
  Plan('lang_fa_life', 0, 49000, listKrw: 69900),
  Plan('all_1y', 12, 79000, listKrw: 112900, bundle: true),
  Plan('all_life', 0, 329000, listKrw: 469000, bundle: true),
];

/// 앱 안 결제 — Talkverse 공용 클라이언트(한자앱 방식). 결제는 스토어(iOS StoreKit 2 · Android Play Billing),
/// 이용권 기록은 Talkverse ID(auth.talkverse.uk POST /me/purchases).
/// - 로그인 없이도 사고 복원할 수 있다(스토어가 기억 → 이 기기에 저장).
/// - 로그인돼 있으면 서버가 스토어에 확인해 계정 이용권으로 기록 → 다른 기기·다른 플랫폼에서도 열림. 로그인 전에 산 것은 로그인할 때 서버로 보낸다.
/// - 구독은 기기에 「구매 시각 + 기간 + 3일」까지만 열어 둔다. 자동 갱신되면 스토어가 새 거래를 보내 기한이 늘어난다(해지하면 그 기한에 닫힘).
///   기간의 최종 판단은 서버(계정 이용권)가 한다.
class Purchase {
  Purchase._();

  static String lang = 'fa';
  static List<Plan> plans = const [];
  /// 상품 ID → 만료 시각(ms, 평생이면 0)
  static final owned = ValueNotifier<Map<String, int>>(const {});
  static final products = ValueNotifier<Map<String, ProductDetails>>(const {});
  /// 구매 진행 상태 알림(화면이 듣고 안내): null = 없음, 'pending' · 'error' · 'done' · 'restored' · 'nothing'
  static final status = ValueNotifier<String?>(null);
  static StreamSubscription<List<PurchaseDetails>>? _sub;

  /// 통합 앱 연결(2026-11-09): false 면 이 패키지가 스토어 구매 스트림을 직접 듣지 않는다 —
  /// 통합 앱의 공용 결제가 스트림 하나를 듣고 [onPurchaseUpdates] 로 넘기며, completePurchase 도 통합 앱이 한다.
  /// 단독 앱은 true(예전과 같음). `embedInit()` 이 정한다.
  static bool ownStream = true;
  static bool _restoring = false, _restoredAny = false;
  /// 옛 평생 상품 ID(2026-11-02 첫 판) — 복원·영수증에 오면 `lang_<코드>_life` 로 친다.
  static const _legacy = {'com.talkverse.persianUniverse.lifetime': 'lang_fa_life', 'lang_fa': 'lang_fa_life'};

  static Plan? plan(String id) => plans.where((p) => p.id == id).firstOrNull;

  /// 이 언어를 열 수 있는가 — 언어 상품(lang_<코드>_*) 또는 종합(all_*) 중 기한이 남은 것이 있으면.
  static bool owns(String code) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return owned.value.entries.any((e) => (e.key.startsWith('lang_${code}_') || e.key.startsWith('all_')) && (e.value == 0 || e.value > now));
  }

  /// 상품을 스토어에서 못 받았음(연결 실패·빈 응답) — 결제 화면이 「잠시 뒤 다시 시도」를 보인다.
  static final productsFailed = ValueNotifier<bool>(false);
  static bool _quiet = false; // 앱 시작 때 조용한 복원 — 화면 알림(status)을 건드리지 않음

  /// 기기 저장 키(PAYWALL_SPEC §4, 11-23): 언어 접두 `<언어>_entitlement_v1`(Prefs 가 fa_ 를 붙임), 종합은 공통 `all_entitlement_v1` 에도.
  static const _keyLang = 'entitlement_v1';
  static const _keyAll = 'all_entitlement_v1';

  static Map<String, int> _decode(String? raw) {
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> configure(String code, List<Plan> list) async {
    lang = code;
    plans = list;
    final p = await Prefs.getInstance();
    final m = <String, int>{..._decode(p.getString('iap_owned2')), ..._decode(p.getString(_keyLang))};
    try {
      final shared = await SharedPreferences.getInstance(); // 접두 없는 공통 키 — 통합 앱에서 언어를 바꿔도 종합 이용권 유효
      m.addAll({for (final e in _decode(shared.getString(_keyAll)).entries) if (e.key.startsWith('all_')) e.key: e.value});
    } catch (_) {}
    if ((p.getStringList('iap_owned') ?? const []).contains(code)) m['lang_${code}_life'] = 0; // 옛 저장 방식(평생 하나)
    owned.value = m;
    Account.user.addListener(_onAccount);
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    if (ownStream) _sub ??= InAppPurchase.instance.purchaseStream.listen(onPurchaseUpdates, onError: (_) => status.value = 'error');
    await loadProducts();
    // 앱 시작 때 조용히 복원 조회(PAYWALL_SPEC §4) — 안드로이드만. iOS 는 Apple ID 암호 창이 뜰 수 있어
    // 미완료 거래 자동 수신(purchaseStream) + 「구매 복원」 단추만(uk 11-23 기준 통일). 통합 앱은 공용 결제가 맡는다.
    if (ownStream && Platform.isAndroid) {
      try {
        _quiet = true;
        await InAppPurchase.instance.restorePurchases();
        Future.delayed(const Duration(seconds: 6), () => _quiet = false);
      } catch (_) {
        _quiet = false;
      }
    }
  }

  /// 스토어 상품 받기 — 실패하거나 하나도 없으면 [productsFailed] = true(끝없이 기다리지 않게).
  static Future<void> loadProducts() async {
    productsFailed.value = false;
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
      productsFailed.value = true;
      return;
    }
    try {
      if (!await InAppPurchase.instance.isAvailable().timeout(const Duration(seconds: 8))) {
        productsFailed.value = true;
        return;
      }
      final r = await InAppPurchase.instance.queryProductDetails({for (final x in plans) x.id}).timeout(const Duration(seconds: 8));
      products.value = {for (final d in r.productDetails) d.id: d};
      productsFailed.value = products.value.isEmpty;
    } catch (_) {
      productsFailed.value = true;
    }
  }

  /// 스토어 표시 가격(예 ₩3,900). 상품을 못 받았으면 null.
  static String? price(String id) => products.value[id]?.price;

  static Future<bool> buy(String id) async {
    final d = products.value[id];
    if (d == null) {
      status.value = 'error';
      return false;
    }
    status.value = 'pending';
    // 자동 갱신 구독도 이 호출로 산다(in_app_purchase 는 구독·비소모성을 같은 경로로 처리).
    return InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: d));
  }

  /// 구매 복원(스토어 심사 요구). 결과는 [status] 로: 'restored' 또는 'nothing'.
  static Future<void> restore() async {
    _restoring = true;
    _restoredAny = false;
    status.value = 'pending';
    await InAppPurchase.instance.restorePurchases();
    // 복원할 것이 없으면 스트림에 아무것도 안 오는 플랫폼이 있다 — 잠시 뒤 결과를 정한다
    Future.delayed(const Duration(seconds: 4), () {
      if (_restoring) {
        _restoring = false;
        status.value = _restoredAny ? 'restored' : 'nothing';
      }
    });
  }

  static String? _known(String productId) {
    final id = _legacy[productId] ?? productId;
    return plan(id) != null || id.startsWith('lang_') || id.startsWith('all_') ? id : null;
  }

  /// 구매 갱신 처리. 단독 앱은 스토어 스트림이 직접 부르고, 통합 앱은 공용 결제가 이 언어 상품(lang_fa_*·all_*)만 골라 부른다.
  static Future<void> onPurchaseUpdates(List<PurchaseDetails> list) async {
    for (final pd in list) {
      final id = _known(pd.productID);
      switch (pd.status) {
        case PurchaseStatus.pending:
          if (!_quiet) status.value = 'pending';
        case PurchaseStatus.error:
          if (!_quiet) status.value = 'error';
        case PurchaseStatus.canceled:
          if (!_quiet) status.value = null;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (id != null) {
            await _grant(id, pd);
            _restoredAny = true;
            if (!_quiet || pd.status == PurchaseStatus.purchased) status.value = pd.status == PurchaseStatus.restored ? 'restored' : 'done';
            if (_restoring) _restoring = false;
          }
      }
      if (ownStream && pd.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(pd);
    }
  }

  static int _expiry(String id, PurchaseDetails pd) {
    final months = plan(id)?.months ?? (id.endsWith('_1m') ? 1 : id.endsWith('_3m') ? 3 : id.endsWith('_1y') ? 12 : 0);
    if (months == 0) return 0;
    final t = DateTime.fromMillisecondsSinceEpoch(int.tryParse(pd.transactionDate ?? '') ?? DateTime.now().millisecondsSinceEpoch);
    return DateTime(t.year, t.month + months, t.day + 3, t.hour, t.minute).millisecondsSinceEpoch;
  }

  static Future<void> _grant(String id, PurchaseDetails pd) async {
    final exp = _expiry(id, pd);
    final cur = owned.value[id];
    final keep = cur != null && (cur == 0 || (exp != 0 && cur > exp)); // 더 긴 기한이 있으면 유지
    if (!keep) owned.value = {...owned.value, id: exp};
    final p = await Prefs.getInstance();
    await p.setString(_keyLang, jsonEncode(owned.value));
    await p.setString('iap_owned2', jsonEncode(owned.value)); // 옛 키도 당분간 같이(되돌릴 때 대비)
    if (id.startsWith('all_')) {
      try {
        final shared = await SharedPreferences.getInstance();
        final all = _decode(shared.getString(_keyAll));
        final c = all[id];
        if (!(c != null && (c == 0 || (exp != 0 && c > exp)))) all[id] = exp;
        await shared.setString(_keyAll, jsonEncode(all));
      } catch (_) {}
    }
    // 서버로 보낼 영수증 — 로그인 전이면 쌓아 두었다가 로그인 때 보낸다
    final rec = {
      'platform': Platform.isIOS ? 'ios' : 'android',
      'product_id': pd.productID,
      if (Platform.isIOS) 'transaction_id': pd.purchaseID,
      if (Platform.isAndroid) 'purchase_token': pd.verificationData.serverVerificationData,
    };
    await p.setStringList('iap_pending', {...?p.getStringList('iap_pending'), jsonEncode(rec)}.toList());
    await _flush();
  }

  static void _onAccount() {
    if (Account.signedIn) _flush();
  }

  /// 쌓인 영수증을 계정에 붙인다. 실패한 것은 남겨 두고 다음에 다시.
  static Future<void> _flush() async {
    final at = Account.signedIn ? await Account.accessToken() : null;
    if (at == null) return;
    final p = await Prefs.getInstance();
    final left = <String>[];
    var sent = false;
    for (final s in [...?p.getStringList('iap_pending')]) {
      try {
        final r = await http.post(Uri.parse('${Account.base}/me/purchases'),
            headers: {'Authorization': 'Bearer $at', 'Content-Type': 'application/json'},
            body: jsonEncode({...jsonDecode(s) as Map<String, dynamic>, 'client_id': Account.clientId})).timeout(const Duration(seconds: 15));
        if (r.statusCode == 200) {
          sent = true;
        } else if (r.statusCode >= 500 || r.statusCode == 401) {
          left.add(s); // 서버 준비 전·일시 오류 → 다시
        } // 400(잘못된 영수증)은 버린다
      } catch (_) {
        left.add(s);
      }
    }
    await p.setStringList('iap_pending', left);
    if (sent) await Account.refresh(); // 이용권 다시 받기
  }
}
