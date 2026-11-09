import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/embed_env.dart';
import '../core/cliff.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/word_art_thumb.dart';

/// 절벽 단어 — 빈도 1~1,500위를 구간(R1~R3·EXT)별 **20어 단원**, 단어는 **네모 타일**(일본어앱 구조, 사용자 지시 2026-11-07).
/// 「회화 단어 포함」이면 회화 레마 중 1,500위 밖 단어(assets/data/freq/conv_words_fa.json)가 「회화」 구간으로 뒤에 붙는다.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordEntry> _words = const [];
  List<WordEntry> _conv = const [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';
  String _query = '';

  static Map<String, _Region> get _regions => {
        'ALL': _Region(tr('전체'), AppColors.sumi),
        'R1': _Region('R1 · 1-${kCliffs[0]}', AppColors.beni),
        'R2': _Region('R2 · ${kCliffs[0] + 1}-${kCliffs[1]}', AppColors.beniLight),
        'R3': _Region('R3 · ${kCliffs[1] + 1}-${kCliffs[2]}', AppColors.beniDeep),
        'EXT': _Region('EXT · ${kCliffs[2] + 1}-$kWordCap', AppColors.muted),
        'C': _Region(tr('회화'), AppColors.ai),
      };

  @override
  void initState() {
    super.initState();
    KoReadingPrefs.show.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    KoReadingPrefs.show.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _load() async {
    final rows = const CsvToListConverter(eol: '\n').convert(await rootBundle.loadString(assetPath('assets/data/freq/lang_es_top.csv')));
    final words = <WordEntry>[];
    for (final r in rows.skip(1)) {
      if (r.length < 10) continue;
      final rank = int.tryParse('${r[0]}') ?? 0;
      if (rank < 1 || rank > kWordCap) continue;
      words.add(WordEntry(rank: rank, word: '${r[1]}', ko: '${r[4]}', rd: '${r[9]}', region: '${r[7]}'));
    }
    final conv = <WordEntry>[];
    final j = json.decode(await rootBundle.loadString(assetPath('assets/data/freq/conv_words_fa.json'))) as Map<String, dynamic>;
    for (final w in (j['words'] as List).cast<Map<String, dynamic>>()) {
      conv.add(WordEntry(rank: conv.length + 1, word: '${w['word']}', ko: '${w['ko'] ?? ''}', rd: '${w['rd'] ?? ''}', region: 'C'));
    }
    if (!mounted) return;
    setState(() {
      _words = words;
      _conv = conv;
      _loading = false;
    });
  }

  void _setConv(bool v) => setState(() {
        _withConv = v;
        if (!v && _filter == 'C') _filter = 'ALL';
      });

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final shown = [
      for (final w in _withConv ? [..._words, ..._conv] : _words)
        if ((_filter == 'ALL' || w.region == _filter) && (q.isEmpty || w.word.contains(q) || w.ko.contains(q))) w,
    ];
    final units = [
      for (var i = 0; i < shown.length; i += kUnit) shown.sublist(i, (i + kUnit).clamp(0, shown.length)),
    ];
    final regions = _regions;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(trf('회화 빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['1,500', kUnit]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: const [KoReadingToggleAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(children: [
              Container(
                color: AppColors.washiDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(children: [
                  Row(children: [
                    _ModeButton(label: tr('절벽구간 단어만'), selected: !_withConv, onTap: () => _setConv(false)),
                    const SizedBox(width: 8),
                    _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => _setConv(true)),
                  ]),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final e in regions.entries)
                        if (e.key != 'C' || _withConv)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Chip(region: e.value, selected: _filter == e.key, onTap: () => setState(() => _filter = e.key)),
                          ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: tr('단어 / 뜻 검색'),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ]),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final cols = (c.maxWidth / 112).floor().clamp(3, 8);
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                    itemCount: units.length,
                    itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], regions: regions, cols: cols),
                  );
                }),
              ),
            ]),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  final _Region region;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.region, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? region.color : AppColors.washi,
            border: Border.all(color: region.color, width: selected ? 1.5 : 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(region.label, style: TextStyle(color: selected ? AppColors.washi : region.color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index, cols;
  final List<WordEntry> words;
  final Map<String, _Region> regions;
  const _UnitBlock({required this.index, required this.words, required this.regions, required this.cols});

  @override
  Widget build(BuildContext context) {
    final first = words.first, last = words.last;
    final conv = first.region == 'C';
    final color = regions[first.region]?.color ?? AppColors.sumi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
          child: Row(children: [
            Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text(conv ? trf('회화 {0}-{1}', [first.rank, last.rank]) : '#${first.rank}-${last.rank}', style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              child: Text(conv ? tr('회화') : first.region, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6),
          itemCount: words.length,
          itemBuilder: (context, i) => _WordTile(w: words[i], color: color),
        ),
      ]),
    );
  }
}

/// 네모 타일 — 순위·독음 · 그림(있으면) · 단어 · 뜻. 탭하면 발음.
class _WordTile extends StatelessWidget {
  final WordEntry w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  /// 접사 행(-م · می-)은 붙임표를 떼고 읽고, 글자가 없는 행(-e 등)은 소리 없음.
  void _speak() {
    final s = w.word.replaceAll('-', '');
    if (!RegExp(r'[a-zA-Zā]').hasMatch(s)) TtsService.instance.speak(s);
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: _speak,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.washi,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(8),
            boxShadow: kCardShadow,
          ),
          padding: const EdgeInsets.all(6),
          child: Column(children: [
            Row(children: [
              Text(w.region == 'C' ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (w.rd.isNotEmpty)
                Flexible(flex: 3, child: KoReadingText(w.rd, style: const TextStyle(fontSize: 9, color: AppColors.sumiLight))),
            ]),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final size = (c.maxHeight < c.maxWidth ? c.maxHeight : c.maxWidth) - 4;
                return Center(child: size < 16 ? const SizedBox.shrink() : WordArtThumb(word: w.word, rank: w.region == 'C' ? null : w.rank, size: size));
              }),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(w.word, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            ),
            if (w.ko.isNotEmpty)
              Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
          ]),
        ),
      );
}

class WordEntry {
  final int rank;
  final String word, ko, rd;
  final String region; // R1~R3 · EXT · C(회화 단어)
  const WordEntry({required this.rank, required this.word, required this.ko, required this.rd, required this.region});
}

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}
