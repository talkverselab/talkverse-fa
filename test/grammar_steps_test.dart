import 'package:flutter_test/flutter_test.dart';
import 'package:persian_universe/screens/grammar_lesson_screen.dart';
import 'package:persian_universe/screens/sense_course_screen.dart';

/// 문법 스텝 틀(사용자 11-23): 스텝 수는 데이터대로, 내용 없는 스텝·급은 숨김.
void main() {
  test('스텝 번호는 있는 파일대로 — 15 이상도, 다른 파일은 무시', () {
    expect(
      GrammarLesson.stepNumbers([
        'grammar/lesson3.json',
        'grammar/lesson1.json',
        'grammar/lesson15.json',
        'grammar/lesson12.json',
        'grammar/sense_course.json',
        'dialogues/R1/love/r1_love_a3.json',
        'grammar/lesson1.json',
      ]),
      [1, 3, 12, 15],
    );
  });

  test('서버 목록: 빠지면 안 보임 · 더해지면 보임 · 못 받으면 묶음 목록', () {
    final bundled = ['grammar/lesson1.json', 'grammar/lesson2.json', 'grammar/lesson3.json'];
    // 서버를 못 받음 → added·removed 없음 → 묶음 그대로
    expect(GrammarLesson.stepNumbers(bundled), [1, 2, 3]);
    // 서버가 2 를 빼고 16 을 더함
    expect(GrammarLesson.stepNumbers([...bundled, 'grammar/lesson16.json'], removed: {'grammar/lesson2.json'}), [1, 3, 16]);
  });

  test('내용(패턴) 없는 스텝은 null(숨김), 있으면 강의', () {
    expect(GrammarLesson.fromJson(2, {'title': '빈 스텝', 'patterns': []}), isNull);
    expect(GrammarLesson.fromJson(2, {'title': '빈 스텝'}), isNull);
    final l = GrammarLesson.fromJson(4, {
      'title': '스텝 4',
      'patterns': [
        {'examples': [{'tl': 'a'}, {'tl': 'b'}]}
      ]
    })!;
    expect((l.number, l.title, l.exampleCount), (4, '스텝 4', 2));
  });

  test('언어감각: 내용 없는 급·회차는 숨김, 급 목록은 데이터 순서대로', () {
    final d = {
      'levels': [
        {'id': 'L1', 'title': '하나', 'lessons': [{'id': 'a', 'sentences': [{'fa': 'x'}]}]},
        {'id': 'L2', 'title': '빈 급', 'lessons': [{'id': 'b', 'sentences': []}]},
        {'id': 'L15', 'title': '열다섯', 'lessons': [{'id': 'c', 'points': [{'head': 'h'}]}, {'id': 'd'}]},
      ]
    };
    expect(SenseCourse.levels(d).map((l) => l['id']), ['L1', 'L15']);
    expect(SenseCourse.flat(d).map((e) => e.$2['id']), ['a', 'c']);
  });
}
