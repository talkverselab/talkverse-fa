import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';

/// 토크버스 커리큘럼 홈 — 레벨 고르기 → 오늘 분량 → 지금 코스(편 연습·코스 시험) → 복습.
/// 기준 ~/talkverse/CURRICULUM_SPEC.md (2026-11-22). 기존 화면은 바꾸지 않고 메뉴만 더함.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final cur = CurriculumService.instance;
  List<Dialogue> all = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([DialogueService.instance.ensureLoaded(), cur.load()]);
    all = DialogueService.instance.all;
    if (mounted) setState(() => loading = false);
  }

  Dialogue? _byId(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> _push(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final levels = CurriculumService.levels(all);
    final st = cur.state;
    final level = st.level;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text(tr('토크버스 커리큘럼')),
        actions: [
          if (level != null)
            TextButton(onPressed: () => setState(() => st.level = null), child: Text(tr('레벨 바꾸기'))),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : levels.isEmpty
              ? Center(child: Text(tr('회화를 불러오는 중입니다.')))
              : level == null || !levels.contains(level)
                  ? _levelPicker(levels)
                  : _home(level),
    );
  }

  Widget _levelPicker(List<String> levels) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)),
      children: [
        Text(tr('레벨을 고르세요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.tinta)),
        const SizedBox(height: 6),
        Text(tr('처음이면 가장 낮은 레벨부터 권합니다.'), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 14),
        for (final (i, lv) in levels.indexed)
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.beni, foregroundColor: Colors.white, child: Text(lv)),
              title: Text('${DialogueService.levelKo[lv] ?? lv} · ${trf('{0}편', [CurriculumService.inLevel(all, lv).length])}'),
              subtitle: i == 0 ? Text(tr('추천')) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await cur.setLevel(lv);
                setState(() {});
              },
            ),
          ),
      ],
    );
  }

  Widget _home(String level) {
    final st = cur.state;
    final (rev, newLeft, ratio) = cur.today();
    final inLv = CurriculumService.inLevel(all, level);
    final passed = inLv.where((d) => st.passedDialogues.contains(d.id)).length;
    final course = st.course;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        // 오늘 분량
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(tr('오늘 분량'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                if (st.streakCount > 0) Text(trf('연속 {0}일', [st.streakCount]), style: const TextStyle(color: AppColors.beni, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              Text(st.todayDone ? tr('오늘 분량 끝') : trf('오늘: 복습 {0} · 새 편 {1}', [rev, newLeft]),
                  style: const TextStyle(fontSize: 14, color: AppColors.tinta)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: AppColors.line, color: AppColors.beni),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final (n, label) in [(1, tr('가볍게')), (2, tr('보통')), (3, tr('집중'))])
                  ChoiceChip(
                    label: Text('$label · ${trf('새 편 {0}', [n])}'),
                    selected: st.dailyGoal == n,
                    onSelected: (_) async {
                      await cur.setDailyGoal(n);
                      setState(() {});
                    },
                  ),
              ]),
              if (rev > 0) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  icon: const Icon(Icons.replay),
                  label: Text(trf('복습 {0}줄 하기', [rev])),
                  onPressed: () {
                    final qs = CurriculumService.reviewFor(st.dueReviews(DateTime.now()), all);
                    _push(CurQuizScreen(
                      title: tr('복습'),
                      questions: qs,
                      onDone: (res) => cur.finishReview(res),
                    ));
                  },
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('${DialogueService.levelKo[level] ?? level} ($level) · ${trf('통과 {0}/{1}편', [passed, inLv.length])}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.tintaLight)),
        ),
        if (course == null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.playlist_add, color: AppColors.beni),
              title: Text(tr('새 코스 만들기')),
              subtitle: Text(tr('이 레벨에서 다이얼로그를 3·5·10편 고릅니다')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _push(CoursePickScreen(level: level, all: all)),
            ),
          )
        else ...[
          for (final id in course.dialogueIds)
            if (_byId(id) case final d?)
              Card(
                child: ListTile(
                  leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(d.title),
                  subtitle: Text(course.practiced.contains(id) ? tr('연습 끝') : tr('연습 전'),
                      style: TextStyle(color: course.practiced.contains(id) ? AppColors.oliva : AppColors.muted)),
                  trailing: Icon(course.practiced.contains(id) ? Icons.check_circle : Icons.chevron_right,
                      color: course.practiced.contains(id) ? AppColors.oliva : null),
                  onTap: () => _push(CurPracticeScreen(dialogue: d, pool: CurriculumService.inLevel(all, level))),
                ),
              ),
          const SizedBox(height: 8),
          if (course.examScores.isNotEmpty)
            Text(trf('지난 시험 {0}% — 80% 이상이면 통과', [course.examScores.last]),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 6),
          FilledButton.icon(
            icon: const Icon(Icons.school),
            label: Text(course.allPracticed ? tr('코스 시험 보기') : tr('모든 편을 연습하면 코스 시험이 열립니다')),
            onPressed: !course.allPracticed
                ? null
                : () {
                    final ds = [for (final id in course.dialogueIds) ?_byId(id)];
                    final qs = CurriculumService.examFor(ds, CurriculumService.inLevel(all, level));
                    _push(CurQuizScreen(
                      title: tr('코스 시험'),
                      questions: qs,
                      exam: true,
                      onDone: (res) async {
                        final (_, _, next) = await cur.finishExam(res, all);
                        return next;
                      },
                    ));
                  },
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _push(CoursePickScreen(level: level, all: all)),
            child: Text(tr('다른 코스로 바꾸기')),
          ),
        ],
      ],
    );
  }
}

