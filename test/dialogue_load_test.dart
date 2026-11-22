import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persian_universe/services/dialogue_service.dart';

/// 새 회화 편(R1~R3 주제별 파일)을 앱 안에서 읽는지 — 2026-11-18.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  test('R 편을 읽고 옛 L1 로 돌아가지 않는다', () async {
    final svc = DialogueService.instance;
    await svc.ensureLoaded();
    expect(svc.all.length, greaterThanOrEqualTo(40));
    expect(svc.regions, ['R1', 'R2', 'R3']);
    final d = svc.byId('r1_friends_b1')!;
    expect(d.turns.first.tl, isNotEmpty);
    expect(d.turns.first.gloss, isNotEmpty); // 테헤란 입말 칸
    expect(d.voiceGender('B'), anyOf('male', 'female'));
  });
}
