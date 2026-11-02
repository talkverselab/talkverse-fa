import 'package:flutter_test/flutter_test.dart';
import 'package:persian_universe/services/persian_script.dart';

void main() {
  test('hastam — 앞·가운데·가운데·끝', () {
    final p = splitWord('هستم');
    expect(p.map((g) => g.letter.ch).join(), 'هستم');
    expect(p.map((g) => g.form).toList(), [GlyphForm.initial, GlyphForm.medial, GlyphForm.medial, GlyphForm.finalForm]);
  });

  test('오른쪽만 이어지는 글자 뒤에서는 새로 시작', () {
    // سارا: س(앞) ا(끝) ر(홀로) ا(홀로)
    expect(splitWord('سارا').map((g) => g.form).toList(),
        [GlyphForm.initial, GlyphForm.finalForm, GlyphForm.isolated, GlyphForm.isolated]);
  });

  test('ZWNJ 에서 이음이 끊긴다', () {
    // می‌کنم: م(앞) ی(끝) | ک(앞) ن(가운데) م(끝)
    expect(splitWord('می‌کنم').map((g) => g.form).toList(),
        [GlyphForm.initial, GlyphForm.finalForm, GlyphForm.initial, GlyphForm.medial, GlyphForm.finalForm]);
  });

  test('분모 = 25×4 + 7×2', () => expect(totalGlyphForms, 114));

  test('문장 → 낱말', () => expect(persianWords('سلام! من مینجون هستم.'), ['سلام', 'من', 'مینجون', 'هستم']));
}
