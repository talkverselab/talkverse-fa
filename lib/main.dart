import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'data/account.dart';
import 'data/purchase.dart';
import 'services/achievement_service.dart';
import 'services/learner_prefs.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'screens/main_screen.dart';
import 'screens/sync_screen.dart';
import 'services/content_sync.dart';
import 'services/ko_reading.dart';
import 'core/l10n.dart';

late final AppDatabase appDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  await AppLangPrefs.load();
  await LearnerPrefs.load();
  await AchievementService.instance.load();
  // Talkverse ID(선택 로그인)·스토어 평생 이용권 — 기다리지 않는다(오프라인이어도 앱은 바로 뜬다)
  Account.load();
  Purchase.configure({'fa': ('com.talkverse.persianUniverse.lifetime', 'lang_fa')});
  await _setOrientations(); // 폰은 세로 고정, 태블릿·폴드 펼침(짧은 변 600 이상)은 회전 허용
  // 그림(장면 컷·단어 그림) 기기 내려받기: 버전이 다르면 로딩 화면에서 받고 시작(사용자 지시 2026-11-04)
  final needSync = await ContentSync.instance.init(large: _wide ?? false);
  runApp(PersianUniverseApp(syncFirst: needSync));
}

bool? _wide;

/// 짧은 변 600 이상(아이패드·태블릿·폴드 펼침)이면 가로 회전 허용, 아니면 세로 고정(일본어앱과 같음).
/// 폴드를 접고 펼 때마다 builder 에서 다시 계산한다.
Future<void> _setOrientations([double? shortest]) async {
  shortest ??= () {
    final v = WidgetsBinding.instance.platformDispatcher.views.first;
    return v.physicalSize.shortestSide / v.devicePixelRatio;
  }();
  final wide = shortest >= 600;
  if (wide == _wide && shortest != 0) return;
  _wide = wide;
  await SystemChrome.setPreferredOrientations(wide ? DeviceOrientation.values : [DeviceOrientation.portraitUp]);
}

class PersianUniverseApp extends StatelessWidget {
  final bool syncFirst;
  const PersianUniverseApp({super.key, this.syncFirst = false});

  @override
  Widget build(BuildContext context) {
    // 표시 언어가 바뀌면 key 가 바뀌어 앱 전체가 새로 그려진다 (홈으로 돌아감).
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLangPrefs.lang,
      builder: (context, lang, _) => MaterialApp(
        key: ValueKey(lang),
        title: tr('페르시아어유니버스'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        // 아이폰 Dynamic Type·갤럭시 글자 크기 설정이 커도 타일이 깨지지 않게 1.2배까지만
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          WidgetsBinding.instance.addPostFrameCallback((_) => _setOrientations(mq.size.shortestSide));
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: syncFirst ? const SyncScreen(next: MainScreen()) : const MainScreen(),
      ),
    );
  }
}
