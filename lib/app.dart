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

/// The screens are designed for a phone in portrait. Phones and tablets held upright (up to
/// about 840 dp wide) use the whole width, and the screens adapt (fixed-height menus, more photo
/// columns). Only a very wide screen, such as a tablet held sideways, gets a centred column so the
/// banner and cards do not stretch out of shape. Dialogs, sheets and snack bars live inside it too.
class _PhoneWidth extends StatelessWidget {
  const _PhoneWidth({required this.child});
  final Widget child;

  static const fullWidthUpTo = 840.0;
  static const maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= fullWidthUpTo) return child;
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
