# 심사 메모(App Review Notes) 초안 · 개인정보처리방침 추가 문안 — 2026-11-02

> 한자 앱 `docs/store/review_notes.md` 를 페르시아어유니버스에 맞춘 것. Talkverse ID 로그인(선택) + 인앱 구입(평생 이용권 1개).
> ⚠ 지금은 잠긴 기능이 없다(무엇을 유료로 할지 사용자 결정 전). 잠금이 정해지면 아래 [인앱 구입] 의 "어디서 사는지"를 고칠 것 —
> 아무것도 열어 주지 않는 상품은 심사에서 거절될 수 있다(지침 3.1.1).

## App Store Connect "심사 정보 → 메모"

```
[로그인] 로그인은 선택입니다. 모든 학습 기능은 로그인 없이 사용할 수 있고, 로그인은 구매 복원과 기기 간 이용권 공유에만 쓰입니다.
- 로그인 화면: 홈 → 프로필·설정 → 계정 → 로그인. Apple로 로그인 + 이메일 로그인(심사·테스트용).
- 데모 계정(이메일 로그인): review@talkverse.uk / 비밀번호: <Doppler keys/prd TALKVERSE_REVIEW_ACCOUNT 에서 복사해 여기 입력>
- 계정 삭제: 프로필·설정 → 계정 → 계정 삭제(확인 창) → 서버에서 개인정보가 삭제되고 모든 기기에서 로그아웃됩니다.
[인앱 구입] 비소모성 "평생 이용권"(com.talkverse.persianUniverse.lifetime) 1개. 프로필·설정 → 계정 → 평생 이용권 → [평생 이용권 구매 ₩…], [이전 구매 복원]. Sandbox 계정으로 시험할 수 있습니다. 로그인 없이도 구매·복원이 됩니다.
[마이크] 말하기 연습에서 사용자가 버튼을 누를 때만 마이크·음성 인식을 씁니다. 녹음은 저장하거나 전송하지 않습니다.

[Sign-in] Optional. Every learning feature works without an account; sign-in is only for restoring purchases across devices.
- Where: Home → Profile & Settings → Account → Sign in (Sign in with Apple, or email sign-in for review/testing).
- Demo account (email sign-in): review@talkverse.uk / password: <paste from Doppler>
- Account deletion: Profile & Settings → Account → Delete account (confirmation) → personal data is deleted server-side and all sessions are revoked.
[IAP] One non-consumable "Lifetime Pass" (com.talkverse.persianUniverse.lifetime). Profile & Settings → Account → Lifetime Pass → [Buy], [Restore purchases]. Works with a Sandbox account; sign-in is not required to buy or restore.
[Microphone] Used only in Speaking Practice while the user holds the record button; audio is not stored or sent.
```

## 개인정보처리방침에 추가할 문안 (talkverse.uk 세션 반영 요청 — 페르시아어 앱 방침 주소 미정)
```
계정(선택)
페르시아어유니버스는 로그인 없이 쓸 수 있습니다. Talkverse 계정으로 로그인하면 다음을 처리합니다.
- 수집 항목: 이메일 주소, 이름(로그인 제공자가 전달하는 범위), 계정 ID, 로그인 시각·기기 식별 토큰.
- 목적: 로그인 유지, 구매(평생 이용권) 복원과 기기 간 공유, 고객 문의 응대.
- 보관: 계정 삭제 시 즉시 삭제(구매·주문 기록은 관계 법령에 따라 회계 목적으로 사용자 ID 만 남깁니다).
- 삭제 방법: 앱 → 프로필·설정 → 계정 → 계정 삭제, 또는 https://talkverse.uk/account/delete .
- 처리 위탁·국외 이전: 계정 서버는 Cloudflare(미국 등 글로벌 리전)에서 운영됩니다.

결제
평생 이용권 결제는 Apple App Store 또는 Google Play 가 처리하며, 앱은 카드 정보를 받지 않습니다. 앱은 구매 영수증(거래 번호·상품 ID)만 확인해 이용권을 적용합니다.
```
