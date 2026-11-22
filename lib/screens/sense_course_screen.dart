import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/script_sync.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';

/// 언어감각 익히기 — 헝가리어앱(일본어앱 정규과정에서 옮김) 화면을 페르시아어로 옮김(2026-11-22, 문장은 Claude 작성 — 사용자 「언어감각 10급은 클로드로만」).
/// L1~L10, 급마다 외울 대화 1회 + 참고. 문장 칸: fa = 페르시아어 입말(`{낱말|번호}` = 익힐 자리, 이어 쓰는 글자라 낱말 통째로 표시),
/// rd = 한글 독음(독음 토글), ko = 한국어, who = 말하는 사람(듣기 목소리 성별).
/// 회차 = 문법 짧은 설명(points.tip) → 감 익히는 문장(points.sentences). 데이터 `assets/data/grammar/sense_course.json`.
/// 내용은 간단하게 시작해 차차 늘린다 — 회차를 늘리려면 JSON 에 lessons 만 더하면 된다.
const _kDoneKey = 'sense_course_done';
const _kAsset = 'assets/data/grammar/sense_course.json';

/// 말하는 사람 → 목소리 성별(인물 시트 chars_fa_v1: 사라·네가르 여, 아라시·레자 남, 나 = 학습자 설정).
String senseGender(String? who) => switch (who) {
      '사라' || '네가르' => 'female',
      '아라시' || '레자' => 'male',
      _ => LearnerPrefs.voiceGender('A'),
    };

void _say(String text, [String? who]) => TtsService.instance.speakAs(text, gender: senseGender(who));

class SenseCourse {
  static Map<String, dynamic>? _cache;
  static Future<Map<String, dynamic>> load() async =>
      // loadString 은 큰 파일을 다른 isolate 에서 풀어 위젯 테스트가 멈춘다 — 바이트로 읽어 여기서 푼다.
      _cache ??= json.decode(await ScriptSync.instance.load(_kAsset.substring('assets/data/'.length))) as Map<String, dynamic>;

  static Future<Set<String>> done() async => ((await Prefs.getInstance()).getStringList(_kDoneKey) ?? const []).toSet();

  static Future<void> markDone(String id) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kDoneKey) ?? <String>[]).toSet()..add(id);
    await p.setStringList(_kDoneKey, s.toList());
  }

  /// 내용이 있는 회차인가(문장·요점이 하나라도).
  static bool hasContent(Map<String, dynamic> ls) =>
      ((ls['sentences'] as List?)?.isNotEmpty ?? false) || ((ls['points'] as List?)?.isNotEmpty ?? false) || ((ls['lines'] as List?)?.isNotEmpty ?? false);

  /// 보일 급 — 급 목록·제목·순서는 데이터(서버 원고 `grammar/sense_course.json`)에서. 내용 없는 급은 숨김(서버에 내용이 오면 저절로 보임, 사용자 11-23).
  static List<Map<String, dynamic>> levels(Map<String, dynamic> d) => [
        for (final lv in ((d['levels'] as List?) ?? const []).cast<Map<String, dynamic>>())
          if (((lv['lessons'] as List?) ?? const []).cast<Map<String, dynamic>>().any(hasContent)) lv,
      ];

  /// 모든 회차를 순서대로 (레벨, 회차) 쌍으로 — 내용 있는 것만.
  static List<(Map<String, dynamic>, Map<String, dynamic>)> flat(Map<String, dynamic> d) => [
        for (final lv in levels(d))
          for (final ls in (lv['lessons'] as List).cast<Map<String, dynamic>>())
            if (hasContent(ls)) (lv, ls),
      ];
}

class SenseCourseScreen extends StatefulWidget {
  const SenseCourseScreen({super.key});

  @override
  State<SenseCourseScreen> createState() => _SenseCourseScreenState();
}

