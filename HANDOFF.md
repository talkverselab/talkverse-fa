# HANDOFF — talkverse-fa (페르시아어 유니버스) · 2026-11-09 (세션 종료 때 전체 다시 씀)

## 상태 한눈에

| 항목 | 상태 |
|---|---|
| 공통 프롬프터(`~/talkverse/LANG_APP_REPLICATE_PROMPT.md`) | ① 캐릭터 통과(11-03) · ② UX 통과(11-03) · ③ 아이패드 빌드 완료 · ④ 회화 Claude 초안 완료(11-07, 사용자 지시로 제한 해제) → Grok·Gemini 대기. 소수언어 정책: 앱 전체 150편 이내, R1~R3 만 |
| Android | CI 빌드 16(`6cc3a7e`, 통합 앱 연결 준비) → Zealot https://apps.talkverse.uk/O2wYW/420 , PC `D:\OneDrive\app project\talkverse-fa\talkverse-fa-latest.apk`(+ `.txt`). Zealot 앱이름 「페르시아어유니버스」. (399 는 실수로 빌드 14 를 한 번 더 올린 것) |
| iOS | TestFlight `2611091208`(`6cc3a7e`, Android 16 과 같은 커밋), IPA PC `D:\OneDrive\app project\persian_universe\ios\` |
| 통합 앱(Talkverse) | **연결 준비 끝(`6cc3a7e`, uk 에 보고함)** — 패키지 `persian_universe`, 콜백 `talkverse.fa://auth`, `lib/embed.dart`(embedInit·embedApp), `lib/core/embed_env.dart`(assetPath·`fa_` 접두·dataDir·dbName), `lib/core/prefs.dart`(SharedPreferences 를 `fa_` 접두로, 단독 앱 옛 키 1회 이전). 통합 모드: clientId `talkverse`, DB `fa_universe`, 결제 스트림은 통합 앱이(`Purchase.ownStream=false`·`onPurchaseUpdates`), 프로필 맨 위 「다른 언어 배우기」. **단독 앱 DB 이름은 템플릿의 옛 이름 `spanish_universe` 그대로**(바꾸면 기록 끊김). drift 2.34.4·drift_flutter 0.3.1·sqlite3_flutter_libs 0.6.0+eol. **통합 앱 자체는 손대지 않는다**(uk 담당). 새 에셋 폴더를 만들면 uk 에 알린다 |
| 결제 | 확정 가격표(`~/talkverse/PRICING.md`, 2026-11-09): `lang_fa_1m`·`_3m`·`_1y`(자동 갱신)·`_life`, `all_1y`·`all_life`, 앱 할인가 + 정가 취소선(`lib/data/purchase.dart` `kPlans`). 결제 시트 규정 표기·구매 복원·약관/방침 링크(`widgets/legal_links.dart`). **잠그는 화면 없음** |
| 출시 | **아직 아님.** 지금 출시는 한자앱뿐, 언어앱은 완성된 것부터 하나씩. 4.3 차별화 설명·심사 메모 `docs/store/listing.md`·`review_notes.md`, 상품 목록 `docs/store/STORE_PRODUCTS.md`, 스크린샷 시안 `data/review/store_shots/`(시뮬레이터 상단 표시가 찍혀 제출용은 다시). 남은 것 = listing.md 맨 위(회화 연결·빈 메뉴·음성·임시 조음 그림) |
| 회화 | **Claude 초안 146편(로컬만, 커밋 안 함)**: R1 83 · R2 35 · R3 28, 1,467턴, chaos 46편(32%). `assets/data/dialogues/R<n>/<주제>/<편id>.json`, 칸 `tl`=글말·`tl_col`=테헤란 입말·`rd`=입말 독음·`emotion`/`segs`(음성 감정)·편 `cast`(목소리). 계획 `data/dialogue_plan_fa.csv`, 규칙 `tools/prompts/dialogue_fa.md`, 표현 풀 `data/expressions/top_expressions.csv`, 검사 `tools/check_dialogues_fa.py`(146편 오류 0). **앱은 아직 옛 `L1.json`(5편)을 읽는다**(`dialogue_service`, pubspec 에 하위 폴더 없음) |
| 회화 음성 | 시험 2편(r1_friends_b1·r1_love_a3, R2 만 · D1 안 넣음), 22조각 중 21 통과. VoxCPM2 에 페르시아어가 없어 참고 음성은 아랍어, 본문은 MOSS language=Persian(리뷰 페이지에 표시). 계획은 회화 칸에서 `tools/tts/make_plan.py` 로 자동, 실행 `tools/tts/run_trial.py`(파이썬 `~/.venvs/tts_zh/bin/python`, 작업 폴더 `~/tts_work/fa`). 글자/초 중앙값 7.1 — pack RATE 9.5 라 대부분 1.15배로 빨라짐(사용자 청취 뒤 조정). **전편은 사용자 판단 + uk 「지금 시작」 뒤**(PC 는 한 번에 한 세션), Grok 재작성 뒤에 만드는 편이 낫다 |
| 리뷰 페이지 | `data/review/REVIEW_fa.html`(`tools/review_fa.sh`, 시험 2편 음성 + 146편 글) — uk 에 「REVIEW_fa 갱신」 보냄 → https://talkverse.uk/talkverse/review/fa/ , 저장 API `/api/review/fa` |
| 절벽·단어 | R1 50 · R2 72 · R3 185(55/60/70%), 561 = 80%, 1,500 = 87.3%(`lib/core/cliff.dart`, `data/cliff_2026-11-03/` 커밋 안 함). 절벽 단어 1,500 + 회화 보충, 20어 단원 타일. 그림 리스트 `talkverselab/talkversehanja` `talkverse_art/words/fa.csv`·`fa_food.csv` |

