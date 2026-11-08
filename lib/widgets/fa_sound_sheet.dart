import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/persian_phonetics.dart';
import '../services/persian_script.dart';
import '../services/tts_service.dart';

/// 글자 탭 → 발음 시트(일본어앱 kana_sound_sheet 와 같은 틀, 2026-11-08).
/// 열리면 1초 뒤 자동 재생 · 다시 듣기 · IPA · 위치별 모양 · 소리 나는 곳(그림 번호) · 모음 위치(한국어 모음과 비교) · 한국어와 비교.
Future<void> showFaSoundSheet(BuildContext context, FaSound s, Color color) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      constraints: const BoxConstraints(maxWidth: 720),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FaSoundSheet(s: s, color: color),
    );

/// 조음 위치 그림(임시 — 출시 전 Grok 그림으로 교체, 사용자 지시 2026-11-08)의 번호.
const _spots = {
  'ب': [1, 2], 'پ': [1, 2], 'م': [1, 2], 'ف': [2, 3], 'و': [2, 3],
  'ت': [3, 4], 'د': [3, 4], 'ط': [3, 4], 'ث': [4], 'س': [4], 'ص': [4], 'ز': [4], 'ذ': [4], 'ض': [4], 'ظ': [4],
  'ن': [4], 'ل': [4], 'ر': [4], 'ش': [5], 'ژ': [5], 'چ': [5], 'ج': [5], 'ی': [7],
  'ک': [8], 'گ': [8], 'خ': [8], 'ق': [9], 'غ': [9], 'ه': [11], 'ح': [11], 'ع': [11], 'ء': [11],
};
const _spotKo = {1: '입술 바깥', 2: '입술 안쪽', 3: '윗니', 4: '윗잇몸', 5: '잇몸 뒤', 7: '센입천장', 8: '여린입천장', 9: '목젖', 11: '성대(목청)'};

class _FaSoundSheet extends StatefulWidget {
  final FaSound s;
  final Color color;
  const _FaSoundSheet({required this.s, required this.color});

  @override
  State<_FaSoundSheet> createState() => _FaSoundSheetState();
}

class _FaSoundSheetState extends State<_FaSoundSheet> {
  Timer? _auto;
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), _play); // 1초 뒤 자동 재생
  }

  void _play() => TtsService.instance.speak(widget.s.say);

  @override
  void dispose() {
    _auto?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s, color = widget.color;
    final letter = letterOf(s.ch.characters.first);
    final vc = s.isVowel ? faVowelCharts[s.roman] : null;
    final spots = _spots[s.ch];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Text(s.ch, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s.name}  ·  ${s.nameKo}', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                Text(s.roman, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                Text('IPA [${s.ipa}]', style: const TextStyle(fontSize: 14, color: AppColors.sumiLight)),
              ]),
            ),
            IconButton(
              iconSize: 44,
              color: color,
              tooltip: tr('다시 듣기'),
              icon: const Icon(Icons.play_circle_fill),
              onPressed: _play,
            ),
          ]),
          if (letter != null && !s.isVowel) ...[
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final f in letter.forms)
                  Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
                    child: Column(children: [
                      Text(letter.shape(f), textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                      Text(tr(f.ko), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ]),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          _section(tr('👄 소리 나는 곳 · 입 모양'),
              spots == null ? s.place : '${s.place}\n\n${tr('그림 번호')}: ${spots.map((n) => '$n ${tr(_spotKo[n] ?? '')}').join(' · ')}', color),
          if (vc != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.35))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('📍 모음 위치 — 페르시아어 vs 한국어'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 10),
                FaVowelChartView(data: vc, color: color),
              ]),
            ),
          ],
          if (spots != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _showChart = !_showChart),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(_showChart ? Icons.expand_less : Icons.expand_more, size: 18, color: color),
                  Text(tr('조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ]),
              ),
            ),
            if (_showChart) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Image.asset('assets/images/ipa/places_of_articulation.png', fit: BoxFit.contain)),
              ),
            ],
          ],
          const SizedBox(height: 14),
          _section(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [s.korSim, s.korDiff]), color),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => TtsService.instance.speak(s.example.split('=').first.split('·').first.trim()),
            child: _section(tr('예'), s.example, color, trailing: Icon(Icons.volume_up, size: 18, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body, Color color, {Widget? trailing}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color))),
            ?trailing,
          ]),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)),
        ]),
      );
}

/// IPA 모음 사다리꼴 한 장에 페르시아어 모음(강조색)과 이웃 한국어 모음(남색)을 함께 찍는다.
class FaVowelChartView extends StatelessWidget {
  final FaVowelChart data;
  final Color color;
  const FaVowelChartView({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 1.45,
          child: Container(
            decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line)),
            padding: const EdgeInsets.fromLTRB(30, 22, 16, 14),
            child: CustomPaint(painter: _Trapezoid(data, color), size: Size.infinite),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [_dot(color, tr('페르시아어')), const SizedBox(width: 12), _dot(AppColors.tinta, tr('한국어'))]),
        const SizedBox(height: 4),
        Text(data.note, style: const TextStyle(fontSize: 11.5, color: AppColors.sumi, height: 1.45)),
      ]);

  Widget _dot(Color c, String label) => Row(children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      ]);
}

class _Trapezoid extends CustomPainter {
  final FaVowelChart data;
  final Color color;
  _Trapezoid(this.data, this.color);

  Offset _map(double x, double y, Size s) {
    final left = 0.38 * s.width * y;
    return Offset(left + (s.width - left) * x, y * s.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.sumiLight.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
        Path()
          ..moveTo(_map(0, 0, size).dx, 0)
          ..lineTo(_map(1, 0, size).dx, 0)
          ..lineTo(_map(1, 1, size).dx, size.height)
          ..lineTo(_map(0, 1, size).dx, size.height)
          ..close(),
        grid);
    for (final y in [1 / 3, 2 / 3]) {
      canvas.drawLine(_map(0, y, size), _map(1, y, size), grid);
    }
    canvas.drawLine(_map(0.5, 0, size), _map(0.5, 1, size), grid);
    _text(canvas, tr('앞'), Offset(_map(0, 0, size).dx - 2, -18), 9, AppColors.sumiLight);
    _text(canvas, tr('뒤'), Offset(size.width - 14, -18), 9, AppColors.sumiLight);
    _text(canvas, tr('높'), Offset(-24, -4), 9, AppColors.sumiLight);
    _text(canvas, tr('낮'), Offset(-24, size.height - 10), 9, AppColors.sumiLight);
    final fa = _map(data.fa.x, data.fa.y, size);
    for (final k in data.ko) {
      final p = _map(k.x, k.y, size);
      canvas.drawLine(fa, p, Paint()
        ..color = AppColors.sumiLight.withValues(alpha: 0.5)
        ..strokeWidth = 1);
      canvas.drawCircle(p, 5, Paint()..color = AppColors.tinta);
      _text(canvas, '${k.label} [${k.ipa}]', p + const Offset(-14, 7), 10, AppColors.tinta);
    }
    canvas.drawCircle(fa, 8, Paint()..color = color);
    canvas.drawCircle(fa, 8, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    _text(canvas, '${data.fa.label} [${data.fa.ipa}]', fa + const Offset(-18, -26), 12, color, bold: true);
  }

  void _text(Canvas c, String s, Offset o, double size, Color col, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: col, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _Trapezoid old) => old.data != data;
}