/// 코스 만들기 — 개수(3·5·10) 고르고 편을 고름. 지금 코스가 있으면 화면 안에서 버릴지 확인.
class CoursePickScreen extends StatefulWidget {
  final String level;
  final List<Dialogue> all;
  const CoursePickScreen({super.key, required this.level, required this.all});

  @override
  State<CoursePickScreen> createState() => _CoursePickScreenState();
}

class _CoursePickScreenState extends State<CoursePickScreen> {
  final cur = CurriculumService.instance;
  int size = 5;
  final picked = <String>{};
  bool confirmDrop = false;

  @override
  Widget build(BuildContext context) {
    final inLv = CurriculumService.inLevel(widget.all, widget.level);
    final passed = cur.state.passedDialogues.toSet();
    final hasCourse = cur.state.course != null;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('새 코스 만들기'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Text(tr('고를 개수'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            for (final n in [3, 5, 10])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(label: Text('$n'), selected: size == n, onSelected: (_) => setState(() => size = n)),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                final keep = picked.take(size).toSet();
                picked
                  ..clear()
                  ..addAll(CurriculumService.recommend(inLv, passed, size, already: keep));
              }),
              child: Text(tr('추천으로 채우기')),
            ),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final d in inLv)
                CheckboxListTile(
                  value: picked.contains(d.id),
                  onChanged: (v) => setState(() {
                    if (v == true && picked.length < size) {
                      picked.add(d.id);
                    } else {
                      picked.remove(d.id);
                    }
                  }),
                  secondary: Text(d.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(d.title),
                  subtitle: Text('${DialogueService.islandKo[d.island] ?? d.island}${passed.contains(d.id) ? ' · ${tr('통과함')}' : ''}'),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
          child: confirmDrop
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(tr('지금 코스를 버리고 새 코스를 시작할까요? 연습 기록은 복습에 남습니다.'), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => confirmDrop = false), child: Text(tr('취소')))),
                    const SizedBox(width: 10),
                    Expanded(child: FilledButton(onPressed: _start, child: Text(tr('새 코스 시작')))),
                  ]),
                ])
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: picked.isEmpty ? null : () => hasCourse ? setState(() => confirmDrop = true) : _start(),
                    child: Text(trf('{0}편으로 코스 시작', [picked.length])),
                  ),
                ),
        ),
      ]),
    );
  }

  Future<void> _start() async {
    final order = [for (final d in CurriculumService.inLevel(widget.all, widget.level)) if (picked.contains(d.id)) d.id];
    await cur.startCourse(order);
    if (mounted) Navigator.pop(context);
  }
}

/// 편 연습 — 듣기·읽기(기기 TTS), 줄 따라 말하기(반복 듣기), 확인 문제.
class CurPracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  final List<Dialogue> pool;
  const CurPracticeScreen({super.key, required this.dialogue, required this.pool});

  @override
  State<CurPracticeScreen> createState() => _CurPracticeScreenState();
}

class _CurPracticeScreenState extends State<CurPracticeScreen> {
  final showKo = <int>{};
  int? playing;
  bool stop = false;

  Future<void> _say(int i) async {
    final d = widget.dialogue;
    final t = d.turns[i];
    setState(() => playing = i);
    await TtsService.instance.speakAs(CurriculumService.clean(t.tl), gender: d.voiceGender(t.speaker));
  }

  Future<void> _playAll() async {
    stop = false;
    for (var i = 0; i < widget.dialogue.turns.length && !stop && mounted; i++) {
      await _say(i);
      final len = CurriculumService.clean(widget.dialogue.turns[i].tl).length;
      await Future.delayed(Duration(milliseconds: 900 + len * 90));
    }
    if (mounted) setState(() => playing = null);
  }