class _SenseCourseScreenState extends State<SenseCourseScreen> {
  Map<String, dynamic>? _data;
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await SenseCourse.load();
    final done = await SenseCourse.done();
    if (!mounted) return;
    setState(() {
      _data = d;
      _done = done;
    });
  }

  Future<void> _open(int index) async {
    await openFull(context, (_) => SenseLessonScreen(index: index));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('언어감각 익히기'))),
      body: d == null ? const Center(child: CircularProgressIndicator()) : _body(d),
    );
  }

  Widget _body(Map<String, dynamic> d) {
    final all = SenseCourse.flat(d);
    bool isRef(Map<String, dynamic> l) => l['kind'] == 'ref';
    final next = all.indexWhere((e) => !isRef(e.$2) && !_done.contains(e.$2['id']));
    final real = all.where((e) => !isRef(e.$2)).toList();
    final children = <Widget>[
      Text(tr('영상을 보고, 대화를 통째로 외워요. 규칙은 참고에만 있어요.'),
          style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
      const SizedBox(height: 4),
      Text(trf('{0}/{1}회 마침', [real.where((e) => _done.contains(e.$2['id'])).length, real.length]),
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ];
    var i = 0;
    for (final lv in SenseCourse.levels(d)) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Text('${lv['id']}  ${lv['title']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sumi)),
      ));
      var n = 1;
      for (final ls in (lv['lessons'] as List).cast<Map<String, dynamic>>().where(SenseCourse.hasContent)) {
        final idx = i;
        final isDone = _done.contains(ls['id']);
        final isNext = idx == next;
        if (ls['open'] != null) {
          // 다른 메뉴로 가는 버튼(회차 아님)
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              key: ValueKey('sense-${ls['id']}'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ai, side: const BorderSide(color: AppColors.ai), minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _open(idx),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(tr(ls['title'] as String), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ));
          i++;
          continue;
        }
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isNext ? AppColors.washiDeep : AppColors.washi,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isNext ? AppColors.ai : AppColors.line, width: isNext ? 1.4 : 1),
            ),
            child: InkWell(
              key: ValueKey('sense-${ls['id']}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _open(idx),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(children: [
                  SizedBox(
                    width: 44,
                    child: Text(isRef(ls) ? tr('참고') : trf('{0}회', [n]),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ai)),
                  ),
                  Expanded(
                    child: Text(ls['title'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                  ),
                  if (isDone)
                    const Icon(Icons.check_circle, color: AppColors.matcha, size: 20)
                  else if (isNext)
                    Text(tr('다음'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ai)),
                ]),
              ),
            ),
          ),
        ));
        i++;
        if (!isRef(ls)) n++;
      }
    }
    return ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)), children: children);
  }
}

/// 한 회차 — 문법 설명 → 문장. 아래 「마침 · 다음 회」 버튼.
class SenseLessonScreen extends StatefulWidget {
  final int index;
  const SenseLessonScreen({super.key, required this.index});

  @override
  State<SenseLessonScreen> createState() => _SenseLessonScreenState();
}

class _SenseLessonScreenState extends State<SenseLessonScreen> {
  List<(Map<String, dynamic>, Map<String, dynamic>)>? _all;

  @override
  void initState() {
    super.initState();
    SenseCourse.load().then((d) {
      if (mounted) setState(() => _all = SenseCourse.flat(d));
    });
  }

  Future<void> _finish() async {
    final all = _all!;
    if (all[widget.index].$2['kind'] == 'ref') {
      Navigator.of(context).pop(); // 참고는 기록하지 않는다
      return;
    }
    await SenseCourse.markDone(all[widget.index].$2['id'] as String);
    if (!mounted) return;
    var nextIdx = widget.index + 1;
    while (nextIdx < all.length && all[nextIdx].$2['kind'] == 'ref') {
      nextIdx++;
    }
    if (nextIdx < all.length) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SenseLessonScreen(index: nextIdx)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    if (all == null) {
      return const Scaffold(backgroundColor: AppColors.washi, body: Center(child: CircularProgressIndicator()));
    }
    final (lv, ls) = all[widget.index];
    final lessons = (lv['lessons'] as List);
    final isRef = ls['kind'] == 'ref';
    final n = lessons.take(lessons.indexOf(ls) + 1).where((l) => (l as Map)['kind'] != 'ref').length;
    final points = ((ls['points'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final memorize = ls['kind'] == 'memorize';
    final last = !all.skip(widget.index + 1).any((e) => e.$2['kind'] != 'ref');
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Text('${lv['id']} · ${isRef ? tr('참고') : trf('{0}회', [n])}  ${ls['title']}', overflow: TextOverflow.ellipsis),
        actions: const [KoReadingToggleAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: memorize ? [_Memorize(lesson: ls)] : [for (final p in points) _Point(point: p)],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: FilledButton(
          key: const ValueKey('sense-finish'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.ai, minimumSize: const Size.fromHeight(48)),
          onPressed: _finish,
          child: Text(isRef ? tr('닫기') : (last ? tr('마침') : tr('마침 · 다음 회'))),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final Map<String, dynamic> point;
  const _Point({required this.point});

  @override
  Widget build(BuildContext context) {
    final sentences = (point['sentences'] as List).cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.washi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: kCardShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(point['head'] as String,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ai)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(8)),
          child: Text('💡 ${point['tip']}', style: const TextStyle(fontSize: 13, color: AppColors.sumi, height: 1.45)),
        ),
        const SizedBox(height: 6),
        for (final s in sentences)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: double.infinity,
                    child: SelectableText(s['fa'] as String,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.45)),
                  ),
                  if (s['rd'] != null) KoReadingText(s['rd'] as String, style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight)),
                  Text(s['ko'] as String,
                      style: const TextStyle(fontSize: 13, color: AppColors.ai, fontWeight: FontWeight.w600)),
                ]),
              ),
              IconButton(
                tooltip: tr('듣기'),
                icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 22),
                onPressed: () => _say(s['fa'] as String),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// 「5문장을 암기하세요」 회차 — 영상 → 안내 한 줄 → 문장만(조사 설명 없음).