## 화면(이번까지 만든 것)
- 홈 메뉴: **기초**(문자와 발음 · 키보드 연습) → 문법(문법·동사 활용) → 회화(회화·문장 말하기·문장 카드) → 단어(절벽 단어·단어·단어 카드·표현) → 에피소드 → 참고(청크 검색). 아이패드 두 화면, 만화책 리더, 성과 데스크, 앱 소개.
- **문자와 발음**(11-08, §5-3): `screens/alphabet_screen.dart` + `widgets/fa_sound_sheet.dart` + `services/persian_phonetics.dart`. 조음 위치 그림 `assets/images/ipa/places_of_articulation.png` 는 **임시·출처 표기 없음(사용자 지시) — 출시 전 Grok 그림으로 교체**. 발음 설명은 원어민 검수 전.
- **키보드 연습**(11-08, 「아랍어앱 키보드 가져오기」 = 옛 아랍어앱 `~/talkverse/_legacy/ar`): `screens/keyboard_screen.dart` + `widgets/persian_keyboard_guide.dart`.
- 글자 시트(문장 낱말 길게 누름), 낱말 탭 = 단어창, 입말 칩(데이터는 새 회화 연결 뒤), 한글독음 기본 숨김.
- 확인: `flutter analyze` 0, `flutter test` 11개, 아이폰 시뮬레이터로 홈·프로필·문자와 발음·키보드·결제 시트·통합 준비 뒤 단독 실행(키 이전·폴더·에셋) 확인.

## 회화 다음 순서(사용자 지시, uk 전달)
Claude 초안(끝) → **Grok 재작성(11/9 13:30 재개 공지)** → **Gemini 검수**(fa 포함, `~/talkverse/GEMINI_REVIEW_GUIDE.md`: 3.1 Pro, `-j 1 --gap 60`, 한 번에 한 세션, BLOCKED 면 멈추고 알림, 샘플 먼저) → 실제 오류만 반영(`emotion`·`segs` 유지, `make_plan.py` 다시) → 리뷰 통과 → 앱 연결(`dialogue_service` 가 R 폴더를 읽게, pubspec 폴더 단위 추가, version.json db 번호 올림, `tools/add_lemmas_fa.py`) → 장면 컷 → 전편 음성.
- Gemini 틀 `tools/prompts/review_gemini_fa.md`, 생성 `tools/gemini_prompts_fa.py`, 도구 `tools/gemini_send.py`·`gemini_batch.py`.
- 다시 볼 것: 말장난 `رئیس/ریش`(r2_work_b2)·`ما عسلی‌ایم/ماه عسلیم`(r2_travel_b2), 수위 `پدرسوخته`(r3_friends_b4)·`گند`(r1_life_a2, `profanity_mild`), R1 장면어 초과, R3 감정이 턴마다 하나.
- 글말/입말 두 칸은 `DIALOGUE_NOTES.md` 의 「제안」을 따른 것 — 사용자 확인 전.

## 사용자 결정·할 일
1. 시험 음성 청취(아랍어 억양·속도) → 전편 생성 여부.
2. 무엇을 유료로 잠글지(정하기 전 IAP 등록하지 않음), 스토어 상품 등록, Sign in with Apple(App ID), TestFlight 내부 그룹.
3. 회화 초안·도구 커밋 여부(로컬만 있음 — 올릴 때 `[skip ci]`).
4. 결제 시트 종합 평생의 정가 취소선(「할인 없음」이라 빼야 하면 `kPlans` 의 `listKrw` 0).
5. Play 프로텍트 경고, CLAUDE.md §2 「앱 업데이트」 설명(옛 내용) 정리.

## 공통 절차(이 저장소)
- **앱을 고치면 Android(Zealot)·iOS(TestFlight)를 함께**(사용자 지시 11-07). Zealot = CI APK(`gh release download latest -R talkverselab/talkverse-fa -p '*.apk'`, `latest.json` 의 sha 가 새 커밋인지 확인 — **release.yml 실행을 기다릴 것, iOS 워크플로가 아님**) → apksigner SHA-1 `9cc4bc93…` → `~/bin/zealot-upload` → PC 백업. iOS = `bash tools/ios_release.sh`(백그라운드), 뒤에 pbxproj·xcconfig·xcscheme·xcworkspace `git checkout --`.
- 서명 키 새로 만들지 말 것, M6 의 `~/.android/debug.keystore` 는 다른 키(CLAUDE.md §1·§8).
- 커밋은 경로 지정, CRLF 잡음 커밋 금지, 공개 저장소(출처·작품·말뭉치 이름 금지). 아이콘은 uk 세션.
- 디스크: 11-09 M6 가 한 번 꽉 찼다(빌드·시뮬레이터). `build/` 와 scratchpad APK 는 지워도 된다(PC 백업 있음).
- Grok·Gemini 는 M4 Chrome(`~/talkverse/GROK_M4_LOGIN.md`, `GROK_PROMPT_GUIDE.md`), 한 번에 한 작업, 탭·Chrome 은 끝나면 닫는다.
- **Grok 재개(2026-11-09 허브 공지 `~/logs/rc/RELAY_grok_20261109.md`)**: 옛 계정 다시 로그인(M4 uk 크롬 포트 9231, uk 의 방은 건드리지 말 것). 자기 크롬을 켠 뒤 `ssh macmini4 /usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 <자기 포트>` 로 쿠키 동기화. **한자 세션은 더 이상 대행하지 않는다** — 직접 처리, 요청 도구는 M6 `~/Hanja/tools/grok_req.py`·`grok_cdp.py` 를 이 저장소 `tools/` 로 복사해 쓴다. 회화 Grok 재작성은 여전히 사용자 지시 뒤.
