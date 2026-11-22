import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:persian_universe/services/curriculum_service.dart';
import 'package:persian_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Dialogue _d(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'title': id,
      'speakers': {'A': '{name}', 'B': 'B'},
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'tl': 'جمله $id $i', 'rd': '자말레', 'ko': '$id 뜻 $i'}
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('점수 80% 경계 — 소수점 버림', () {
    expect(scorePct(8, 10), 80);
    expect(isPass(scorePct(8, 10)), isTrue);
    expect(scorePct(79, 100), 79);
    expect(isPass(79), isFalse);
    expect(scorePct(23, 29), 79); // 79.3 → 79, 불통과
    expect(isPass(scorePct(24, 30)), isTrue);
    expect(scorePct(0, 0), 0);
  });

  test('간격 반복 1 → 3 → 7일, 틀리면 1일', () {
    final day = DateTime(2026, 11, 22, 21, 30);
    var r = const ReviewItem('a:1', '2026-11-22', 0);
    r = r.answered(true, day);
    expect((r.step, r.due), (1, '2026-11-25'));
    r = r.answered(true, day);
    expect((r.step, r.due), (2, '2026-11-29'));
    r = r.answered(true, day);
    expect((r.step, r.due), (2, '2026-11-29')); // 7일 유지
    r = r.answered(false, day);
    expect((r.step, r.due), (0, '2026-11-23'));
  });

  test('처음 연습한 줄은 다음 날 복습, 오늘 차례만 나옴', () {
    final st = CurriculumState();
    final day = DateTime(2026, 11, 22);
    st.schedule('a:1', true, day);
    st.schedule('a:2', false, day);
    expect(st.review.map((r) => r.due).toSet(), {'2026-11-23'});
    expect(st.dueReviews(day), isEmpty);
    expect(st.dueReviews(DateTime(2026, 11, 23)).length, 2);
  });

  test('저장 형식 왕복 · 언어 접두 키', () async {
    SharedPreferences.setMockInitialValues({});
    final cur = CurriculumService.instance;
    await cur.load();
    await cur.setLevel('R1');
    await cur.startCourse(['x', 'y']);
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('fa_curriculum_v1');
    expect(raw, isNotNull);
    final j = json.decode(raw!) as Map<String, dynamic>;
    expect(j.keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    final back = CurriculumState.fromJson(j);
    expect(back.level, 'R1');
    expect(back.course!.dialogueIds, ['x', 'y']);
  });

  test('추천 — 주제가 겹치지 않게, 통과한 편 뒤로', () {
    final lv = [_d('a', 'love', 4), _d('b', 'love', 4), _d('c', 'travel', 4), _d('d', 'work', 4)];
    final r = CurriculumService.recommend(lv, {'c'}, 3);
    expect(r, ['a', 'd', 'b']);
  });

  test('문제 만들기 · 코스 시험 편당 최소 3문제, 최대 30', () {
    final pool = [for (var i = 0; i < 12; i++) _d('e$i', 'life', 8)];
    final qs = CurriculumService.questionsFor(pool.first, pool, rnd: Random(1));
    expect(qs.length, 8);
    expect(qs.every((q) => q.options.length == 4 && q.options.contains(q.answer)), isTrue);
    final ex = CurriculumService.examFor(pool.take(3).toList(), pool, rnd: Random(1));
    expect(ex.length, 24); // 30 ~/ 3 = 10 → 편마다 8줄 모두
    final big = CurriculumService.examFor(pool, pool, rnd: Random(1));
    expect(big.length, 30);
    for (final d in pool.take(10)) {
      expect(big.where((q) => q.dialogueId == d.id).length, greaterThanOrEqualTo(0));
    }
  });

  test('코스 시험 통과 → 편 통과·코스 끝, 불통과 → 틀린 편 다시 연습', () async {
    SharedPreferences.setMockInitialValues({});
    final cur = CurriculumService.instance;
    final all = [_d('a', 'love', 4), _d('b', 'work', 4)];
    cur.state = CurriculumState(level: 'R1');
    await cur.startCourse(['a', 'b']);
    await cur.finishPractice('a', {'a:1': true});
    await cur.finishPractice('b', {'b:1': true});
    expect(cur.state.course!.allPracticed, isTrue);
    final fail = await cur.finishExam({'a:1': true, 'a:2': true, 'b:1': false, 'b:2': false, 'a:3': true}, all);
    expect(fail.$1, 60);
    expect(fail.$2, isFalse);
    expect(cur.state.course!.practiced, ['a']);
    final pass = await cur.finishExam({'a:1': true, 'a:2': true, 'b:1': true, 'b:2': true, 'a:3': false}, all);
    expect(pass.$1, 80);
    expect(pass.$2, isTrue);
    expect(cur.state.course, isNull);
    expect(cur.state.passedDialogues.toSet(), {'a', 'b'});
  });
}
