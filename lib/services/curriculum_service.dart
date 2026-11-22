import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import 'dialogue_service.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 ~/talkverse/CURRICULUM_SPEC.md, 2026-11-22).
/// 회화 레벨에서 다이얼로그를 골라 코스를 만들고 → 편마다 연습·확인 문제 → 틀린 줄 간격 반복(1·3·7일)
/// → 코스 시험 80% 이상이면 통과. 하루 목표(새 편 1·2·3 + 복습). 기기 저장 키 `curriculum_v1` — Prefs 가 언어 접두를 붙여 실제로는 `fa_curriculum_v1`(11-22 기준 문서 정정).

const kCurriculumKey = 'curriculum_v1';
const kReviewSteps = [1, 3, 7]; // 일
const kPassPct = 80;

/// 정답 수 / 문제 수, 소수점 버림.
int scorePct(int correct, int total) => total == 0 ? 0 : (correct * 100) ~/ total;
bool isPass(int pct) => pct >= kPassPct;

String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class ReviewItem {
  final String lineId; // '<편 id>:<턴 번호>'
  final String due; // yyyy-mm-dd
  final int step; // kReviewSteps 의 칸

  const ReviewItem(this.lineId, this.due, this.step);

  /// 맞히면 다음 간격(7일 뒤로는 7일 유지), 틀리면 1일로.
  ReviewItem answered(bool correct, DateTime today) {
    final s = correct ? min(step + 1, kReviewSteps.length - 1) : 0;
    final gap = correct ? kReviewSteps[s] : kReviewSteps[0];
    return ReviewItem(lineId, dayKey(_day(today).add(Duration(days: gap))), s);
  }

  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map<String, dynamic> j) =>
      ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

class Course {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  final String? passedAt;

  const Course({required this.id, required this.dialogueIds, this.practiced = const [], this.examScores = const [], this.passedAt});

  bool get allPracticed => dialogueIds.every(practiced.contains);

