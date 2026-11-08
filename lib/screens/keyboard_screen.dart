import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';
import '../widgets/persian_keyboard_guide.dart';

/// 키보드 연습 — 아랍어앱(옛 앱 keyboard_screen)에서 옮김(2026-11-08, 사용자 지시 「아랍어앱 키보드 가져오기」).
/// 기기 키보드(삼성·Gboard·iOS)의 페르시아어 입력기로 목표 글을 따라 친다. 오른쪽→왼쪽.
/// 모음 부호·ZWNJ(띄어쓰기로 쳐도 됨)·아랍식 ي ك·آ/ا 차이는 정답 판정에서 무시한다.
enum KeyboardItems { words, sentences }

class _Item {
  final String tl, rd, ko;
  const _Item(this.tl, this.rd, this.ko);
}

class KeyboardScreen extends StatefulWidget {
  final KeyboardItems items;
  const KeyboardScreen({super.key, this.items = KeyboardItems.words});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late KeyboardItems _items = widget.items;
  List<_Item> _list = const [];
  bool _loading = true;
  int _i = 0, _score = 0;
  bool? _ok;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final out = <_Item>[];
    if (_items == KeyboardItems.words) {
      final rows = const CsvToListConverter(eol: '\n').convert(await rootBundle.loadString('assets/data/freq/lang_es_top.csv'));
      final h = rows.first.map((e) => '$e').toList();
      final w = h.indexOf('word'), ko = h.indexOf('ko'), rd = h.indexOf('rd');
      for (final r in rows.skip(1)) {
        final word = '${r[w]}'.trim();
        if (word.isEmpty || word.contains('-') || '${r[ko]}'.trim().isEmpty) continue; // 접사(-م·می-)는 따로 칠 수 없다
        out.add(_Item(word, '${r[rd]}', '${r[ko]}'));
      }
    } else {
      await DialogueService.instance.ensureLoaded();
      final seen = <String>{};
      for (final d in DialogueService.instance.all) {
        for (final t in d.turns) {
          final s = LearnerPrefs.fill(t.tl).trim();
          if (s.isEmpty || !seen.add(s)) continue;
          out.add(_Item(s, LearnerPrefs.fill(t.rd, ko: true), LearnerPrefs.fill(t.ko, ko: true)));
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _list = out;
      _loading = false;
      _i = 0;
      _ok = null;
      _controller.clear();
    });
    if (out.isNotEmpty) {
      _speak();
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  _Item get _cur => _list[_i];
  void _speak() => TtsService.instance.speak(_cur.tl);

  /// 모음 부호·타트윌 제거, ZWNJ → 띄어쓰기, 아랍식 글자 → 페르시아 글자, 알레프 변형 통일, 문장부호·겹칸 정리.
  static String norm(String s) => s
      .replaceAll(RegExp('[ً-ْٰـ]'), '')
      .replaceAll('‌', ' ')
      .replaceAll('ي', 'ی')
      .replaceAll('ى', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[؟?!.,،؛:«»"…]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  void _changed(String v) {
    final got = norm(v), want = norm(_cur.tl);
    if (got.isEmpty || got.length < want.length) {
      if (_ok != null) setState(() => _ok = null);
      return;
    }
    final ok = got == want;
    setState(() => _ok = ok);
    if (ok) {
      _score++;
      _focus.unfocus();
    }
  }

  void _next() {
    setState(() {
      _i = (_i + 1) % _list.length;
      _controller.clear();
      _ok = null;
    });
    _speak();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final title = tr('키보드 연습');
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        backgroundColor: AppColors.washi,
        title: Text(title, style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), tooltip: tr('키보드 설정법'), onPressed: () => showPersianKeyboardGuide(context)),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(trf('점수 {0}', [_score]), style: const TextStyle(color: AppColors.matcha, fontWeight: FontWeight.w800))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? Center(child: Text(tr('연습할 항목이 없어요'), style: const TextStyle(color: AppColors.muted)))
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)),
                        child: Column(children: [
                          SegmentedButton<KeyboardItems>(
                            segments: [
                              ButtonSegment(value: KeyboardItems.words, label: Text(tr('절벽 단어')), icon: const Icon(Icons.text_fields)),
                              ButtonSegment(value: KeyboardItems.sentences, label: Text(tr('회화 문장')), icon: const Icon(Icons.chat_bubble_outline)),
                            ],
                            selected: {_items},
                            onSelectionChanged: (v) {
                              setState(() {
                                _items = v.first;
                                _loading = true;
                              });
                              _load();
                            },
                          ),
                          const SizedBox(height: 16),
                          _target(),
                          const SizedBox(height: 16),
                          _input(),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => showPersianKeyboardGuide(context),
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: Text(tr('키보드가 없으면? 설정 방법 보기'), style: const TextStyle(fontSize: 13)),
                          ),
                          if (_ok != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_ok! ? tr('🎉 정답!') : tr('❌ 다시 해 보세요'),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ok! ? AppColors.matcha : AppColors.fem)),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _next,
                              style: FilledButton.styleFrom(backgroundColor: AppColors.beni, padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: Text(_ok == true ? tr('다음 →') : tr('건너뛰기'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${_i + 1} / ${_list.length}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        ]),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _target() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: AppColors.beni, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Text(_cur.tl,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: _items == KeyboardItems.words ? 40 : 26, color: Colors.white, fontWeight: FontWeight.w700, height: 1.5)),
            ),
            IconButton(onPressed: _speak, icon: const Icon(Icons.volume_up), color: Colors.white, tooltip: tr('발음 듣기')),
          ]),
          if (_cur.rd.isNotEmpty) Text(_cur.rd, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
          const SizedBox(height: 4),
          Text(_cur.ko, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15)),
        ]),
      );

  Widget _input() {
    final c = _ok == true ? AppColors.matcha : (_ok == false ? AppColors.fem : AppColors.line);
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: 2));
    return TextField(
      controller: _controller,
      focusNode: _focus,
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      autocorrect: false,
      enableSuggestions: false,
      style: TextStyle(fontSize: _items == KeyboardItems.words ? 32 : 22, fontWeight: FontWeight.w700, height: 1.5, color: _ok == false ? AppColors.fem : AppColors.sumi),
      decoration: InputDecoration(
        hintText: 'اینجا بنویس',
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 18),
        filled: true,
        fillColor: c == AppColors.line ? AppColors.washiDeep : c.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.backspace_outlined, color: AppColors.muted),
                onPressed: () {
                  _controller.clear();
                  _changed('');
                }),
      ),
      onChanged: _changed,
      onSubmitted: _changed,
    );
  }
}
