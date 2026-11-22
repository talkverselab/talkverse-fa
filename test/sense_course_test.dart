import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_universe/screens/sense_course_screen.dart';

void main() {
  test('언어감각 원고 — 10급, 급마다 외울 대화 10줄 + 참고, 표시 번호가 양쪽 같음, 독음 글자', () {
    final d = json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>;
    final levels = (d['levels'] as List).cast<Map<String, dynamic>>();
    expect(levels.length, 10);
    final mark = RegExp(r'\{([^|}]+)\|(\d+)\}');
    final rd = RegExp(r'^[가-힣0-9 ,.!?…"·~\-{}_a-z()]*$');
    for (final lv in levels) {
      final ls = (lv['lessons'] as List).cast<Map<String, dynamic>>();
      expect(ls.map((l) => l['kind']), ['memorize', 'ref']);
      final ss = (ls[0]['sentences'] as List).cast<Map<String, dynamic>>();
      expect(ss.length, 10);
      for (final s in ss) {
        expect({for (final m in mark.allMatches(s['fa'] as String)) m.group(2)}, {for (final m in mark.allMatches(s['ko'] as String)) m.group(2)}, reason: s['fa'] as String);
        expect(plainMarked(s['fa'] as String).contains('{'), isFalse);
        expect(rd.hasMatch(s['rd'] as String), isTrue, reason: s['rd'] as String);
        expect(['나', '사라', '네가르', '아라시', '레자'], contains(s['who']));
      }
      for (final p in (ls[1]['points'] as List).cast<Map<String, dynamic>>()) {
        for (final s in (p['sentences'] as List).cast<Map<String, dynamic>>()) {
          expect(rd.hasMatch(s['rd'] as String), isTrue, reason: s['rd'] as String);
          expect((s['fa'] as String).isNotEmpty && (s['ko'] as String).isNotEmpty, isTrue);
        }
      }
    }
  });

  test('목소리 성별 — 사라·네가르 여, 아라시·레자 남', () {
    expect(senseGender('사라'), 'female');
    expect(senseGender('네가르'), 'female');
    expect(senseGender('아라시'), 'male');
    expect(senseGender('레자'), 'male');
  });

  testWidgets('색 표시 — 같은 번호는 같은 색', (t) async {
    final a = markedSpans('{کیفِ|1} نگاره', const TextStyle()), b = markedSpans('네가르{의|1} 가방', const TextStyle());
    expect((a.first as TextSpan).style!.color, (b[1] as TextSpan).style!.color);
  });
}
