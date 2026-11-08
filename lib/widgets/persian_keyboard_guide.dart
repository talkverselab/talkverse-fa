import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';

/// 페르시아어 키보드 설치 안내(안드로이드 삼성·Gboard / 아이폰) — 아랍어앱 arabic_keyboard_guide 를 옮김(2026-11-08).
Future<void> showPersianKeyboardGuide(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      constraints: const BoxConstraints(maxWidth: 720),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _Guide(),
    );

class _Guide extends StatelessWidget {
  const _Guide();

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(children: [
                Text(tr('키보드 설정'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppColors.muted), onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(tr('기기 키보드에 페르시아어(فارسی) 입력기를 추가하면 앱 안에서 바로 페르시아 글자를 칠 수 있어요. 오른쪽에서 왼쪽으로 써요.'),
                  style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, height: 1.4)),
            ),
            const SizedBox(height: 8),
            TabBar(
              labelColor: AppColors.beni,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.beni,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: [Tab(text: tr('안드로이드')), Tab(text: tr('아이폰'))],
            ),
            Expanded(
              child: TabBarView(children: [
                ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset(context)), children: [
                  _Section(tr('방법 1 — 삼성 키보드에 페르시아어 추가'), [
                    tr('설정 앱 열기'),
                    tr('일반 → 삼성 키보드 설정'),
                    tr('언어 및 형식 → 입력 언어 관리 → + 버튼'),
                    tr('검색창에 「페르시아어」 또는 「فارسی」 → 다운로드'),
                    tr('목록에서 페르시아어를 켜기'),
                  ]),
                  const SizedBox(height: 16),
                  _Section(tr('방법 2 — Gboard(구글 키보드)'), [
                    tr('Play 스토어에서 Gboard 설치(있으면 건너뛰기)'),
                    tr('설정 → 일반 → 키보드 목록 및 기본값 → Gboard 켜기'),
                    tr('Gboard 설정 → 언어 → 키보드 추가 → 페르시아어(فارسی)'),
                    tr('입력 칸을 눌러 키보드를 연 뒤 🌐 지구본(또는 스페이스바 밀기)으로 페르시아어로 바꾸기'),
                  ]),
                  const SizedBox(height: 16),
                  const _Tips(),
                ]),
                ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset(context)), children: [
                  _Section(tr('아이폰 기본 키보드에 페르시아어 추가'), [
                    tr('설정 앱 열기'),
                    tr('일반 → 키보드 → 키보드'),
                    tr('새로운 키보드 추가 → 페르시아어(فارسی)'),
                    tr('완료'),
                  ]),
                  const SizedBox(height: 16),
                  _Section(tr('키보드 바꾸기'), [
                    tr('입력 칸을 눌러 키보드 열기'),
                    tr('스페이스바 왼쪽 🌐 지구본을 누르면 다음 키보드로'),
                    tr('길게 누르면 목록에서 바로 고르기'),
                  ]),
                  const SizedBox(height: 16),
                  const _Tips(),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) => Column(children: [
        _Tip(tr('오른쪽 → 왼쪽으로 입력돼요. 글자는 앞뒤 글자에 따라 모양이 바뀌니(홀로·앞·가운데·끝) 한 글자씩 확인하며 치세요.')),
        const SizedBox(height: 10),
        _Tip(tr('می‌ 같은 반칸(ZWNJ)은 띄어쓰기로 쳐도 정답이에요. 모음 부호와 아랍식 ي·ك 도 신경 쓰지 않아도 돼요.')),
        const SizedBox(height: 10),
        _Tip(tr('ی(예)와 ک(커프)는 페르시아 글자예요. 아랍어 키보드로 치면 모양이 달라질 수 있으니 페르시아어 키보드를 쓰세요.')),
      ]);
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> steps;
  const _Section(this.title, this.steps);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.beni, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                Expanded(child: Text(steps[i], style: const TextStyle(fontSize: 13.5, color: AppColors.sumi, height: 1.4))),
              ]),
            ),
        ]),
      );
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.beni.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(right: 8, top: 1), child: Text('💡', style: TextStyle(fontSize: 16))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.sumi, height: 1.4))),
        ]),
      );
}
