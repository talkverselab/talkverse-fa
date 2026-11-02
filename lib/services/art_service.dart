import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

/// 단어 그림(talkverse.uk 공용 그림 저장소) — 2026-11-03.
///
/// talkverse.uk 세션이 Cloudflare 에 올린 공개 API(인증 없음) — 일본어앱에서 옮김(2026-11-02). 페르시아어 세트는 아직 0장:
/// - 목록 `GET https://auth.talkverse.uk/art/fa/manifest?level=R1` (level 생략 = 전체)
///   → `{lang, level, count, base, items:[{id, rank, level, word, reading, ko, en, pos, key_1024, key_512}]}`
/// - 그림 = `base + key` (512·1024 webp, 1년 캐시). 
/// 매니페스트는 SharedPreferences 에 하루 캐시하고, 없으면 그림 없이 카드가 그대로 나온다(실패해도 화면은 멀쩡해야 한다).
class ArtService {
  ArtService._();
  static final ArtService instance = ArtService._();

  static const manifestUrl = 'https://auth.talkverse.uk/art/fa/manifest';
  static const _prefKey = 'art_manifest_id_v1';
  static const _prefAt = 'art_manifest_id_at';
  static const _ttl = Duration(hours: 24);

  String _base = '';
  final Map<String, String> _byWord = {}; // word → key_512
  final Map<int, String> _byRank = {}; // rank → key_512
  final Map<String, int> _rankByWord = {}; // word → rank
  Future<void>? _loading;
  bool get isLoaded => _byWord.isNotEmpty;

  /// 단어(표제어) 또는 빈도 순위로 512px 그림 주소. 없으면 null.
  Future<String?> urlFor(String word, {int? rank}) async {
    await _ensure();
    final key = _byWord[word] ?? (rank != null ? _byRank[rank] : null);
    if (key == null || _base.isEmpty) return null;
    return _base.endsWith('/') ? '$_base$key' : '$_base/$key';
  }

  /// 문장 안에 들어 있는 그림 단어 중 가장 긴 것의 그림. 핵심 단어에 그림이 없을 때의 보조.
  Future<MapEntry<String, String>?> urlInText(String text) async {
    await _ensure();
    if (_base.isEmpty || text.isEmpty) return null;
    String? best;
    final words = text.split(RegExp(r'[^\u0600-\u06FF\u200C]+')).toSet(); // 페르시아 문자 — 낱말 단위로(부분 문자열이 긴 낱말에 걸리지 않게)
    for (final w in _byWord.keys) {
      if (w.length < 2 || !words.contains(w.toLowerCase())) continue;
      if (best == null || w.length > best.length) best = w;
    }
    if (best == null) return null;
    final key = _byWord[best]!;
    return MapEntry(best, _base.endsWith('/') ? '$_base$key' : '$_base/$key');
  }

  /// 로드 없이 즉시 조회(이미 받아 둔 경우만).
  String? urlForSync(String word, {int? rank}) {
    final key = _byWord[word] ?? (rank != null ? _byRank[rank] : null);
    if (key == null || _base.isEmpty) return null;
    return _base.endsWith('/') ? '$_base$key' : '$_base/$key';
  }

  Future<void> _ensure() => _loading ??= _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final at = prefs.getInt(_prefAt) ?? 0;
    final cached = prefs.getString(_prefKey);
    final fresh = DateTime.now().millisecondsSinceEpoch - at < _ttl.inMilliseconds;
    if (cached != null && fresh && _apply(cached)) return;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(manifestUrl));
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        if (_apply(body)) {
          await prefs.setString(_prefKey, body);
          await prefs.setInt(_prefAt, DateTime.now().millisecondsSinceEpoch);
          client.close();
          return;
        }
      }
      client.close();
    } catch (e) {
      debugPrint('ArtService: manifest 실패 $e');
    }
    if (cached != null) _apply(cached); // 오래된 캐시라도 쓴다
  }

  bool _apply(String body) {
    try {
      final j = json.decode(body) as Map<String, dynamic>;
      final base = j['base'] as String? ?? '';
      final items = j['items'] as List<dynamic>? ?? const [];
      if (base.isEmpty || items.isEmpty) return false;
      _base = base;
      _byWord.clear();
      _byRank.clear();
      _rankByWord.clear();
      for (final it in items) {
        final m = it as Map<String, dynamic>;
        final key = m['key_512'] as String? ?? m['key_1024'] as String?;
        if (key == null) continue;
        final w = m['word'] as String?;
        if (w != null && w.isNotEmpty) _byWord[w] = key;
        final r = m['rank'];
        final rank = r is int ? r : (r is String ? int.tryParse(r) : null);
        if (rank != null) {
          _byRank[rank] = key;
          if (w != null && w.isNotEmpty) _rankByWord[w] = rank;
        }
      }
      return _byWord.isNotEmpty;
    } catch (e) {
      debugPrint('ArtService: manifest 파싱 실패 $e');
      return false;
    }
  }
}
