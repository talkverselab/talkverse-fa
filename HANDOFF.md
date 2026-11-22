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
| 회화 음성 | 시험 2편(r1_friends_b1·r1_love_a3, **11-10 사용자 지시 「모든 자산 db 에」로 R2+D1 `audio_lines` 30줄 올림**), 22조각 중 21 통과. VoxCPM2 에 페르시아어가 없어 참고 음성은 아랍어, 본문은 MOSS language=Persian(리뷰 페이지에 표시). 계획은 회화 칸에서 `tools/tts/make_plan.py` 로 자동, 실행 `tools/tts/run_trial.py`(파이썬 `~/.venvs/tts_zh/bin/python`, 작업 폴더 `~/tts_work/fa`). 글자/초 중앙값 7.1 — pack RATE 9.5 라 대부분 1.15배로 빨라짐(사용자 청취 뒤 조정). **전편은 사용자 판단 + uk 「지금 시작」 뒤**(PC 는 한 번에 한 세션), Grok 재작성 뒤에 만드는 편이 낫다 |
| 리뷰 페이지 | `data/review/REVIEW_fa.html`(`tools/review_fa.sh`, 시험 2편 음성 + 146편 글) — uk 에 「REVIEW_fa 갱신」 보냄 → https://talkverse.uk/talkverse/review/fa/ , 저장 API `/api/review/fa` |
| 절벽·단어 | R1 50 · R2 72 · R3 185(55/60/70%), 561 = 80%, 1,500 = 87.3%(`lib/core/cliff.dart`, `data/cliff_2026-11-03/` 커밋 안 함). 절벽 단어 1,500 + 회화 보충, 20어 단원 타일. 그림 리스트 `talkverselab/talkversehanja` `talkverse_art/words/fa.csv`·`fa_food.csv` |

## 2026-11-18 일본어앱 수준 맞추기(통합 앱 iOS 심사 준비, 일본어앱 전달문 `~/talkverse/ja/docs/RELAY_2026-11-18_ja_parity.md`)
- **사용자 결정: 「Gemini 검수 먼저」** — 회화 30%를 초안 그대로 올리지 않고 검수한 뒤 연결.
- **11-18 uk 전달 사용자 원칙(전 세션, `~/talkverse/LANG_APP_REPLICATE_PROMPT.md` §12)**: Claude 는 초안까지, 대사는 Grok(「빠른」, 모든 줄 새로, 「유지」 금지)이 쓰고 그대로 붙여 넣기 — Claude 는 형식(JSON·독음·감정 열·단어 칩)·검사기만. 11-10 의 「페르시아어 Grok 생략」은 이것으로 바뀜 → 순서 = **Grok 45편 → Gemini → 연결**. uk 에 「Grok 대사 작성 45편」 순서 요청 보냄(11-18, 답 대기). Grok 안 거친 것 보고함: 배포 앱의 옛 L1 5편, R2·D1 시험 음성 2편.
- 30% 고름(`data/review/select_30_fa.txt`): R1 25 · R2 11 · R3 9 = 45편, 주제별로 나눔, 음성 있는 2편 포함, 다시 볼 4편(말장난·수위) 뺌. 나머지 101편은 `data/dialogues_later/`(로컬)로 옮김. Gemini 목록 `data/gemini/prompts/list_30.tsv`.
- **로컬에 만들어 둠(커밋 안 함 — 회화 JSON 이 검수 전이라 CI 빌드가 깨지므로 함께 커밋)**: `lib/services/script_sync.dart`(일본어앱 그대로, `art/script/fa`), `dialogue_service.dart` 가 R 폴더+ScriptSync 를 읽음(R 편이 없을 때만 옛 L1), `embed.dart` 에서 ContentSync 앞에 refresh(15초), 회화 홈이 `revision` 에 다시 그림, pubspec 에 R 폴더 20개+`script_rev.json`(로컬 rev 1), `tools/script_publish.py`·`turn_lock.py`(대상 R1~R3), 시험 `script_sync_test`·`dialogue_load_test`. `flutter analyze` 0, 시험 15개 통과.
- **막힘: PC 크롬 9244 가 꺼져 있음(11-18 확인).** 사용자가 PC 에서 `chrome.exe --remote-debugging-port=9244 --remote-debugging-address=127.0.0.1 --user-data-dir=D:\chrome-grok-fa --no-first-run https://gemini.google.com` 을 띄우고 Google 로그인해야 함.
- **11-18 오후: Grok 45편 끝**(「빠른」, 방 2개 25+20, 골격만 보냄 → 초안과 줄별 유사도 대부분 0.2~0.7, 0.9↑ 줄은 다시 요청). `data/grok/w/<id>.md` → `fa_grok_io.py import` 로 회화 JSON 반영(`grok: true`), 한국어 칸 `؟`→`?` 정리, 독음은 Claude 가 채움(`data/grok/rd/*.rd.tsv`). uk 에 「Grok 끝」 보냄.
  - 검사기: 45편·452턴, 길이 오류 5편(r1_life_a1 t5·r1_love_a5 t5·r1_travel_a4 t1 = 11단어, r1_love_a3 t2·r1_survival_s1 t2·t4 = 1단어) → Gemini 지적과 함께 Grok 에 한 번에 다시 쓰게 할 것(Claude 수정 금지). ZWNJ 경고 2건은 کمی·جسمی 오탐.
  - 독음 쓰면서 이상해 보인 Grok 줄(Gemini 확인용): r2_travel_b3 #4·#9, r3_study_b1 #5(می‌خوام…لازم داریم), r2_culture_b1 #4(بدونِ).
  - Gemini 프롬프트 다시 만듦(`data/gemini/prompts30/`, `list_30.tsv` 갱신). **막힘: 9244 크롬 Gemini 비로그인(Flash-Lite) → 사용자 RustDesk 로그인 요청(푸시 보냄), 탭 열어 둠.**
