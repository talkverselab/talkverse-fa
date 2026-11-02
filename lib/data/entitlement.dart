import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 평생 이용권 — Talkverse 계정 이용권(lang 'fa', auth.talkverse.uk) OR 이 기기에서 산·복원한 스토어 구매(2026-11-02).
/// 아직 잠그는 화면은 없다(무엇을 유료로 할지 사용자 결정 전) — 지금은 모든 기능이 무료.
class Entitlement {
  Entitlement._();
  static const lang = 'fa';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
