import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_universe/core/cliff.dart';
import 'package:persian_universe/screens/about_screen.dart';
import 'package:persian_universe/screens/word_freq_screen.dart';

/// 폰·아이패드 오른쪽 칸 너비에서 타일이 넘치지 않고, 구간 수가 절벽 값과 맞는지.
void main() {
  for (final w in [320.0, 390.0, 700.0]) {
    testWidgets('절벽 단어 $w', (t) async {
      rootBundle.clear(); // 앞 테스트의 가짜 시간 안에서 만든 캐시 Future 는 끝나지 않는다
      t.view.physicalSize = Size(w, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: WordFreqScreen()));
      for (var i = 0; i < 100 && find.text('1단원').evaluate().isEmpty; i++) {
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await t.pump();
      }
      expect(find.text('1단원'), findsOneWidget);
      expect(find.text('회화 단어 포함 (+17)'), findsOneWidget);
      await t.tap(find.text('회화 단어 포함 (+17)'));
      await t.pump();
      final ext = find.text('EXT · ${kCliffs[2] + 1}-$kWordCap');
      await t.ensureVisible(ext);
      await t.pump();
      await t.tap(ext);
      await t.pump();
      expect(find.text('#186-205'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('앱 소개', (t) async {
    await t.pumpWidget(const MaterialApp(home: AboutScreen()));
    expect(find.text('누적 87.3%'), findsOneWidget);
    expect(find.text('186-1500'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
