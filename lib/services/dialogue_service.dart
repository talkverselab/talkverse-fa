import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../core/embed_env.dart';
import '../core/prefs.dart';
import 'learner_prefs.dart';
import 'script_sync.dart';

/// 회화 리더(일본어앱 시안 02 「만화책 읽기형」)용 회화 모델 — 2026-11-02, 일본어앱 `dialogue_service.dart` 를 옮김.
///
/// 2026-11-18: 새 구조 `assets/data/dialogues/R<n>/<주제>/<편 id>.json` 을 읽고, 서버에 더 새 원고가 있으면 그것([ScriptSync]).
/// R 편이 하나도 없을 때만 옛 `L1.json`(초안 5편)을 읽는다.
/// 칸: tl = 페르시아어(옛 파일의 칸 이름은 템플릿 그대로 `es`), gloss = 테헤란 입말 줄(`tl_col`, 아직 없음), rd = 한글 독음, ko = 한국어, note = 「표현 = 뜻」.
/// 문장 내용어 한 개: 표면형(문장 속)·기본형(사전형)·한글 읽기 — 단어장 연결(2026-11-04, 일본어앱과 같은 모양).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

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
  final List<Lemma> lemmas; // 문장 내용어 — 단어장 연결(tools/add_lemmas_fa.py)
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
    this.lemmas = const [],
  });

  factory DialogueTurn.fromL1(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: (j['tl'] ?? j['es']) as String? ?? '',
        gloss: j['tl_col'] as String? ?? '', // 테헤란 입말 한 줄(UX 시안 FA-01 ②) — 데이터는 회화 작업 뒤, 없으면 칩을 숨긴다
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );

  /// 그림 조회용 핵심 단어 후보: note 「표현 = 뜻」의 왼쪽 페르시아어 낱말.
  List<String> get pictureWords {
    final i = note.indexOf('=');
    if (i < 0) return const [];
    return note.substring(0, i).split(RegExp(r'[^\u0600-\u06FF\u200C]+')).where((w) => w.length >= 2).toList();
  }
}

/// 편 `cast` 의 목소리 이름 → 성별(tools/tts 와 같은 이름).
const kVoiceGender = {
  'negar': 'female', 'sara': 'female', 'woman_y': 'female', 'woman_m': 'female', 'woman_o': 'female',
  'reza': 'male', 'arash': 'male', 'man_y': 'male', 'man_m': 'male', 'man_o': 'male',
};

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

  /// 새 편 파일(`R<n>/<주제>/<편 id>.json`). 화자 성별은 편 `cast` 목소리 이름으로(없으면 학습자 설정).
  factory Dialogue.fromJson(Map<String, dynamic> j) {
    final sp = ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
    final cast = ((j['cast'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
    return Dialogue(
      id: j['id'] as String,
      region: j['region'] as String? ?? 'R1',
      island: j['island'] as String? ?? 'life',
      title: j['title'] as String? ?? j['id'] as String,
      emoji: j['emoji'] as String? ?? '💬',
      scene: j['scene'] as String? ?? '',
      speakers: sp,
      genders: {for (final e in cast.entries) if (kVoiceGender[e.value] != null) e.key: kVoiceGender[e.value]!},
      expressions: ((j['expressions'] as List?) ?? const []).map((e) => '$e').toList(),
      turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList(),
      art: j['art'] as String?,
    );
  }

  /// 화자 표시 이름. `{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별 — 편 데이터에 있으면 그것(cast·옛 L1 characters), 없으면(A = 학습자) 학습자 설정.
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
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  /// 여러 화면이 동시에 불러도 한 번만 읽는다(넓은 화면에서 탭이 함께 떠 목록이 두 번 차는 문제).
  Future<void> ensureLoaded() => _loading ??= _load();

  /// 원고가 서버 판으로 바뀌어 다시 읽힐 때마다 오른다.
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<void> _load() async {
    _lastOpened = (await Prefs.getInstance()).getString(_prefLast);
    await _readAll();
    // 서버에 더 새 원고가 있으면 뒤에서 받아 다시 읽는다(없거나 실패하면 그대로)
    ScriptSync.instance.refresh().then((changed) async {
      if (!changed) return;
      await _readAll();
      revision.value++;
    });
  }

  /// 앱 안 편 + 서버에서 받은 새 편. 각 파일은 덮어쓴 판이 있으면 그것.
  Future<void> _readAll() async {
    final next = <Dialogue>[];
    try {
      final sync = ScriptSync.instance;
      await sync.init();
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final pat = RegExp(r'^assets/data/dialogues/R[0-4]/[^/]+/[^/]+\.json$');
      // 매니페스트 키는 통합 앱이면 packages/persian_universe/ 가 붙어 있다 — 접두를 떼고 견준다
      final rels = <String>{
        for (final p in manifest.listAssets().map(stripAssetPrefix).where(pat.hasMatch)) p.substring('assets/data/'.length),
        ...sync.added.where((p) => pat.hasMatch('assets/data/$p')),
      }..removeAll(sync.removed);
      for (final rel in rels) {
        try {
          final d = Dialogue.fromJson(json.decode(await sync.load(rel)) as Map<String, dynamic>);
          if (d.turns.isNotEmpty) next.add(d);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('DialogueService: 읽기 실패 $e');
    }
    if (next.isEmpty) next.addAll(await _readL1());
    next.sort((a, b) => a.id.compareTo(b.id));
    _all
      ..clear()
      ..addAll(next);
  }

  Future<List<Dialogue>> _readL1() async {
    final out = <Dialogue>[];
    try {
      final j = json.decode(await rootBundle.loadString(assetPath('assets/data/dialogues/L1.json'))) as Map<String, dynamic>;
      final chars = (j['characters'] as Map<String, dynamic>? ?? const {});
      final names = chars.map((k, v) => MapEntry(k, ((v as Map)['name'] ?? k).toString()));
      final genders = chars.map((k, v) => MapEntry(k, ((v as Map)['gender'] ?? 'female').toString()));
      final level = j['level'] as String? ?? 'L1';
      for (final e in (j['episodes'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        final turns = ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList();
        if (turns.isEmpty) continue;
        out.add(Dialogue(
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
    return out;
  }

  Dialogue? byId(String id) => _all.where((d) => d.id == id).firstOrNull;
  List<Dialogue> get all => List.unmodifiable(_all);
  List<String> get regions => (_all.map((d) => d.region).toSet().toList()..sort());

  List<Dialogue> list({String? region, String? island}) =>
      _all.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();

  List<String> islandsOf(String region) {
    final has = _all.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _all.where((d) => d.region == region).length;
}
