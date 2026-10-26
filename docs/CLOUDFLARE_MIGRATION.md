# Supabase → Cloudflare 이관 — 페르시아어앱

**Supabase 사용 없음 — 확인 2026-10-26.**

- 코드·스크립트·웹 파일에 Supabase 주소·키·클라이언트가 없다(`pubspec.yaml` 에도 `supabase_flutter` 없음).
  표·저장소 버킷·RPC·로그인(Auth) 모두 쓰지 않는다.
- 앱이 바깥으로 부르는 곳은 「앱 업데이트」의 GitHub 릴리스(`latest.json`·APK)뿐이다(`lib/services/update_service.dart`).
- 콘텐츠(회화·문법·단어)는 앱에 번들된 `assets/data/**` 와 기기 안 SQLite(drift·sqflite), 학습 기록은 기기에만 저장한다.

## Supabase 에 남아 있는 페르시아어 행 (앱 미사용)
- 공용 표 `public.items` 에 `language_code='fa'` 14행(sentence 12 · word 2, 약 2.8KB, 마지막 수정 2026-04-21).
  이 앱은 읽지 않는다. 옮길지·지울지는 공용 `items` 전체를 정리할 때 함께 결정(삭제는 사용자가 실행).

## 앞으로
- 콘텐츠를 서버로 옮기거나 로그인을 붙일 때는 공용 규칙을 따른다: 학습 데이터 → `talkverse-db`(`lang='fa'`),
  계정 → `talkverse-accounts` + `talkverse-auth`, 파일(음성 등) → R2.
- 지금 할 일·대기 항목 없음.
