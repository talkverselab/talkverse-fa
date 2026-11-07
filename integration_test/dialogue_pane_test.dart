// 아이패드 두 화면 + 만화책 읽기형 회화 확인용 스크린샷 흐름 — 2026-11-02(일본어앱 dialogue_pane_test 를 옮김).
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <출력폴더> integration_test/dialogue_pane_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_universe/core/l10n.dart';
import 'package:persian_universe/data/db/app_database.dart';
import 'package:persian_universe/data/db/seed_loader.dart';
import 'package:persian_universe/main.dart';
import 'package:persian_universe/services/achievement_service.dart';
import 'package:persian_universe/services/ko_reading.dart';
import 'package:persian_universe/services/learner_prefs.dart';
import 'package:persian_universe/widgets/glyph_sheet.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 2000);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 3000);
  }

  Finder rail(String label) => find.descendant(of: find.byType(NavigationRail), matching: find.text(label));

  testWidgets('dialogue pane', timeout: const Timeout(Duration(minutes: 10)), (t) async {
    appDb = AppDatabase();
    await SeedLoader(appDb).seedIfNeeded();
    await KoReadingPrefs.load();
    await AppLangPrefs.load();
    await LearnerPrefs.load();
    await AchievementService.instance.load();
    await t.pumpWidget(const PersianUniverseApp());
    await wait(t, 1500);
    await shot(t, '01_home_wide');

    await t.tap(find.text('회화').at(1)); // 0 = 섹션 머리글
    await wait(t, 2500);
    await shot(t, '02_dialogue_home_right');

    await t.tap(find.text('사랑').first);
    await wait(t, 1200);
    await shot(t, '03_topic_list');

    await t.tap(find.text('첫 인사').first);
    await wait(t, 1500);
    await shot(t, '04_reader');

    // 글자 시트(UX 시안 FA-01 ①): 캡션의 페르시아어 줄 낱말 탭
    await t.tap(find.byType(TappablePersianText).first, warnIfMissed: false);
    await wait(t, 1500);
    await shot(t, '04b_glyph_sheet');
    Navigator.of(t.element(find.byType(GlyphSheet))).pop();
    await wait(t, 1000);

    await t.tap(find.text('재생').first);
    await wait(t, 6000);
    await shot(t, '05_reader_playing');

    await t.tap(find.byTooltip('그림 카드(글자 없이)'));
    await wait(t, 1500);
    await shot(t, '06_card_front');
    await t.tap(find.text('탭해서 확인'));
    await wait(t, 800);
    await shot(t, '07_card_back');
    await t.pageBack();
    await wait(t, 1200);

    await t.tap(rail('진행'));
    await wait(t, 1500);
    await shot(t, '08_progress_achievements');

    await t.tap(rail('프로필'));
    await wait(t, 1500);
    await shot(t, '09_profile');
  });
}