  @override
  void dispose() {
    stop = true;
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dialogue;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(d.title)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            Expanded(child: Text(d.scene, style: const TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis)),
            TextButton.icon(onPressed: _playAll, icon: const Icon(Icons.play_circle), label: Text(tr('전체 듣기'))),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            itemCount: d.turns.length,
            itemBuilder: (_, i) {
              final t = d.turns[i];
              return Card(
                color: playing == i ? AppColors.washi : null,
                child: ListTile(
                  leading: CircleAvatar(radius: 14, child: Text(t.speaker, style: const TextStyle(fontSize: 12))),
                  title: Text(CurriculumService.clean(t.tl), textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 18)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (t.rd.isNotEmpty) Text(t.rd, style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
                    if (showKo.contains(i)) Text(t.ko, style: const TextStyle(fontSize: 13, color: AppColors.tinta)),
                  ]),
                  trailing: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => _say(i)),
                  onTap: () => setState(() => showKo.contains(i) ? showKo.remove(i) : showKo.add(i)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset(context)),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.quiz),
              label: Text(tr('확인 문제 풀기')),
              onPressed: () async {
                stop = true;
                final qs = CurriculumService.questionsFor(d, widget.pool);
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CurQuizScreen(
                      title: tr('확인 문제'),
                      questions: qs,
                      onDone: (res) => CurriculumService.instance.finishPractice(d.id, res),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

/// 뜻 고르기 4지선다 — 연습·복습·코스 시험 공용. onDone 이 다음 레벨 이름을 돌려주면 결과에 보임.
class CurQuizScreen extends StatefulWidget {
  final String title;
  final List<CurQuestion> questions;
  final bool exam;
  final FutureOr<Object?> Function(Map<String, bool> results) onDone;
  const CurQuizScreen({super.key, required this.title, required this.questions, required this.onDone, this.exam = false});

  @override
  State<CurQuizScreen> createState() => _CurQuizScreenState();
}

class _CurQuizScreenState extends State<CurQuizScreen> {
  int i = 0;
  String? chosen;
  final results = <String, bool>{};
  bool finished = false;
  Object? doneInfo;

  Future<void> _next() async {
    if (i + 1 < widget.questions.length) {
      setState(() {
        i++;
        chosen = null;
      });
      return;
    }
    final info = await widget.onDone(results);
    if (mounted) {
      setState(() {
        finished = true;
        doneInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(widget.title)),
      body: qs.isEmpty
          ? Center(child: Text(tr('풀 문제가 없습니다.')))
          : finished
              ? _result()
              : _question(qs[i]),
    );
  }

  Widget _question(CurQuestion q) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)),
      children: [
        Text('${i + 1} / ${widget.questions.length}', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(q.tl, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              if (q.rd.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(q.rd, style: const TextStyle(fontSize: 13, color: AppColors.tintaLight)),
              ],
              IconButton(icon: const Icon(Icons.volume_up), onPressed: () => TtsService.instance.speakAs(q.tl, gender: q.gender)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(tr('알맞은 뜻을 고르세요'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final o in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
                backgroundColor: chosen == null
                    ? null
                    : o == q.answer
                        ? AppColors.oliva.withValues(alpha: 0.18)
                        : o == chosen
                            ? AppColors.beni.withValues(alpha: 0.15)
                            : null,
              ),
              onPressed: chosen != null
                  ? null
                  : () => setState(() {
                        chosen = o;
                        results[q.lineId] = (results[q.lineId] ?? true) && o == q.answer;
                      }),
              child: Text(o, style: const TextStyle(color: AppColors.tinta)),
            ),
          ),
        if (chosen != null)
          FilledButton(onPressed: _next, child: Text(i + 1 < widget.questions.length ? tr('다음') : tr('결과 보기'))),
      ],
    );
  }

  Widget _result() {
    final ok = results.values.where((x) => x).length;
    final pct = scorePct(ok, results.length);
    final pass = isPass(pct);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$pct%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: pass ? AppColors.oliva : AppColors.beni)),
          const SizedBox(height: 6),
          Text(trf('{0}문제 중 {1}문제 맞힘', [results.length, ok])),
          const SizedBox(height: 12),
          if (widget.exam)
            Text(pass ? tr('통과! 코스를 마쳤습니다.') : tr('80% 미만 — 틀린 편을 다시 연습하고 시험을 다시 보세요.'), textAlign: TextAlign.center),
          if (doneInfo is String) ...[
            const SizedBox(height: 8),
            Text(trf('이 레벨을 모두 통과했습니다. 다음 레벨 {0} 이 열렸습니다.', [doneInfo as String]), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('돌아가기'))),
        ]),
      ),
    );
  }
}
