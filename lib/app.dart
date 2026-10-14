import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Shows messages that do not belong to one page (e.g. "logged in on another phone").
final appMessenger = GlobalKey<ScaffoldMessengerState>();

class MyRgApp extends StatelessWidget {
  const MyRgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: AppRouter.router,
      scaffoldMessengerKey: appMessenger,
      builder: (context, child) => _PhoneWidth(child: child!),
    );
  }
}

/// The screens are designed for a phone. On a tablet they would stretch over the whole width
/// (wide gaps, very long lines), so there the app keeps a phone-like width in the middle of the
/// screen. Dialogs, sheets and snack bars live inside it too. Phones are not affected.
class _PhoneWidth extends StatelessWidget {
  const _PhoneWidth({required this.child});
  final Widget child;

  static const maxWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxWidth) return child;
    return ColoredBox(
      color: AppColors.surfaceSoft,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            data: media.copyWith(size: Size(maxWidth, media.size.height)),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
