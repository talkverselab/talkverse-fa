import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 앱 단어장(`assets/data/vocab/travel_words.json`) 조회 — 문장 레마 칩용(일본어앱 WordService.byLemmas 자리, 2026-11-04).
class VocabEntry {
  final String tx; // 페르시아어
  final String rd; // 한글 독음
  final String ko; // 뜻
  final String icon;
  const VocabEntry(this.tx, this.rd, this.ko, this.icon);
  String get gloss => ko;
}

class VocabService {
  VocabService._();
  static final VocabService instance = VocabService._();
  Future<Map<String, VocabEntry>>? _loading;

  Future<Map<String, VocabEntry>> _load() async {
    final out = <String, VocabEntry>{};
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/vocab/travel_words.json')) as Map<String, dynamic>;
      for (final t in (j['themes'] as List? ?? const [])) {
        for (final sec in ((t as Map)['sections'] as List? ?? const [])) {
          for (final w in ((sec as Map)['words'] as List? ?? const [])) {
            final m = w as Map;
            final tx = (m['tx'] ?? '').toString().trim();
            if (tx.isEmpty) continue;
            out.putIfAbsent(tx, () => VocabEntry(tx, '${m['rd'] ?? ''}', '${m['ko'] ?? ''}', '${m['ic'] ?? ''}'));
          }
        }
      }
    } catch (_) {}
    return out;
  }

  /// 기본형 → 단어장 항목(없으면 빠짐).
  Future<Map<String, VocabEntry>> byLemmas(Iterable<String> bases) async {
    final all = await (_loading ??= _load());
    return {for (final b in bases) if (all[b] != null) b: all[b]!};
  }
}
