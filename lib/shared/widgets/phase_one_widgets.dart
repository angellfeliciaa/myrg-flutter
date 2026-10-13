import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class PhaseOneScaffold extends StatelessWidget {
  const PhaseOneScaffold({
    required this.title,
    required this.child,
    this.footer,
    this.headerPadding = const EdgeInsets.fromLTRB(20, 8, 24, 0),
    this.headerTitleSpacing = 12,
    this.backButtonPadding = const EdgeInsets.all(8),
    this.footerPadding = const EdgeInsets.fromLTRB(24, 12, 24, 20),
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry headerPadding;
  final double headerTitleSpacing;
  final EdgeInsetsGeometry backButtonPadding;
  final EdgeInsetsGeometry footerPadding;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAFAFA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: headerPadding,
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: IconButton(
                      padding: backButtonPadding,
                      tooltip: 'Kembali',
                      onPressed: () => Navigator.maybePop(context),
                      icon: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: .06),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/icons/phase1_back.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: headerTitleSpacing),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF242424),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
            if (footer != null) Padding(padding: footerPadding, child: footer),
          ],
        ),
      ),
    ),
  );
}

class PhaseOneCard extends StatelessWidget {
  const PhaseOneCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFEBEBEB), width: .8),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class PhaseOneButton extends StatelessWidget {
  const PhaseOneButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
      ),
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    ),
  );
}

Future<void> showPhaseTwoNotice(
  BuildContext context,
  String title,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          'Fitur ini masuk fase 2. Pada demo fase 1 belum ada transaksi, pembayaran, atau perubahan data yang dijalankan.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        PhaseOneButton(
          label: 'Mengerti',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  ),
);
