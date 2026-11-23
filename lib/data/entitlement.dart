import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 이용권 — Talkverse 계정 이용권(lang 'fa', auth.talkverse.uk) OR 이 기기에서 산·복원한 스토어 구매(언어 1m·3m·1y·평생 또는 종합 all_*, 2026-11-09).
/// 잠그는 범위는 lib/services/access.dart(PAYWALL_SPEC §2, 2026-11-23): 커리큘럼 2단계~·회화 R2~·문법 3스텝~·언어감각 2급~.
class Entitlement {
  Entitlement._();
  static const lang = 'fa';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
