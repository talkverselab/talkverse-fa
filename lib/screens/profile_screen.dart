import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'login_screen.dart';

import '../core/theme.dart';
import '../widgets/spanish_decor.dart';
import '../core/l10n.dart';
import '../core/pane.dart';
import '../data/account.dart';
import '../data/entitlement.dart';
import '../data/purchase.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('프로필 · 설정'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.rojoDeep, AppColors.rojo],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gualda, width: 1.5),
            ),
            child: Row(
              children: [
                const TileBadge(text: 'FA', size: 60, color: AppColors.farsi),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('학습자'),
                        style: TextStyle(
                          color: AppColors.cal,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        tr('1일차 · 입문 (A1)'),
                        style: TextStyle(
                          color: AppColors.gualdaBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(tr('계정')),
          const SizedBox(height: 8),
          const _AccountSection(),
          const SizedBox(height: 18),
          // 학습자 프로필(일본어앱 learner_prefs) — 이름 → 회화의 {name} 자리, 성별 → 학습자 목소리(새 회화 구조부터)
          _SectionTitle(tr('학습자')),
          const SizedBox(height: 8),
          const _LearnerSection(),
          const SizedBox(height: 18),
          _SectionTitle(tr('설정')),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: KoReadingPrefs.show,
            builder: (context, on, _) => _SettingsGroup(items: [
              _SettingItem(
                  icon: Icons.language,
                  title: tr('언어 / Language'),
                  subtitle: '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                  onTap: AppLangPrefs.next),
              _SettingItem(
                  icon: Icons.text_fields,
                  title: tr('한글독음'),
                  subtitle: on ? tr('표시 — 탭하면 숨김') : tr('미표시(기본) — 힘들어도 보지 않고 익혀보세요'),
                  onTap: () => KoReadingToggleAction.toggle(context)),
            ]),
          ),
          const SizedBox(height: 16),
          _SectionTitle(tr('정보')),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(
                icon: Icons.landscape_outlined,
                title: tr('앱 소개'),
                subtitle: tr('절벽구간 — 이 앱이 단어를 나누는 기준'),
                onTap: () => openPane(context, (_) => const AboutScreen())),
            _SettingItem(icon: Icons.info_outline, title: tr('앱 버전'), subtitle: '0.1.0 · alpha'),
            _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('페르시아어유니버스 · 2026')),
          ]),
          const SizedBox(height: 20),
          const BandDivider(),
          const SizedBox(height: 12),
          const Center(child: SolMark(size: 28)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'دانستن توانستن است',
              style: TextStyle(
                color: AppColors.tintaLight,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: AppColors.tinta,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gualda.withValues(alpha: 0.5)),
      ),
      child: Material(type: MaterialType.transparency, child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.rojo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.rojo, width: 0.8),
                ),
                child: Icon(items[i].icon, color: AppColors.rojo, size: 18),
              ),
              title: Text(items[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
              subtitle: Text(items[i].subtitle,
                  style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.rojo, size: 18),
            ),
            if (i < items.length - 1)
              Container(height: 0.5, color: AppColors.gualda.withValues(alpha: 0.3)),
          ],
        ],
      )),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  _SettingItem({required this.icon, required this.title, required this.subtitle, this.onTap});
}

/// Talkverse 계정 + 평생 이용권(한자 앱 me_screen 계정 칸 이식, 2026-11-02).
/// 로그인 전: 로그인 타일 / 후: 이름·이메일·로그아웃·계정 삭제(스토어 심사 요구). 아래에 이용권·구매 복원.
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: Account.user,
        builder: (context, u, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.cal,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gualda.withValues(alpha: 0.5)),
          ),
          child: Material(type: MaterialType.transparency, child: Column(children: [
            if (u == null)
              ListTile(
                leading: const Icon(Icons.account_circle_outlined, color: AppColors.rojo),
                title: Text(tr('로그인'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
                subtitle: Text(tr('Talkverse 계정 하나로 모든 앱에서 (선택)'), style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.rojo, size: 18),
                onTap: () => LoginScreen.open(context),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.account_circle, color: AppColors.rojo),
                title: Text((u['display_name'] as String?) ?? tr('이름 없음'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
                subtitle: u['email'] == null ? null : Text(u['email'] as String, style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.tintaLight),
                title: Text(tr('로그아웃')),
                onTap: () => Account.signOut(),
              ),
              ListTile(
                leading: const Icon(Icons.person_remove_outlined, color: AppColors.tintaLight),
                title: Text(tr('계정 삭제')),
                onTap: () => _confirmDelete(context),
              ),
            ],
            Container(height: 0.5, color: AppColors.gualda.withValues(alpha: 0.3)),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.rojo),
              title: Text(tr('평생 이용권'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
              subtitle: Text(Entitlement.premium ? tr('이용 중') : tr('한 번 결제 · 구독 아님'), style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.rojo, size: 18),
              onTap: () => Entitlement.showPaywall(context),
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: AppColors.rojo),
              title: Text(tr('구매 복원'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
              subtitle: ValueListenableBuilder<String?>(
                valueListenable: Purchase.status,
                builder: (_, st, _) => Text(
                    switch (st) {
                      'pending' => tr('확인 중…'),
                      'restored' => tr('복원했습니다'),
                      'nothing' => tr('복원할 구매가 없습니다'),
                      _ => tr('이전에 산 평생 이용권을 이 기기에서 다시 엽니다'),
                    },
                    style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
              ),
              onTap: () => Purchase.restore(),
            ),
          ])),
        ),
      );

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('계정을 삭제할까요?')),
        content: Text(tr('Talkverse 계정과 이름·이메일·로그인 정보가 지워지고 모든 기기에서 로그아웃됩니다. 이 기기의 학습 기록은 그대로 남습니다. 되돌릴 수 없습니다.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('취소'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('삭제'), style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Account.deleteAccount();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('삭제하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.'))));
      }
    }
  }
}

/// 학습자 이름·성별(일본어앱 profile_screen 학습자 프로필 이식, 2026-11-02).
class _LearnerSection extends StatelessWidget {
  const _LearnerSection();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: LearnerPrefs.name,
        builder: (context, name, _) => ValueListenableBuilder<String>(
          valueListenable: LearnerPrefs.gender,
          builder: (context, gender, _) => Container(
            decoration: BoxDecoration(
              color: AppColors.cal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gualda.withValues(alpha: 0.5)),
            ),
            child: Material(type: MaterialType.transparency, child: Column(children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined, color: AppColors.rojo),
                title: Text(tr('이름'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
                subtitle: Text(name.isNotEmpty ? trf('{0} — 회화 속 「나」로 나와요', [name]) : tr('없음 — 회화에서 「○○」로 보여요'),
                    style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
                trailing: const Icon(Icons.edit_outlined, color: AppColors.rojo, size: 18),
                onTap: () => _editName(context),
              ),
              Container(height: 0.5, color: AppColors.gualda.withValues(alpha: 0.3)),
              ListTile(
                leading: Icon(gender == 'female' ? Icons.face_3 : Icons.face, color: AppColors.rojo),
                title: Text(tr('성별'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
                subtitle: Text(gender == 'female' ? tr('여성 — 탭하면 남성') : tr('남성 — 탭하면 여성'),
                    style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
                onTap: () => LearnerPrefs.setGender(gender == 'female' ? 'male' : 'female'),
              ),
            ])),
          ),
        ),
      );

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: LearnerPrefs.name.value);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('이름')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: tr('회화에서 불릴 이름'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('취소'))),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('저장'))),
        ],
      ),
    );
    if (v != null) await LearnerPrefs.setName(v);
  }
}
