import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/persian_phonetics.dart';
import '../services/tts_service.dart';
import '../widgets/fa_sound_sheet.dart';

/// 문자와 발음 — 일본어앱 「50음도와 발음」의 페르시아어판(2026-11-08, 공통 프롬프터 §5-3).
/// 오른쪽→왼쪽 격자 · 묶음 칩(글자 32 / 같은 소리 글자 / 모음 6) · 로마자 토글. 글자 탭 = 발음 시트.
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  String _group = 'all';
  bool _roman = true;

  static const _palette = [AppColors.beni, AppColors.oliva, AppColors.farsi, AppColors.mar, AppColors.rojoDeep, AppColors.irregular];

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        backgroundColor: AppColors.washi,
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('문자와 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('탭하면 발음·IPA 상세'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          IconButton(
            tooltip: tr('로마자'),
            icon: Text('Aa', style: TextStyle(fontWeight: FontWeight.w900, color: _roman ? AppColors.beni : AppColors.sumiLight)),
            onPressed: () => setState(() => _roman = !_roman),
          ),
        ],
      ),
      body: Column(children: [
        _chips(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            const Icon(Icons.arrow_back, size: 14, color: AppColors.muted),
            const SizedBox(width: 4),
            Expanded(child: Text(_hint, style: const TextStyle(fontSize: 11, color: AppColors.muted))),
          ]),
        ),
        Expanded(child: _group == 'same' ? _sameRows() : _grid(_group == 'vowel' ? faVowels : faLetters)),
      ]),
    );
  }

  String get _hint => switch (_group) {
        'vowel' => tr('짧은 모음 a·e·o 는 보통 적지 않아요. 긴 모음 â·i·u 는 글자(ا·ی·و)로 적어요.'),
        'same' => tr('소리가 같은 글자 묶음 — 아랍어에서 온 글자라 페르시아어에서는 같은 소리로 읽어요.'),
        _ => tr('오른쪽에서 왼쪽으로 읽어요. 칸 아래는 글자 이름이에요.'),
      };

  Widget _chips() => Container(
        width: double.infinity,
        color: AppColors.washiDeep,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final e in faGroups.entries)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tr(e.value)),
                  selected: _group == e.key,
                  onSelected: (_) => setState(() => _group = e.key),
                  selectedColor: AppColors.beni,
                  labelStyle: TextStyle(color: _group == e.key ? Colors.white : AppColors.beni, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
          ]),
        ),
      );

  Color _colorOf(FaSound s) => switch (s.group) {
        'same' => AppColors.oliva,
        'vowel' || 'vowelLetter' => AppColors.farsi,
        _ => AppColors.beni,
      };

  Widget _grid(List<FaSound> list) => LayoutBuilder(builder: (context, c) {
        final cols = (c.maxWidth / 86).floor().clamp(4, 9);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + bottomInset(context)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.82),
            itemCount: list.length,
            itemBuilder: (_, i) => _cell(list[i], _colorOf(list[i])),
          ),
        );
      });

  Widget _cell(FaSound s, Color color) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showFaSoundSheet(context, s, color),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.washi,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.6)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.ch, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.2)),
            Text(s.nameKo, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
            if (_roman) Text(s.roman, maxLines: 1, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ]),
        ),
      );

  Widget _sameRows() => ListView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + bottomInset(context)),
        children: [
          for (var r = 0; r < faSameSound.length; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _palette[r % _palette.length], borderRadius: BorderRadius.circular(10)),
                  child: Text(faSameSound[r].$1, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(children: [
                      for (final ch in faSameSound[r].$2)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: SizedBox(height: 84, child: _cell(faSoundOf(ch)!, _palette[r % _palette.length])),
                          ),
                        ),
                      for (var k = faSameSound[r].$2.length; k < 4; k++) const Expanded(child: SizedBox()),
                    ]),
                  ),
                ),
              ]),
            ),
        ],
      );
}
