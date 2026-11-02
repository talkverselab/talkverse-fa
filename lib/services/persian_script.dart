/// 페르시아 문자 — 글자 모양(홀로·앞·가운데·끝) 계산. UX 시안 FA-01 ①「글자 시트」(2026-11-03).
///
/// 모양은 표를 따로 두지 않고 유니코드 결합 규칙으로 만든다: 앞 = 글자+ZWJ, 가운데 = ZWJ+글자+ZWJ, 끝 = ZWJ+글자.
/// 소리는 `docs/DIALOGUE_NOTES.md` §4 독음 표기표의 자음 자리(모음 글자는 대표 소리).
library;

enum GlyphForm { isolated, initial, medial, finalForm }

extension GlyphFormKo on GlyphForm {
  String get ko => switch (this) {
        GlyphForm.isolated => '홀로',
        GlyphForm.initial => '앞',
        GlyphForm.medial => '가운데',
        GlyphForm.finalForm => '끝',
      };
}

class PersianLetter {
  final String ch;
  final String sound; // 한글 소리
  final bool dual; // 왼쪽(다음 글자)으로도 이어지는가 — ا د ذ ر ز ژ و 는 이어지지 않는다
  const PersianLetter(this.ch, this.sound, {this.dual = true});

  List<GlyphForm> get forms => dual ? GlyphForm.values : const [GlyphForm.isolated, GlyphForm.finalForm];

  String shape(GlyphForm f) => switch (f) {
        GlyphForm.isolated => ch,
        GlyphForm.initial => '$ch‍',
        GlyphForm.medial => '‍$ch‍',
        GlyphForm.finalForm => '‍$ch',
      };
}

/// 페르시아어 32글자(+ آ). 순서는 알파벳 순.
const persianLetters = <PersianLetter>[
  PersianLetter('ا', '아·어', dual: false),
  PersianLetter('آ', '아(길게)', dual: false),
  PersianLetter('ب', 'ㅂ'),
  PersianLetter('پ', 'ㅍ'),
  PersianLetter('ت', 'ㅌ'),
  PersianLetter('ث', 'ㅅ'),
  PersianLetter('ج', 'ㅈ'),
  PersianLetter('چ', 'ㅊ'),
  PersianLetter('ح', 'ㅎ'),
  PersianLetter('خ', 'ㅋ(kh)'),
  PersianLetter('د', 'ㄷ', dual: false),
  PersianLetter('ذ', 'ㅈ(z)', dual: false),
  PersianLetter('ر', 'ㄹ', dual: false),
  PersianLetter('ز', 'ㅈ(z)', dual: false),
  PersianLetter('ژ', 'ㅈ(zh)', dual: false),
  PersianLetter('س', 'ㅅ'),
  PersianLetter('ش', '시'),
  PersianLetter('ص', 'ㅅ'),
  PersianLetter('ض', 'ㅈ(z)'),
  PersianLetter('ط', 'ㅌ'),
  PersianLetter('ظ', 'ㅈ(z)'),
  PersianLetter('ع', '무음'),
  PersianLetter('غ', 'ㄱ(gh)'),
  PersianLetter('ف', 'ㅍ(f)'),
  PersianLetter('ق', 'ㄱ(q)'),
  PersianLetter('ک', 'ㅋ'),
  PersianLetter('گ', 'ㄱ'),
  PersianLetter('ل', 'ㄹ'),
  PersianLetter('م', 'ㅁ'),
  PersianLetter('ن', 'ㄴ'),
  PersianLetter('و', '우·ㅂ(v)', dual: false),
  PersianLetter('ه', 'ㅎ'),
  PersianLetter('ی', '이·ㅇ(y)'),
];

final Map<String, PersianLetter> _byChar = {
  for (final l in persianLetters) l.ch: l,
  'ك': persianLetters.firstWhere((l) => l.ch == 'ک'), // 아랍식 카프·야도 같은 글자로
  'ي': persianLetters.firstWhere((l) => l.ch == 'ی'),
};

PersianLetter? letterOf(String ch) => _byChar[ch];

/// 성과 「익힌 글자 모양」 분모 — 양쪽으로 이어지는 글자 4모양 + 오른쪽만 이어지는 글자 2모양(آ 는 ا 와 같은 글자로 셈).
int get totalGlyphForms => persianLetters.where((l) => l.ch != 'آ').fold(0, (n, l) => n + l.forms.length);

class GlyphInWord {
  final PersianLetter letter;
  final GlyphForm form;
  const GlyphInWord(this.letter, this.form);
  String get key => '${letter.ch == 'آ' ? 'ا' : letter.ch}:${form.name}';
}

/// 낱말 → 글자마다 지금 쓰인 모양(읽는 순서 = 오른쪽부터). ZWNJ(‌)에서 이음이 끊긴다. 모음 부호·숫자 등은 건너뛴다.
List<GlyphInWord> splitWord(String word) {
  final out = <GlyphInWord>[];
  PersianLetter? prev;
  var brokeAfterPrev = false;
  final chars = word.runes.map(String.fromCharCode).toList();
  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];
    if (c == '‌') {
      brokeAfterPrev = true;
      continue;
    }
    final l = letterOf(c);
    if (l == null) continue;
    final joinPrev = prev != null && prev.dual && !brokeAfterPrev;
    // 다음 글자가 있고 이 글자가 왼쪽으로 이어지면 앞으로 이어진다
    var joinNext = false;
    if (l.dual) {
      for (var j = i + 1; j < chars.length; j++) {
        if (chars[j] == '‌') break;
        if (letterOf(chars[j]) != null) {
          joinNext = true;
          break;
        }
      }
    }
    final form = joinPrev
        ? (joinNext ? GlyphForm.medial : GlyphForm.finalForm)
        : (joinNext ? GlyphForm.initial : GlyphForm.isolated);
    out.add(GlyphInWord(l, form));
    prev = l;
    brokeAfterPrev = false;
  }
  return out;
}

/// 문장 → 페르시아 문자 낱말들(문장부호 제외).
List<String> persianWords(String line) =>
    line.split(RegExp(r'[^؀-ۿ‌]+')).where((w) => w.isNotEmpty && w.runes.any((r) => letterOf(String.fromCharCode(r)) != null)).toList();