- **11-22 (사용자 「검수해」 + uk 전달 「막힌 건 각자 판단대로 완료」) — 고른 것**:
  - Gemini: PC 9244 Google 로그인 대신 **M4 9226(chrome-grok-vi, 로그인됨)을 베트남어앱 허락 받아 빌림**(쿠키 복사 없음). 순서 fa → kk(kk-0b 요청으로 크롬 켜 둔 채 넘김).
  - 모델: Gemini 화면이 바뀌어 3.1 Pro 없음 → Gemini 4 **Neon(심층 분석)** 으로 45편. `tools/gemini_send.py` 모델 확인을 새 선택기 aria-label(「현재 X 모드」)로 고침, Hydrogen·자동·Lite 면 BADMODEL. 결과 `data/review/dialogues/<id>_gemini.md`.
  - 분류(`data/review/triage/<id>.json`): rd 85(Claude 반영), Grok 다시 쓰기 149줄/44편, 버림 138(우리 독음 표기표와만 다른 지적·의도된 반전·쿠네 식 걱정·‑ید→‑ین). 공통 독음 고침: اومد 우마, چشم 체슴, خب 코브, ولی 발리, هزار 헤저르 등.
  - r1_survival_s1 2·4줄 «بله.» 는 장면 장치라 그대로 — 턴에 `short_ok: true`, 검사기가 이를 따름.
  - Grok 다시 쓰기: uk 「fa 시작」, PC 9244(9231 쿠키 동기화, 「빠른」), `tools/grok_fix_batch.py`(답 `data/grok/fix/<id>.md`, 기록 `log.tsv`, `--apply` 로 tl_col·tl·ko·note 만 바꾸고 `grok_fix: true`).
