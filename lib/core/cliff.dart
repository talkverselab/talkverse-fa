/// 페르시아어 절벽 — 2026-11-03 산출, 누적 55/60/70% 에 처음 닿는 순위(R1~R3). 경계는 이 파일 한 곳에만 둔다.
/// 소수언어 정책(2026-11-03): 앱에 보이는 구간은 R1~R3 + 그 밖 EXT. 단어 표는 1,500위까지(사용자 결정 2026-11-03).
const List<int> kCliffs = [50, 72, 185];
const List<int> kCliffPct = [55, 60, 70];
const int kWordCap = 1500;
const double kWordCapPct = 87.3;
const int kAt80 = 561; // 누적 80% 에 닿는 순위
const int kUnit = 20; // 한 단원 단어 수
