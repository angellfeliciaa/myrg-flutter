import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/backend_config.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/demo_session.dart';
import 'pin_prompt.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  /// Hapus Akun (Play Store / App Store requirement): warning, then PIN (DELETE /me).
  Future<void> _deleteAccount(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun MyRG?'),
        content: const Text(
          'Profil, poin, voucher, notifikasi, dan riwayat Banding di MyRG akan dihapus dan tidak bisa dikembalikan.\n\n'
          'Gadai kamu di Raja Gadai tetap ada dan tetap harus diselesaikan di cabang.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Lanjut Hapus'),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final deleted = await askPin(
      context,
      title: 'Konfirmasi Hapus Akun',
      message: 'Masukkan PIN untuk menghapus akun secara permanen.',
      actionLabel: 'Hapus Akun',
      destructive: true,
      onPin: AuthApi.deleteAccount,
    );
    if (!deleted || !context.mounted) return;
    DemoSession.logout();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Akun berhasil dihapus.')));
    context.go(AppRoutes.login);
  }

  Widget _tile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: PhaseOneCard(
      onTap: onTap,
      child: Row(
        children: [
          Image.asset('assets/icons/$icon.png', width: 24, height: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/icons/account_chevron.png',
            width: 16,
            height: 16,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PhaseOneScaffold(
    title: 'Keamanan Akun',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Akun aman, transaksi nyaman',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kelola keamanan akun MyRG kamu.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        _tile(
          icon: 'account_security',
          title: 'Ganti Password',
          subtitle: BackendConfig.enabled
              ? 'Perbarui password untuk masuk'
              : 'Perbarui password akun demo',
          onTap: () => context.push(AppRoutes.changePassword),
        ),
        if (BackendConfig.enabled) ...[
          _tile(
            icon: 'account_security',
            title: 'Ganti PIN',
            subtitle: 'PIN untuk membuka aplikasi',
            onTap: () => context.push(AppRoutes.changePin),
          ),
          _tile(
            icon: 'account_exit',
            title: 'Hapus Akun',
            subtitle: 'Hapus akun MyRG secara permanen',
            color: AppColors.error,
            onTap: () => _deleteAccount(context),
          ),
        ] else ...[
          const SizedBox(height: 4),
          const Text(
            'Pratinjau FE. Pengaturan keamanan belum mengubah akun Raja Gadai yang sebenarnya.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );
}
