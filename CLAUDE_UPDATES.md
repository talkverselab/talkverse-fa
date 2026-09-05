# Claude 업데이트 메모 — persian_universe (fa)

> 기준 앱: chinese_universe(zh). 이식 세부 규격은 `zh/docs/PORTING_GUIDE_2026-09.md` 참고.
> 작성: 2026-09-05 (Claude Code 세션). 이후 변경은 git log 참고.

## 변경 이력
- `c6211ff` (2026-09-04) 기초 앱 스캐폴드 + 고유 런처 아이콘 (`ف`)

## 앱 생성 방식 (es 템플릿 스캐폴드)
- `flutter create` 후 spanish_universe(es)의 `lib/`·`assets/`·`pubspec.yaml`·`tool/parse_cotrip_generic.py` 복사.
- 클래스·문자열 치환(앱명·언어), `core/theme.dart` 색 값만 국기 팔레트로 교체(식별자 유지), TTS locale·보이스 필터 교체, 프로필 배지 교체.
- **콘텐츠는 빈 구조**: `assets/data/dialogues/L1.json`(episodes []) · `grammar/verbs_core.json`(verbs []) · `freq/lang_es_top.csv`(헤더만) · `assets/data/vocab/travel_words.json`·`travel_expressions.json`(themes []).
  - 회화·동사·빈도·단어·표현 메뉴는 열리지만 비어 있음.
- **콘텐츠 투입 방법**: co-Trip 형식(`| 한국어 | 원문 | 독음 |` 표, `##` 섹션 제목) MD가 생기면
  `py tool/parse_cotrip_generic.py <src.md> assets/data/vocab/travel_words.json assets/data/vocab/travel_expressions.json "<책이름>"`
  → 테마 자동 분류(제목 키워드)·단어/표현 분리·ko 키워드 아이콘 부여. 권말 사전 섹션은 DICT_SEC 정규식으로 제외(언어별 제목 패턴 확인 필요).
- 포함된 zh 기능: 주제별 단어 1×1 아이콘 타일 그리드 / 표현 목록 / 외우기 모드 / 외움 체크 / 독음 [한] 토글 (`topic_vocab_screen.dart`, `services/ko_reading.dart`, `services/memorized_store.dart`).

## 런처 아이콘
- `assets/icon/icon.png`·`icon_foreground.png` — 언어 상징 글자 `ف` + 국기 팔레트(PIL 생성). 17개 talkverse 앱 모두 다른 모양이어야 한다는 규칙.
- 재생성: pubspec의 `flutter_launcher_icons` 블록 → `dart run flutter_launcher_icons`.

## 미완료 / 후속
- 콘텐츠 전무 (위 투입 방법 참고). 회화(L1)·동사 활용 데이터도 비어 있음.
- CI 릴리스 파이프라인 없음 (zh의 `.github/workflows/android-release.yml` 복사 + Secrets 등록 시 USB 없이 설치 가능).
- ko_reading.dart는 표시 토글만 담당 — 독음 데이터는 콘텐츠 rd 필드에 직접 들어와야 함.

## 이 앱 고유 설정
- 팔레트: rojo=239F40(그린) gualda=DA0000(레드)
- TTS: fa-IR
- 메뉴 sub는 로마자 표기. **RTL 레이아웃 미대응** — 아랍 문자 콘텐츠 투입 전에 Directionality 처리 필요.
