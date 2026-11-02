import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'learner_prefs.dart';

/// 회화 리더(일본어앱 시안 02 「만화책 읽기형」)용 회화 모델 — 2026-11-02, 일본어앱 `dialogue_service.dart` 를 옮김.
///
/// 지금 데이터는 옛 `assets/data/dialogues/L1.json`(초안 5편 × 8턴) 하나뿐이라 그것을 그대로 읽어 이 모양으로 바꾼다.
/// 회화 콘텐츠는 바꾸지 않는다(사용자 지시 2026-11-02 "회화는 아직 하지마") — 새 구조(R0~R4·주제별 편 파일)는 회화 작성이 풀리면.
/// 칸: tl = 페르시아어(옛 파일의 칸 이름은 템플릿 그대로 `es`), gloss = 없음(빈 값), rd = 한글 독음, ko = 한국어, note = 「표현 = 뜻」.
class DialogueTurn {
  final int num;
  final String speaker; // A·B
  final String tl;
  final String gloss;
  final String rd;
  final String ko;
  final String note;
  final List<String> tags;
  final String? art; // 장면 그림 URL(나중에 채움)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.tl,
    required this.gloss,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    this.art,
  });

  factory DialogueTurn.fromL1(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: j['es'] as String? ?? '',
        gloss: j['gloss'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
      );

  /// 그림 조회용 핵심 단어 후보: note 「표현 = 뜻」의 왼쪽 페르시아어 낱말.
  List<String> get pictureWords {
    final i = note.indexOf('=');
    if (i < 0) return const [];
    return note.substring(0, i).split(RegExp(r'[^\u0600-\u06FF\u200C]+')).where((w) => w.length >= 2).toList();
  }
}

class Dialogue {
  final String id;
  final String region; // 지금은 옛 레벨 이름(L1) 그대로 — R 재태그는 회화 작업 때
  final String island; // 주제
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final Map<String, String> genders;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final String? art;
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.expressions,
    required this.turns,
    this.art,
  });

  /// 화자 표시 이름. `{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별 — 지금 회화는 화자 이름·성별이 정해진 이야기(A 민준 남 · B 사라 여)라 데이터의 성별을 따른다.
  String voiceGender(String sp) => genders[sp] ?? LearnerPrefs.voiceGender(sp);
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '일',
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  static const levelKo = {'L1': '이야기', 'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급'};
  static const _prefLast = 'dialogue_last';

  final List<Dialogue> _all = [];
  Future<void>? _loading;
  String? _lastOpened;
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await SharedPreferences.getInstance()).setString(_prefLast, id);
  }

  /// 여러 화면이 동시에 불러도 한 번만 읽는다(넓은 화면에서 탭이 함께 떠 목록이 두 번 차는 문제).
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    _lastOpened = (await SharedPreferences.getInstance()).getString(_prefLast);
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/dialogues/L1.json')) as Map<String, dynamic>;
      final chars = (j['characters'] as Map<String, dynamic>? ?? const {});
      final names = chars.map((k, v) => MapEntry(k, ((v as Map)['name'] ?? k).toString()));
      final genders = chars.map((k, v) => MapEntry(k, ((v as Map)['gender'] ?? 'female').toString()));
      final level = j['level'] as String? ?? 'L1';
      for (final e in (j['episodes'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        final turns = ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList();
        if (turns.isEmpty) continue;
        _all.add(Dialogue(
          id: '${level}_${m['id']}',
          region: level,
          island: 'love', // 옛 L1 = 언어교환 앱에서 시작하는 설렘 이야기(원칙: 기존 연애 서사는 love 주제)
          title: m['title'] as String? ?? m['id'] as String,
          emoji: m['emoji'] as String? ?? '💬',
          scene: m['scenario'] as String? ?? '',
          speakers: names,
          genders: genders,
          expressions: const [],
          turns: turns,
        ));
      }
    } catch (_) {}
  }

  Dialogue? byId(String id) => _all.where((d) => d.id == id).firstOrNull;
  List<Dialogue> get all => List.unmodifiable(_all);
  List<String> get regions => _all.map((d) => d.region).toSet().toList();

  List<Dialogue> list({String? region, String? island}) =>
      _all.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();

  List<String> islandsOf(String region) {
    final has = _all.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _all.where((d) => d.region == region).length;
}
