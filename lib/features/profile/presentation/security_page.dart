import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/phase_one_widgets.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});
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
        PhaseOneCard(
          onTap: () => context.push(AppRoutes.changePassword),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/account_security.png',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ganti Password',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Perbarui password akun demo',
                      style: TextStyle(
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
        const SizedBox(height: 20),
        const Text(
          'Pratinjau FE. Pengaturan keamanan belum mengubah akun Raja Gadai yang sebenarnya.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