- **11-22 저녁 끝낸 것**: Grok 줄 다시 쓰기 44편 149줄(형식 재요청 0, 방 3개, PC 9244 끔) → 독음 → 검사기 0오류 → `turn_lock --write`(45편 452턴) → `script_publish --init` = **R2 `script/fa/index.json` rev 1(45파일)** → 커밋 `2ccbd9f`. CI 는 새 stable Flutter 가 Gradle 9.3.1 을 요구해 실패 → 다른 언어앱처럼 `flutter-version: 3.47.7` 고정(`4d0d75f`) → APK 빌드 18, Zealot https://apps.talkverse.uk/O2wYW/546 (SHA-1 9cc4bc93…). iOS `tools/ios_release.sh` 업로드(빌드 2611221754). PC 일시 멈춤(uk 11-22 19시)이라 APK 의 PC OneDrive 백업은 건너뜀 — 풀리면 할 것.
  - 심사 정리(uk): 에피소드 화면에서 편 없는 급(L2·L3)의 「준비 중」을 숨김. 로그인 버튼 「준비 중」은 uk 지시로 그대로.
  - 음성: 3090 MOSS 450조각 — uk 자리 11-29 프랑스어 「GPU 끝」 뒤(안 되면 11-30 00:01). PC 멈춤 풀린 뒤.
  - 남은 일: 통합 앱 연결 보고(uk) · 음성 · 언어감각 과정 · 단어 퀴즈 복습 · 〇〇 이름 · 장면 컷 10장 · 단어 그림(art 매니페스트). 옛 L1 5편(Claude 글)은 사용자 결정 대기 그대로.
- 다음: uk 순서 + 크롬 뜨면 → Grok 45편(`tools/grok_text.py`, 3분 상한, 첫 방 약속 뒤 한 줄씩) → Gemini 3.1 Pro 확인 → 샘플 2편 → `GEMINI_CDP_PORT=9244 python3 tools/gemini_batch.py data/gemini/prompts/list_30.tsv -j 1 --gap 60` → 실제 오류만 반영 → `tools/turn_lock.py --write` → `rm assets/data/script_rev.json && python3 tools/script_publish.py --init`(R2 rev 1) → 회화·코드 함께 커밋(`git add` 경로 지정) → CI Android + iOS → uk 에 보고(커밋·`persian_universe`·새 에셋 `script_rev.json`·rev). 그 뒤 언어감각 과정(급마다 외울 대화 10줄+참고, `video_player`)·단어 퀴즈 복습(외래어 표기 따로 없음 → 단어 복습용)·장면 컷 10장.

## 화면(이번까지 만든 것)
- 홈 메뉴: **기초**(문자와 발음 · 키보드 연습) → 문법(문법·동사 활용) → 회화(회화·문장 말하기·문장 카드) → 단어(절벽 단어·단어·단어 카드·표현) → 에피소드 → 참고(청크 검색). 아이패드 두 화면, 만화책 리더, 성과 데스크, 앱 소개.
- **문자와 발음**(11-08, §5-3): `screens/alphabet_screen.dart` + `widgets/fa_sound_sheet.dart` + `services/persian_phonetics.dart`. 조음 위치 그림 `assets/images/ipa/places_of_articulation.png` 는 **임시·출처 표기 없음(사용자 지시) — 출시 전 Grok 그림으로 교체**. 발음 설명은 원어민 검수 전.
- **키보드 연습**(11-08, 「아랍어앱 키보드 가져오기」 = 옛 아랍어앱 `~/talkverse/_legacy/ar`): `screens/keyboard_screen.dart` + `widgets/persian_keyboard_guide.dart`.
- 글자 시트(문장 낱말 길게 누름), 낱말 탭 = 단어창, 입말 칩(데이터는 새 회화 연결 뒤), 한글독음 기본 숨김.
- 확인: `flutter analyze` 0, `flutter test` 11개, 아이폰 시뮬레이터로 홈·프로필·문자와 발음·키보드·결제 시트·통합 준비 뒤 단독 실행(키 이전·폴더·에셋) 확인.