  Course copyWith({List<String>? practiced, List<int>? examScores, String? passedAt}) => Course(
        id: id,
        dialogueIds: dialogueIds,
        practiced: practiced ?? this.practiced,
        examScores: examScores ?? this.examScores,
        passedAt: passedAt ?? this.passedAt,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: '${j['id']}',
        dialogueIds: [for (final x in (j['dialogueIds'] as List? ?? const [])) '$x'],
        practiced: [for (final x in (j['practiced'] as List? ?? const [])) '$x'],
        examScores: [for (final x in (j['examScores'] as List? ?? const [])) (x as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

class CurriculumState {
  String? level;
  int dailyGoal; // 새 편 1·2·3
  Course? course;
  List<String> passedDialogues;
  List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  // 하루 진행(저장 형식 밖의 덧붙임 — 날짜가 바뀌면 0)
  String? todayDay;
  int todayNew;
  int todayReview;

  CurriculumState({
    this.level,
    this.dailyGoal = 2,
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay,
    this.todayNew = 0,
    this.todayReview = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'new': todayNew, 'review': todayReview},
      };

  factory CurriculumState.fromJson(Map<String, dynamic> j) {
    final st = (j['streak'] as Map?) ?? const {};
    final td = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: (j['dailyGoal'] as num?)?.toInt() ?? 2,
      course: j['course'] is Map ? Course.fromJson(Map<String, dynamic>.from(j['course'] as Map)) : null,
      passedDialogues: [for (final x in (j['passedDialogues'] as List? ?? const [])) '$x'],
      review: [for (final x in (j['review'] as List? ?? const [])) ReviewItem.fromJson(Map<String, dynamic>.from(x as Map))],
      streakCount: (st['count'] as num?)?.toInt() ?? 0,
      streakLastDay: st['lastDay'] as String?,
      todayDay: td['day'] as String?,
      todayNew: (td['new'] as num?)?.toInt() ?? 0,
      todayReview: (td['review'] as num?)?.toInt() ?? 0,
    );
  }

  /// 날짜가 바뀌었으면 오늘 진행을 0 으로.
  void rollDay(DateTime now) {
    final k = dayKey(now);
    if (todayDay != k) {
      todayDay = k;
      todayNew = 0;
      todayReview = 0;
    }
  }

  List<ReviewItem> dueReviews(DateTime now) {
    final k = dayKey(now);
    return [for (final r in review) if (r.due.compareTo(k) <= 0) r];
  }

  /// 같은 줄은 하나만 — 처음 들어온 줄은 1일 뒤, 이미 있던 줄은 맞힘/틀림에 따라 간격.
  void schedule(String lineId, bool correct, DateTime now) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    if (i < 0) {
      review.add(ReviewItem(lineId, dayKey(_day(now).add(Duration(days: kReviewSteps[0]))), 0));
    } else {
      review[i] = review[i].answered(correct, now);
    }
  }

  /// 오늘 분량을 다 하면 연속 일수 +1(어제 이어서면 이어 세고, 끊겼으면 1).
  bool get todayDone => todayNew >= dailyGoal && todayReviewLeft == 0;
  int todayReviewLeft = 0;

  void markStreakIfDone(DateTime now) {
    final k = dayKey(now);
    if (!todayDone || streakLastDay == k) return;
    final y = dayKey(_day(now).subtract(const Duration(days: 1)));
    streakCount = streakLastDay == y ? streakCount + 1 : 1;
    streakLastDay = k;
  }
}

/// 문제 한 개: 페르시아어 줄을 보고 뜻(한국어) 4지선다.
class CurQuestion {
  final String lineId;
  final String dialogueId;
  final String tl;
  final String rd;
  final String answer;
  final List<String> options;
  final String gender;

  const CurQuestion({required this.lineId, required this.dialogueId, required this.tl, required this.rd, required this.answer, required this.options, required this.gender});
}

class CurriculumService {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();

  CurriculumState state = CurriculumState();
  final ValueNotifier<int> changed = ValueNotifier(0);
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await Prefs.getInstance();
      final raw = p.getString(kCurriculumKey);
      if (raw != null) state = CurriculumState.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {}
    _loaded = true;
  }

  Future<void> save() async {
    try {
      final p = await Prefs.getInstance();
      await p.setString(kCurriculumKey, json.encode(state.toJson()));
    } catch (_) {}
    changed.value++;
  }

  /// 회화 레벨(R0~R5) — 지금 앱에 있는 것만.
  static List<String> levels(List<Dialogue> all) =>
      (all.map((d) => d.region).where((r) => RegExp(r'^R[0-5]$').hasMatch(r)).toSet().toList()..sort());

  static List<Dialogue> inLevel(List<Dialogue> all, String level) => [for (final d in all) if (d.region == level) d];

  static String lineId(Dialogue d, DialogueTurn t) => '${d.id}:${t.num}';

  static String clean(String s) => s.replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\{[a-z_]+\}'), '').trim();

  /// 추천으로 채우기 — 아직 통과 안 한 편에서 주제가 겹치지 않게.
  static List<String> recommend(List<Dialogue> level, Set<String> passed, int n, {Set<String> already = const {}}) {
    final pick = <String>[...already];
    final islands = <String>{for (final d in level) if (already.contains(d.id)) d.island};
    final fresh = [for (final d in level) if (!passed.contains(d.id) && !already.contains(d.id)) d];
    for (final d in fresh) {
      if (pick.length >= n) break;
      if (islands.add(d.island)) pick.add(d.id);
    }
    for (final d in fresh) {
      if (pick.length >= n) break;
      if (!pick.contains(d.id)) pick.add(d.id);
    }
    for (final d in level) {
      if (pick.length >= n) break;
      if (!pick.contains(d.id)) pick.add(d.id);
    }
    return pick;
  }

  /// 편의 줄로 뜻 고르기 문제(최대 [max]개). 오답 보기는 같은 레벨 다른 줄의 뜻.
  static List<CurQuestion> questionsFor(Dialogue d, List<Dialogue> pool, {int max = 10, Random? rnd, Set<String>? only}) {
    final r = rnd ?? Random();
    final others = <String>{
      for (final o in pool)
        for (final t in o.turns)
          if (t.ko.trim().isNotEmpty) t.ko.trim()
    };
    final lines = [
      for (final t in d.turns)
        if (t.tl.trim().isNotEmpty && t.ko.trim().isNotEmpty && (only == null || only.contains(lineId(d, t)))) t
    ];
    final out = <CurQuestion>[];
    for (final t in lines.take(max)) {
      final ans = t.ko.trim();
      final wrong = (others.where((x) => x != ans).toList()..shuffle(r)).take(3);
      final opts = [ans, ...wrong]..shuffle(r);
      out.add(CurQuestion(lineId: lineId(d, t), dialogueId: d.id, tl: clean(t.tl), rd: t.rd, answer: ans, options: opts, gender: d.voiceGender(t.speaker)));
    }
    return out;
  }

  /// 코스 시험: 편마다 최소 3문제, 모두 합쳐 최대 30문제.
  static List<CurQuestion> examFor(List<Dialogue> course, List<Dialogue> pool, {Random? rnd}) {
    final r = rnd ?? Random();
    if (course.isEmpty) return const [];
    final per = max(3, min(10, 30 ~/ course.length));
    final out = <CurQuestion>[];
    for (final d in course) {
      final qs = questionsFor(d, pool, max: 99, rnd: r)..shuffle(r);
      out.addAll(qs.take(per));
    }
    out.shuffle(r);
    return out.take(30).toList();
  }

  /// 복습 문제 — 오늘 차례인 줄.
  static List<CurQuestion> reviewFor(List<ReviewItem> due, List<Dialogue> all, {Random? rnd}) {
    final r = rnd ?? Random();
    final byId = {for (final d in all) d.id: d};
    final want = <String, Set<String>>{};
    for (final it in due) {
      final i = it.lineId.lastIndexOf(':');
      if (i < 0) continue;
      want.putIfAbsent(it.lineId.substring(0, i), () => {}).add(it.lineId);
    }
    final out = <CurQuestion>[];
    want.forEach((id, lines) {
      final d = byId[id];
      if (d != null) out.addAll(questionsFor(d, all, max: 99, rnd: r, only: lines));
    });
    out.shuffle(r);
    return out;
  }

  // ── 상태 바꾸기 ──

  Future<void> setLevel(String level) async {
    state.level = level;
    await save();
  }

  Future<void> setDailyGoal(int n) async {
    state.dailyGoal = n.clamp(1, 3);
    await save();
  }

  Future<void> startCourse(List<String> ids) async {
    state.course = Course(id: 'c${DateTime.now().millisecondsSinceEpoch}', dialogueIds: ids);
    await save();
  }

  Future<void> dropCourse() async {
    state.course = null;
    await save();
  }

  /// 편 연습(확인 문제)을 마침 — 연습 표시, 줄을 복습 대기열에(틀린 줄은 1일, 맞힌 줄도 1일 뒤 첫 복습).
  Future<void> finishPractice(String dialogueId, Map<String, bool> results, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    state.rollDay(t);
    final c = state.course;
    if (c != null && !c.practiced.contains(dialogueId)) {
      state.course = c.copyWith(practiced: [...c.practiced, dialogueId]);
      state.todayNew++;
    }
    results.forEach((line, ok) => state.schedule(line, ok, t));
    today(now: t);
    await save();
  }

  Future<void> finishReview(Map<String, bool> results, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    state.rollDay(t);
    for (final e in results.entries) {
      final i = state.review.indexWhere((r) => r.lineId == e.key);
      if (i >= 0) state.review[i] = state.review[i].answered(e.value, t);
      state.todayReview++;
    }
    today(now: t);
    await save();
  }

  /// 코스 시험 결과. 통과면 코스 완료·편 통과 기록, 아니면 틀린 편의 연습 표시를 지워 다시 연습하게.
  /// 돌려주는 값: (점수, 통과, 다음 레벨로 넘어감)
  Future<(int, bool, String?)> finishExam(Map<String, bool> results, List<Dialogue> all, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    final c = state.course;
    final pct = scorePct(results.values.where((x) => x).length, results.length);
    if (c == null) return (pct, false, null);
    final pass = isPass(pct);
    String? nextLevel;
    if (pass) {
      state.passedDialogues = {...state.passedDialogues, ...c.dialogueIds}.toList();
      state.course = null;
      final lv = state.level;
      if (lv != null) {
        final inLv = inLevel(all, lv);
        if (inLv.isNotEmpty && inLv.every((d) => state.passedDialogues.contains(d.id))) {
          final ls = levels(all);
          final i = ls.indexOf(lv);
          if (i >= 0 && i + 1 < ls.length) {
            nextLevel = ls[i + 1];
            state.level = nextLevel;
          }
        }
      }
    } else {
      final failed = <String>{
        for (final e in results.entries)
          if (!e.value) e.key.substring(0, e.key.lastIndexOf(':'))
      };
      state.course = c.copyWith(practiced: [for (final id in c.practiced) if (!failed.contains(id)) id], examScores: [...c.examScores, pct]);
    }
    for (final e in results.entries) {
      if (!e.value) state.schedule(e.key, false, t);
    }
    await save();
    return (pct, pass, nextLevel);
  }

  /// 오늘 분량 요약 (복습 남음, 새 편 남음, 진행 0~1)
  (int, int, double) today({DateTime? now}) {
    final t = now ?? DateTime.now();
    state.rollDay(t);
    final rev = state.dueReviews(t).length;
    final newLeft = max(0, state.dailyGoal - state.todayNew);
    final total = state.todayReview + rev + state.dailyGoal;
    final done = state.todayReview + min(state.todayNew, state.dailyGoal);
    state.todayReviewLeft = rev;
    state.markStreakIfDone(t);
    return (rev, newLeft, total == 0 ? 0 : done / total);
  }
}
