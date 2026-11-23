import 'package:flutter/widgets.dart';

import '../data/entitlement.dart';
import 'curriculum_service.dart';

/// 무료/유료 경계 — ~/talkverse/PAYWALL_SPEC.md §2(2026-11-23, uk 정함, 사용자 「1 2 모두 진행」).
/// 무료: 커리큘럼 1단계·회화 R0·R1·문법 1~2스텝·언어감각 1급. 나머지는 이용권.
/// 잠금 값은 서버(커리큘럼 JSON: 단계 free, 최상위 freeSteps·freeSenseLevels)가 주고, 없으면 기본값.
/// 잠긴 곳은 숨기지 않고 자물쇠 → 누르면 결제 화면.
class Access {
  Access._();

  /// 테스트에서 이용권 유무를 정할 때.
  @visibleForTesting
  static bool? premiumOverride;

  static bool get premium => premiumOverride ?? Entitlement.premium;

  static Map<String, dynamic>? get _cfg => CurriculumService.instance.cfg;

  static int _int(Object? v, int def) => v is num && v >= 0 ? v.toInt() : def;

  /// 문법 무료 스텝 수(기본 2).
  static int get freeSteps => _int(_cfg?['freeSteps'], 2);

  /// 언어감각 무료 급 수(기본 1).
  static int get freeSenseLevels => _int(_cfg?['freeSenseLevels'], 1);

  /// 커리큘럼 단계가 무료인가 — 단계 JSON 의 free, 없으면 1단계만. 옛 회화 레벨(R0·R1)도 무료.
  static bool stageFree(String? lv) {
    if (lv == null) return true;
    for (final x in (_cfg?['stages'] as List? ?? const [])) {
      if (x is Map && '${x['n']}' == lv && x['free'] is bool) return x['free'] as bool;
    }
    return lv == '1' || lv == 'R0' || lv == 'R1';
  }

  /// 회화 편(레벨 R) 이 무료인가 — R0·R1 만.
  static bool regionFree(String region) => region == 'R0' || region == 'R1';

  static bool stepFree(int step) => step <= freeSteps;

  /// [index] = 언어감각 급 순서(1부터).
  static bool senseFree(int index) => index <= freeSenseLevels;

  static bool canStage(String? lv) => premium || stageFree(lv);
  static bool canRegion(String region) => premium || regionFree(region);
  static bool canStep(int step) => premium || stepFree(step);
  static bool canSense(int index) => premium || senseFree(index);

  /// 잠겨 있으면 결제 화면을 열고 false.
  static Future<bool> ensure(BuildContext context, bool ok) async {
    if (ok) return true;
    await Entitlement.showPaywall(context);
    return false;
  }
}
