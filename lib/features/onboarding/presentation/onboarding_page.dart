import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/onboarding_item.dart';
import '../providers/onboarding_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _items = [
    OnboardingItem(
      title: AppStrings.onboardingFirstTitle,
      description: AppStrings.onboardingFirstDescription,
      illustration: AppAssets.onboardingSecure,
      indicator: AppAssets.onboardingIndicator1,
      illustrationWidth: 331,
    ),
    OnboardingItem(
      title: AppStrings.onboardingSecondTitle,
      description: AppStrings.onboardingSecondDescription,
      illustration: AppAssets.onboardingSimulation,
      indicator: AppAssets.onboardingIndicator2,
      illustrationWidth: 390,
    ),
    OnboardingItem(
      title: AppStrings.onboardingThirdTitle,
      description: AppStrings.onboardingThirdDescription,
      illustration: AppAssets.onboardingRewards,
      indicator: AppAssets.onboardingIndicator3,
      illustrationWidth: 387,
    ),
  ];

  late final PageController _pageController;
  var _currentPage = 0;
  var _isCompleting = false;

  bool get _isLastPage => _currentPage == _items.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  Future<void> _handlePrimaryAction() async {
    if (!_isLastPage) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      await ref.read(onboardingRepositoryProvider).completeOnboarding();
      if (mounted) context.go(AppRoutes.login);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan preferensi. Coba lagi.')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = math.min(
                  1.0,
                  math.min(
                    constraints.maxWidth / 402,
                    constraints.maxHeight / 812,
                  ),
                );

                return Column(
                  children: [
                    SizedBox(height: 24 * scale),
                    Image.asset(
                      AppAssets.brandLogo,
                      width: 111 * scale,
                      height: 57 * scale,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 14 * scale),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _items.length,
                        onPageChanged: (page) {
                          setState(() => _currentPage = page);
                        },
                        itemBuilder: (context, index) {
                          return _OnboardingSlide(
                            item: _items[index],
                            scale: scale,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20 * scale),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Image.asset(
                        _items[_currentPage].indicator,
                        key: ValueKey(_currentPage),
                        width: 56 * scale,
                        height: 8 * scale,
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox(height: 67 * scale),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                      child: AppButton(
                        label: _isLastPage
                            ? AppStrings.getStarted
                            : AppStrings.next,
                        isLoading: _isCompleting,
                        height: 48 * scale,
                        onPressed: _handlePrimaryAction,
                      ),
                    ),
                    SizedBox(height: 36 * scale),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.item, required this.scale});

  final OnboardingItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Image.asset(
              item.illustration,
              width: item.illustrationWidth * scale,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        SizedBox(height: 22 * scale),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * scale),
          child: Column(
            children: [
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: 24 * scale,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16 * scale),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 322 * scale),
                child: Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 16 * scale,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