/// 문장 표시 `{낱말|번호}` = 익힐 자리. 같은 번호는 페르시아어·한국어에서 같은 색 — 두 말의 어미·조사를 견줘 보게(일본어앱과 같음).
const _kMarkColors = [
  Color(0xFFD83A3A), Color(0xFF2F6FDB), Color(0xFF1E9E5A), Color(0xFFE08A00), Color(0xFF8E44AD),
  Color(0xFF00897B), Color(0xFFC2185B), Color(0xFF5D4037), Color(0xFF3949AB), Color(0xFF7CB342),
];

final _kMark = RegExp(r'\{([^|}]+)\|(\d+)\}');

/// 표시 없앤 본문(듣기용).
String plainMarked(String s) => s.replaceAllMapped(_kMark, (m) => m.group(1)!);

List<InlineSpan> markedSpans(String s, TextStyle base) {
  final out = <InlineSpan>[];
  var i = 0;
  for (final m in _kMark.allMatches(s)) {
    if (m.start > i) out.add(TextSpan(text: s.substring(i, m.start)));
    final c = _kMarkColors[(int.parse(m.group(2)!) - 1) % _kMarkColors.length];
    out.add(TextSpan(
        text: m.group(1),
        style: TextStyle(color: c, fontWeight: FontWeight.w900, decoration: TextDecoration.underline, decorationColor: c.withValues(alpha: 0.5), decorationThickness: 2)));
    i = m.end;
  }
  if (i < s.length) out.add(TextSpan(text: s.substring(i)));
  return out;
}

class _Memorize extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const _Memorize({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final sentences = (lesson['sentences'] as List).cast<Map<String, dynamic>>();
    const faStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.45);
    const koStyle = TextStyle(fontSize: 14, color: AppColors.sumi, height: 1.45);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // 영상 칸은 페르시아어 영상이 생기면 넣는다(헝가리어앱 LessonVideo) — 지금은 영상이 없어 빈 「영상 준비 중」 칸도 두지 않는다(2026-11-22 uk 공지).
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10)),
        child: Text('💡 ${lesson['note'] ?? ''}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.45)),
      ),
      const SizedBox(height: 6),
      for (var i = 0; i < sentences.length; i++)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(color: AppColors.washi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${i + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ai)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (sentences[i]['who'] != null) Text(sentences[i]['who'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
                SizedBox(
                  width: double.infinity,
                  child: Text.rich(TextSpan(style: faStyle, children: markedSpans(sentences[i]['fa'] as String, faStyle)), textDirection: TextDirection.rtl),
                ),
                if (sentences[i]['rd'] != null)
                  KoReadingText(sentences[i]['rd'] as String, style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight)),
                const SizedBox(height: 4),
                Text.rich(TextSpan(style: koStyle, children: markedSpans(sentences[i]['ko'] as String, koStyle))),
              ]),
            ),
            IconButton(
              tooltip: tr('듣기'),
              icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 22),
              onPressed: () => _say(plainMarked(sentences[i]['fa'] as String), sentences[i]['who'] as String?),
            ),
          ]),
        ),
      if ((lesson['footnotes'] as List?)?.isNotEmpty ?? false) ...[
        const SizedBox(height: 16),
        Text(tr('한국어와 다른 곳만 잠깐'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
        const SizedBox(height: 4),
        for (final f in (lesson['footnotes'] as List).cast<String>())
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('· $f', style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight, height: 1.45)),
          ),
      ],
    ]);
  }
}
