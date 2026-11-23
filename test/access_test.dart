import 'package:flutter_test/flutter_test.dart';
import 'package:persian_universe/screens/sense_course_screen.dart';
import 'package:persian_universe/services/access.dart';
import 'package:persian_universe/services/curriculum_service.dart';

/// 무료/유료 경계 — PAYWALL_SPEC §2(2026-11-23).
void main() {
  final svc = CurriculumService.instance;
  late Map<String, dynamic>? keep;
  setUp(() => keep = svc.cfg);
  tearDown(() {
    svc.cfg = keep;
    Access.premiumOverride = null;
  });

  test('커리큘럼: 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림(서버 free 값 우선, 없으면 1단계만)', () {
    svc.cfg = {
      'rev': 2,
      'freeSteps': 2,
      'freeSenseLevels': 1,
      'stages': [
        {'n': 1, 'free': true, 'dialogueIds': []},
        {'n': 2, 'free': false, 'dialogueIds': []},
        {'n': 3, 'dialogueIds': []},
      ],
    };
    Access.premiumOverride = false;
    expect(Access.canStage('1'), isTrue);
    expect(Access.canStage('2'), isFalse);
    expect(Access.canStage('3'), isFalse);
    Access.premiumOverride = true;
    expect(Access.canStage('2'), isTrue);
    svc.cfg = {
      'rev': 2,
      'stages': [
        {'n': 2, 'free': true, 'dialogueIds': []},
      ],
    };
    Access.premiumOverride = false;
    expect(Access.canStage('2'), isTrue);
  });

  test('문법 3스텝부터 잠김, 2스텝까지 열림 · 서버 freeSteps 대로', () {
    svc.cfg = null;
    Access.premiumOverride = false;
    expect(Access.canStep(2), isTrue);
    expect(Access.canStep(3), isFalse);
    svc.cfg = {'rev': 2, 'freeSteps': 4, 'stages': [{'n': 1, 'dialogueIds': []}]};
    expect(Access.canStep(4), isTrue);
    expect(Access.canStep(5), isFalse);
    Access.premiumOverride = true;
    expect(Access.canStep(9), isTrue);
  });

  test('언어감각 1급 열림 · 2급 잠김, 급 번호는 데이터 순서', () {
    svc.cfg = null;
    Access.premiumOverride = false;
    final d = {
      'levels': [
        {'id': 'L1', 'lessons': [{'id': 'a', 'sentences': [{'fa': 'x'}]}, {'id': 'a2', 'kind': 'ref', 'points': [{'h': 1}]}]},
        {'id': 'L2', 'lessons': [{'id': 'b', 'sentences': [{'fa': 'y'}]}]},
      ]
    };
    final all = SenseCourse.flat(d);
    expect([for (var i = 0; i < all.length; i++) SenseCourse.levelNo(all, i)], [1, 1, 2]);
    expect(Access.canSense(1), isTrue);
    expect(Access.canSense(2), isFalse);
    Access.premiumOverride = true;
    expect(Access.canSense(2), isTrue);
  });

  test('회화: R1 무료 · R2 잠김', () {
    Access.premiumOverride = false;
    expect(Access.canRegion('R1'), isTrue);
    expect(Access.canRegion('R0'), isTrue);
    expect(Access.canRegion('R2'), isFalse);
    Access.premiumOverride = true;
    expect(Access.canRegion('R3'), isTrue);
  });
}
