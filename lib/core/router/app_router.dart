import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../network/backend_config.dart';

import '../../features/activity/data/activity_repository.dart';
import '../../features/activity/models/activity_transaction.dart';
import '../../features/activity/presentation/activity_detail_route.dart';
import '../../features/activity/presentation/activity_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/pin_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/confirm_pin_page.dart';
import '../../features/auth/presentation/create_pin_page.dart';
import '../../features/auth/presentation/otp_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/onboarding/presentation/splash_page.dart';
import '../../features/profile/presentation/account_page.dart';
import '../../features/activity/presentation/notifications_page.dart';
import '../../features/pawn/presentation/pawn_page.dart';
import '../../features/pawn/models/pawn_submission.dart';
import '../../features/support/presentation/support_page.dart';
import '../../features/simulation/presentation/simulation_page.dart';
import '../../features/simulation/models/valuation.dart';
import '../../features/branch/presentation/branch_page.dart';
import '../../features/branch/presentation/branch_detail_page.dart';
import '../../features/branch/models/branch.dart';
import '../../features/branch/data/branch_repository.dart';
import '../../features/profile/presentation/security_page.dart';
import '../../features/profile/presentation/change_password_page.dart';
import '../../features/profile/presentation/change_pin_page.dart';
import '../../features/profile/presentation/edit_profile_page.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const createPin = '/create-pin';
  static const confirmPin = '/confirm-pin';
  static const pin = '/pin';
  static const home = '/home';
  static const activity = '/activity';
  static const activityDetail = '/activity/detail';
  static const account = '/account';
  static const pawn = '/pawn';
  static const notifications = '/notifications';
  static const support = '/support';
  static const simulation = '/simulation';
  static const branches = '/branches';
  static const branchDetail = '/branches/detail';
  static const security = '/account/security';
  static const changePassword = '/account/security/password';
  static const changePin = '/account/security/pin';
  static const editProfile = '/account/profile';
}

abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => OtpPage(
          phoneNumber: state.extra is String ? state.extra! as String : '',
        ),
      ),
      GoRoute(
        path: AppRoutes.createPin,
        builder: (context, state) => const CreatePinPage(),
      ),
      GoRoute(
        path: AppRoutes.confirmPin,
        builder: (context, state) => ConfirmPinPage(
          createdPin: state.extra is String ? state.extra! as String : '',
        ),
      ),
      GoRoute(
        path: AppRoutes.pin,
        builder: (context, state) => const PinPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.activity,
        builder: (context, state) => const ActivityPage(),
      ),
      GoRoute(path: AppRoutes.account, builder: (_, _) => const AccountPage()),
      GoRoute(
        path: AppRoutes.security,
        builder: (_, _) => const SecurityPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, _) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.changePin,
        builder: (_, _) => const ChangePinPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, _) => const EditProfilePage(),
      ),
      GoRoute(path: AppRoutes.branches, builder: (_, _) => const BranchPage()),
      GoRoute(
        path: AppRoutes.branchDetail,
        builder: (_, state) => BranchDetailPage(
          branch: state.extra is Branch
              ? state.extra as Branch
              : BranchRepository.fixtures.first,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.simulation,
        builder: (_, _) => const SimulationPage(),
      ),
      GoRoute(
        path: AppRoutes.pawn,
        builder: (_, state) => PawnPage(
          estimate: state.extra is ValuationResult
              ? state.extra as ValuationResult
              : null,
          submission: state.extra is PawnSubmission
              ? state.extra as PawnSubmission
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (_, state) => SupportPage(
          transactionNumber: state.extra is String ? state.extra as String : '',
        ),
      ),
      GoRoute(
        path: AppRoutes.activityDetail,
        redirect: (_, state) =>
            state.extra is ActivityTransaction || !BackendConfig.enabled
            ? null
            : AppRoutes.activity,
        builder: (context, state) => ActivityDetailRoute(
          transaction: state.extra is ActivityTransaction
              ? state.extra! as ActivityTransaction
              : ActivityRepository.history.first,
        ),
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundPage(),
  );
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Halaman tidak ditemukan')));
  }
}
