import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../../core/network/backend_config.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/demo_session.dart';
import '../../home/presentation/widgets/home_bottom_navigation.dart';
import '../../membership/data/member_repository.dart';
import '../../membership/models/member_profile.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/member_information_card.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void _qr(MemberProfile member) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'QR Member',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          QrImageView(
            data: member.number,
            size: 220,
            backgroundColor: Colors.white,
          ),
          SelectableText(
            member.number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text('Tunjukkan QR ini kepada petugas cabang.'),
          const SizedBox(height: 20),
          PhaseOneButton(
            label: 'Tutup',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu akan kembali ke halaman masuk.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      if (BackendConfig.enabled) await AuthApi.logout();
      DemoSession.logout();
      if (!mounted) return;
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MemberProfile>(
    valueListenable: MemberRepository.profile,
    builder: (context, member, _) => ValueListenableBuilder<DemoContact>(
      valueListenable: DemoSession.contact,
      builder: (context, contact, _) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          bottomNavigationBar: HomeBottomNavigation(
            selectedItem: 'Akun',
            onItemTap: (item) {
              if (item == 'Home') context.go(AppRoutes.home);
              if (item == 'Aktivitas') context.go(AppRoutes.activity);
              if (item == 'Gadai Online') context.push(AppRoutes.pawn);
              if (item == 'Promo') showPhaseTwoNotice(context, 'Promo');
            },
          ),
          body: SingleChildScrollView(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/account_header.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Akun Saya',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kelola informasi dan pengaturan akun kamu',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        PhaseOneCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              ProfileAvatar(
                                name: member.name,
                                isFixture: contact.isFixture,
                                bytes: contact.avatarBytes,
                                url: contact.avatarUrl,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      contact.email.isEmpty
                                          ? 'Email belum ditambahkan'
                                          : contact.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      contact.phone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit profil',
                                onPressed: () =>
                                    context.push(AppRoutes.editAccount),
                                icon: Image.asset(
                                  'assets/icons/account_edit.png',
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -52,
                                right: -50,
                                child: Image.asset(
                                  'assets/images/account_member_glow.png',
                                  width: 184,
                                  height: 184,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (member.tier == MemberTier.gold &&
                                            member.membershipReady)
                                          Image.asset(
                                            'assets/icons/account_gold.png',
                                            width: 24,
                                            height: 24,
                                          )
                                        else
                                          const Icon(
                                            Icons.workspace_premium_outlined,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            member.membershipReady
                                                ? '${member.tier.label} Member'
                                                : 'Member belum aktif',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            child: Text(
                                              !member.membershipReady
                                                  ? 'Verifikasi'
                                                  : member.benefitsActive
                                                  ? 'Benefit aktif'
                                                  : 'Belum aktif',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Nomor Member',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member.number.isEmpty
                                          ? 'Menunggu verifikasi'
                                          : member.number,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/icons/account_points.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${NumberFormat.decimalPattern('id').format(member.points)} Poin ErGe',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: member.membershipReady
                                            ? member.progress
                                            : 0,
                                        minHeight: 6,
                                        color: AppColors.secondary,
                                        backgroundColor: Colors.white24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _heading('Informasi Member'),
                        const SizedBox(height: 16),
                        MemberInformationCard(member: member),
                        if (member.number.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => _qr(member),
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Tampilkan QR Member'),
                          ),
                        const SizedBox(height: 24),
                        _heading('Informasi Akun'),
                        const SizedBox(height: 16),
                        PhaseOneCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _menu(
                                'Keamanan Akun',
                                'account_security',
                                () => context.push(AppRoutes.security),
                              ),
                              const Divider(height: 1),
                              _menu(
                                'Rekening Saya',
                                'account_bank',
                                () => showPhaseTwoNotice(
                                  context,
                                  'Rekening Saya',
                                ),
                                phaseTwo: true,
                              ),
                              const Divider(height: 1),
                              _menu(
                                'Alamat Saya',
                                'account_address',
                                () =>
                                    showPhaseTwoNotice(context, 'Alamat Saya'),
                                phaseTwo: true,
                              ),
                              const Divider(height: 1),
                              _menu(
                                'Pusat Verifikasi Akun',
                                'account_verify',
                                () => showPhaseTwoNotice(
                                  context,
                                  'Pusat Verifikasi Akun',
                                ),
                                phaseTwo: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _heading('Lainnya'),
                        const SizedBox(height: 16),
                        PhaseOneCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _menu(
                                'Bantuan Raja Gadai',
                                'account_help',
                                () => context.push(AppRoutes.support),
                              ),
                              const Divider(height: 1),
                              _menu('Keluar Akun', 'account_exit', _logout),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          BackendConfig.enabled
                              ? 'Fitur berlabel Fase 2 belum aktif.'
                              : 'Demo FE • Data akun contoh. Fitur berlabel Fase 2 belum aktif.',
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _heading(String title) => Text(
    title,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
  Widget _menu(
    String title,
    String icon,
    VoidCallback onTap, {
    bool phaseTwo = false,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    onTap: onTap,
    leading: Image.asset('assets/icons/$icon.png', width: 24, height: 24),
    title: Text(title, style: const TextStyle(fontSize: 14)),
    subtitle: phaseTwo
        ? const Text(
            'Fase 2',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          )
        : null,
    trailing: Image.asset(
      'assets/icons/account_chevron.png',
      width: 16,
      height: 16,
    ),
  );
}
