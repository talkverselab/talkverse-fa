# 심사 메모(App Review Notes) · 개인정보처리방침 추가 문안 — 2026-11-09 다시 씀

> Talkverse ID 로그인(선택) + 인앱 구입 6개(`docs/store/STORE_PRODUCTS.md`, 가격 = `~/talkverse/PRICING.md`). 4.3 차별화 근거·스토어 설명 = `docs/store/listing.md`.
> ⛔ 아직 출시하지 않는다 — 남은 것은 `listing.md` 맨 위. 잠긴 기능이 없으므로, 잠금 없이 내면 [In-app purchases] 문단을 빼고 IAP 를 등록하지 않는다(아무것도 열지 않는 상품은 지침 3.1.1 거절 위험).

## App Store Connect "심사 정보 → 메모"

```
[Language-specific app — Guideline 4.3]
This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the Persian app has its own script & pronunciation module (32 letters and 6 vowels in a right-to-left chart with IPA, articulation and the four positional letter forms, same-sound letter groups, a glyph sheet that decomposes any word in a dialogue, typing practice with the Persian keyboard), its own grammar tools (every line shown as written Persian and spoken Tehrani Persian side by side), [N] original conversation episodes with recorded audio written for this language, and a vocabulary list measured from a Persian conversation corpus (50 words = 55%, 561 words = 80%, 1,500 words = 87.3% of dialogue). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.

[Sign-in] Optional. Every learning feature works without an account; sign-in is only for sharing purchases across devices.
- Where: Profile tab → Account → Sign in (Sign in with Apple, or email sign-in for review/testing).
- Demo account (email sign-in): review@talkverse.uk / password: <paste from Doppler keys/prd TALKVERSE_REVIEW_ACCOUNT>
- Account deletion: Profile → Account → Delete account (confirmation) → personal data is deleted on the server and all sessions are revoked.

[In-app purchases] Auto-renewable subscriptions lang_fa_1m / lang_fa_3m / lang_fa_1y and all_1y (all Talkverse language apps), non-consumables lang_fa_life and all_life ("for as long as the service runs"). Profile → Account → Pass → choose a plan (none pre-selected) → Buy; the sheet shows price, period, auto-renewal and how to cancel next to the button, plus Restore purchases and Terms / Privacy links. Works with a Sandbox account; sign-in is not required to buy or restore.

[Microphone] Used only in Speaking Practice while the user holds the record button; audio is not stored or sent.
[Network] Scene pictures, word pictures and dialogue audio are downloaded and cached; offline the app keeps working with what is cached.
```

한국어 요약: 언어별로 따로 만든 앱(4.3) · 로그인 선택(프로필 → 계정) · 데모 계정 review@talkverse.uk(비밀번호는 Doppler 에서 메모 칸에만) · 계정 삭제 경로 · 인앱 구입 6개와 결제 시트 표기 · 마이크 · 그림·음성 내려받기.

## IAP 상품 심사 스크린샷
- 결제 시트(상품 고르기 전·고른 뒤 각 1장).

## 개인정보처리방침에 추가할 문안 (talkverse.uk 세션 반영 요청 — 페르시아어 앱 방침 주소 미정)
```
계정(선택)
페르시아어유니버스는 로그인 없이 쓸 수 있습니다. Talkverse 계정으로 로그인하면 다음을 처리합니다.
- 수집 항목: 이메일 주소, 이름(로그인 제공자가 전달하는 범위), 계정 ID, 로그인 시각·기기 식별 토큰.
- 목적: 로그인 유지, 구매(이용권) 복원과 기기 간 공유, 고객 문의 응대.
- 보관: 계정 삭제 시 즉시 삭제(구매·주문 기록은 관계 법령에 따라 회계 목적으로 사용자 ID 만 남깁니다).
- 삭제 방법: 앱 → 프로필·설정 → 계정 → 계정 삭제, 또는 https://talkverse.uk/account/delete .
- 처리 위탁·국외 이전: 계정 서버는 Cloudflare(미국 등 글로벌 리전)에서 운영됩니다.

결제
이용권(구독·평생) 결제는 Apple App Store 또는 Google Play 가 처리하며, 앱은 카드 정보를 받지 않습니다. 앱은 구매 영수증(거래 번호·상품 ID)만 확인해 이용권을 적용합니다.
```