## 회화 다음 순서(사용자 지시, uk 전달)
**2026-11-10 현재: 사용자 결정 「다」 = 페르시아어는 Grok 재작성 생략, 바로 Gemini 검수.** Grok 시험 2편(첫 방 규칙 그대로 → 거의 손대지 않음, 규칙 1 강화 뒤 새 방 → 초안에 한 문장씩 덧붙이기만 하고 초급 줄이 길어짐, 결과 `data/grok/out/*_v3.md`, 회화 JSON 엔 반영 안 함). Gemini 프롬프트 146건 생성 끝(`data/gemini/prompts/`, `list.tsv`). **막힘: PC 크롬 9244(`D:\chrome-grok-fa`)에 Google 로그인 없음(Flash-Lite 비로그인 화면) → 사용자가 RustDesk 로 로그인해야 함.** 로그인 뒤: 3.1 Pro 확인 → 샘플 2편 보여 주고 승인 → `GEMINI_CDP_PORT=9244 python3 tools/gemini_batch.py data/gemini/prompts/list.tsv -j 1 --gap 60`(gemini_send.py 기본 포트 9226 은 베트남어 크롬이니 쓰지 말 것). 11-10 00:2x uk 지시로 작업 멈추고 대기(탭 닫음, 크롬 창은 둠). 11-10 M6 디스크 꽉 참 → 허브 지시로 build/·.dart_tool/·ios/Pods 삭제(약 1.9GB, 다시 빌드하면 생김 — 빌드 전 `flutter pub get`·`pod install`) 후 세션 종료. 장면 컷 없음, 회화·단어는 D1 에 표가 없어 앱 에셋으로만 있음. 지울 후보: 없음(`~/tts_work/fa` 13MB 는 시험 음성 원본이라 둠). Grok 도구 `tools/grok_text.py` 는 사용자 지시대로 3분 넘으면 생성 중지.
원래 순서: Claude 초안(끝) → **Grok 재작성(11/9 13:30 재개 공지)** → **Gemini 검수**(fa 포함, `~/talkverse/GEMINI_REVIEW_GUIDE.md`: 3.1 Pro, `-j 1 --gap 60`, 한 번에 한 세션, BLOCKED 면 멈추고 알림, 샘플 먼저) → 실제 오류만 반영(`emotion`·`segs` 유지, `make_plan.py` 다시) → 리뷰 통과 → 앱 연결(`dialogue_service` 가 R 폴더를 읽게, pubspec 폴더 단위 추가, version.json db 번호 올림, `tools/add_lemmas_fa.py`) → 장면 컷 → 전편 음성.
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
- **Grok 은 PC 에서(2026-11-09 사용자 지시 「소수언어들에게 pc에서 그록 켜서 집필 그림 작업 하라고 해」, uk 전달)**: PC 크롬을 `--remote-debugging-port` 로 띄우고 → M4 에서 `ssh -N -L <로컬>:127.0.0.1:<PC포트> pc` 터널 → M4 `grok_cookie_sync.py 9231 <로컬>`. 포트는 `~/talkverse-uk/docs/GROK_CHROME_PORTS.md` 에 등록. **아직 못 함** — PC 에 john 데스크톱으로 크롬을 띄우는 예약 작업 등록이 세션 권한(자동 모드)에서 거부됨. 사용자가 PC 에서 크롬을 직접 띄워 주거나(`chrome.exe --remote-debugging-port=9244 --remote-debugging-address=127.0.0.1 --user-data-dir=D:\chrome-grok-fa --no-first-run https://grok.com`) 허용해 줘야 진행. 한도 공유라 회차는 작게, 샘플 1~2편 먼저.
- **일상 속 반전(2026-11-09 사용자 지시, 정정 포함)**: 반전·러브·플러팅은 그대로, 무대만 실제 일상과 그 자리 표현으로. 규칙 `tools/prompts/dialogue_fa.md`「일상 속 반전」. 146편 중 비현실 설정 40편 다시 씀(억지 우연·건물/동네 소동 제거), 계획표 scene 을 JSON 과 맞춤, 리뷰 페이지 다시 만듦(`zsh tools/review_fa.sh` — bash 로 돌리면 깨짐). Grok 은 모델이 「전문가」인지 확인(`~/talkverse-uk/tools/grok_mode.py <포트> --check`)한 뒤 쓴다.
- **Grok 프롬프트 최소화(2026-11-09 사용자 지시, uk 전달)**: 규칙은 문서(첨부 파일)에 한 번만, 방 첫 메시지에서 「이후엔 파일 이름 한 줄만 보낸다」고 약속하고 그 뒤 채팅은 한 줄만. 그림이 처음과 달라지면 최초 통과 그림을 기준으로(이미 만든 것은 그대로). 회화 감정 열(`emotion`·`segs`, 턴마다)은 재작성 뒤에도 유지 — 지금 146편 1,467턴 모두 들어 있음.
