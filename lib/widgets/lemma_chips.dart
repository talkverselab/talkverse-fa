import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_service.dart';
import 'glyph_sheet.dart';

/// 문장의 내용어(레마) 칩 — 일본어앱 lemma_chips 이식(사용자 지시 2026-11-04 "문장 레마별로 단어장이랑 연결").
/// 단어장에 있는 말은 누르면 단어 시트, 없는 말은 회색(누르면 글자 시트). 같은 기본형은 한 번만.
/// 단어장에 없는 레마는 `data/review/write/missing_lemmas.csv` 로 uk 세션에 넘긴다.
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final lemmas = [for (final l in turn.lemmas) if (seen.add(l.base)) l];
    if (lemmas.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, VocabEntry>>(
      key: ValueKey('${turn.num}:${turn.tl}'),
      future: VocabService.instance.byLemmas(lemmas.map((l) => l.base)),
      builder: (context, snap) {
        final found = snap.data ?? const {};
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final l in lemmas)
              _Chip(
                label: l.base,
                gloss: found[l.base]?.gloss,
                compact: compact,
                on: found[l.base] != null,
                onTap: () => found[l.base] != null ? _wordSheet(context, found[l.base]!) : GlyphSheet.show(context, l.base),
              ),
          ]),
        );
      },
    );
  }

  static void _wordSheet(BuildContext context, VocabEntry e) => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: AppColors.washi,
        builder: (c) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Row(children: [
            if (e.icon.isNotEmpty) Text(e.icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.tx, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                if (e.rd.isNotEmpty) Text(e.rd, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(e.ko, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumiLight)),
              ]),
            ),
            IconButton(tooltip: tr('듣기'), icon: const Icon(Icons.volume_up, color: AppColors.beni), onPressed: () => TtsService.instance.speak(e.tx)),
          ]),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact, on;
  final VoidCallback onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
          decoration: BoxDecoration(
            color: on ? AppColors.washi : AppColors.washiDeep,
            border: Border.all(color: on ? AppColors.beni.withValues(alpha: 0.7) : AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: compact ? 12.5 : 14, fontWeight: FontWeight.w800, color: on ? AppColors.sumi : AppColors.muted)),
            if (gloss != null && gloss!.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(gloss!, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.sumiLight)),
            ],
          ]),
        ),
      );
}
