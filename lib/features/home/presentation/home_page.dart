import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../activity/data/activity_repository.dart';
import '../../membership/data/member_repository.dart';
import '../../membership/models/member_profile.dart';
import 'widgets/home_bottom_navigation.dart';
import 'widgets/home_hero_carousel.dart';
import 'widgets/home_membership_card.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_transaction_card.dart';
import '../../../shared/widgets/carousel_auto_play.dart';
import '../../../core/network/backend_config.dart';
import '../../activity/data/activity_api.dart';
import '../../membership/data/member_api.dart';
import '../../../core/network/api_exception.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Home "Transaksi Berjalan": backend data when connected, the demo cards otherwise.
  List<Widget> get _transactionCards {
    if (!BackendConfig.enabled) {
      return [
        HomeTransactionCard(
          dueLabel: 'Segera jatuh tempo dalam 3 hari',
          productName: 'Apple iPhone 13 | 128 GB | Purple',
          dueDate: '31 Juli 2026',
          amount: 'Rp 5.700.000',
          onManage: () => context.push(
            AppRoutes.activityDetail,
            extra: ActivityRepository.ongoing.first,
          ),
        ),
        HomeTransactionCard(
          dueLabel: 'Jatuh tempo dalam 12 hari',
          productName: 'Emas Antam | 5 gram',
          productIcon: Icons.diamond_outlined,
          dueDate: '9 Agustus 2026',
          amount: 'Rp 4.250.000',
          onManage: () => context.push(
            AppRoutes.activityDetail,
            extra: ActivityRepository.goldPawn,
          ),
        ),
      ];
    }
    if (ActivityRepository.loading) {
      final failed = ActivityApi.loadError.value != null;
      return [
        HomeTransactionCard(
          dueLabel: failed
              ? 'Transaksi belum bisa dimuat'
              : 'Memuat transaksi...',
          productName: failed ? 'Tarik layar ke bawah untuk mencoba lagi' : '',
          dueDate: '-',
          amount: '-',
          onManage: () => context.go(AppRoutes.activity),
        ),
      ];
    }
    final ongoing = ActivityRepository.ongoing;
    if (ongoing.isEmpty) {
      return [
        HomeTransactionCard(
          dueLabel: 'Belum ada transaksi berjalan',
          productName: 'Ajukan gadai pertamamu di MyRG',
          dueDate: '-',
          amount: '-',
          onManage: () => context.push(AppRoutes.pawn),
        ),
      ];
    }
    return [
      for (final tx in ongoing.take(5))
        HomeTransactionCard(
          dueLabel: tx.attentionLabel ?? 'Gadai aktif',
          productName: [
            tx.title,
            if (tx.subtitle != null) tx.subtitle!,
          ].join(' | '),
          dueDate: tx.dueDate ?? '-',
          amount: tx.amount,
          onManage: () => context.push(AppRoutes.activityDetail, extra: tx),
        ),
    ];
  }

  void _onActivityData() {
    if (mounted) setState(() {});
  }

  final _scrollController = ScrollController();
  final _transactionController = PageController(viewportFraction: 0.9);
  int _transactionPage = 0;
  final _transactionViewportKey = GlobalKey();
  bool _bannerVisible = true;
  bool _transactionsVisible = false;

  @override
  void initState() {
    super.initState();
    ActivityApi.ongoing.addListener(_onActivityData);
    ActivityApi.loadError.addListener(_onActivityData);
    if (BackendConfig.enabled) {
      ActivityApi.load().catchError((_) {});
      MemberApi.refreshCard();
    }
    _scrollController.addListener(_updateCarouselVisibility);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateCarouselVisibility(),
    );
  }

  void _updateCarouselVisibility() {
    if (!mounted || !_scrollController.hasClients) return;
    final media = MediaQuery.of(context);
    final bannerVisible =
        _scrollController.offset < media.size.width * (231.92 / 403);
    final box = _transactionViewportKey.currentContext?.findRenderObject();
    var transactionsVisible = false;
    if (box is RenderBox && box.attached && box.hasSize) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final viewport = Rect.fromLTRB(
        0,
        media.padding.top,
        media.size.width,
        media.size.height - 76 - media.padding.bottom,
      );
      transactionsVisible = rect.intersect(viewport).height >= rect.height * .5;
    }
    if (_bannerVisible != bannerVisible ||
        _transactionsVisible != transactionsVisible) {
      setState(() {
        _bannerVisible = bannerVisible;
        _transactionsVisible = transactionsVisible;
      });
    }
  }

  @override
  void dispose() {
    ActivityApi.ongoing.removeListener(_onActivityData);
    ActivityApi.loadError.removeListener(_onActivityData);
    _scrollController.removeListener(_updateCarouselVisibility);
    _scrollController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!BackendConfig.enabled) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return;
    }
    try {
      await Future.wait([
        ActivityApi.load(force: true),
        MemberApi.refreshCard(force: true),
      ]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature akan segera tersedia.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 86),
        ),
      );
  }

  void _handleNavigation(String item) {
    if (item == 'Home') {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (item == 'Aktivitas') {
      context.go(AppRoutes.activity);
      return;
    }
    if (item == 'Cek Pinjaman') {
      context.push(AppRoutes.simulation);
      return;
    }
    if (item == 'Cabang') {
      context.push(AppRoutes.branches);
      return;
    }
    if (item == 'Gadai Online' || item == 'Gadai') {
      context.push(AppRoutes.pawn);
      return;
    }
    if (item == 'Akun' || item == 'Member') {
      context.go(AppRoutes.account);
      return;
    }
    _showComingSoon(item);
  }

  @override
  Widget build(BuildContext context) {
    final transactionCards = _transactionCards; // built once per frame
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroHeight = screenWidth / HomeHeroCarousel.aspectRatio;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final transactionHeight = 176.0 + (textScale - 1).clamp(0.0, 2.0) * 110;
    // Figma frame 403 × 874: banner 302, card begins at y=231.92.
    final membershipTop = screenWidth * (231.92 / 403);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.background,
        bottomNavigationBar: HomeBottomNavigation(onItemTap: _handleNavigation),
        body: RefreshIndicator(
          color: AppColors.primary,
          edgeOffset: MediaQuery.paddingOf(context).top,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: heroHeight,
                      child: HomeHeroCarousel(autoPlayEnabled: _bannerVisible),
                    ),
                    Positioned(
                      top: screenWidth * (284.29 / 403),
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, membershipTop, 24, 24),
                      child: ValueListenableBuilder<MemberProfile>(
                        valueListenable: MemberRepository.profile,
                        builder: (context, member, _) => HomeMembershipCard(
                          member: member,
                          onBalanceTap: () => _showComingSoon('Saldo RG'),
                          onPointsTap: () => context.go(AppRoutes.account),
                          onVoucherTap: () => _showComingSoon('Voucher Saya'),
                        ),
                      ),
                    ),
                    Positioned(
                      top: screenWidth * (70 / 403) - 5,
                      right: 18,
                      child: IconButton(
                        tooltip: 'Notifikasi',
                        onPressed: () => context.push(AppRoutes.notifications),
                        icon: Image.asset(
                          AppAssets.homeNotification,
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    HomeQuickActions(onActionTap: _handleNavigation),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Transaksi Berjalan',
                      subtitle: 'Pantau status gadaimu dengan mudah',
                      actionLabel: 'Lihat Semua',
                      onAction: () => context.go(AppRoutes.activity),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: SizedBox(
                    key: _transactionViewportKey,
                    height: transactionHeight,
                    child: CarouselAutoPlay(
                      controller: _transactionController,
                      page: _transactionPage,
                      itemCount: transactionCards.length,
                      interval: const Duration(seconds: 7),
                      enabled: _transactionsVisible,
                      child: PageView(
                        controller: _transactionController,
                        padEnds: false,
                        onPageChanged: (value) =>
                            setState(() => _transactionPage = value),
                        children: transactionCards,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 0, 0),
                  child: _PageDots(
                    current: _transactionPage,
                    count: transactionCards.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 104),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionHeader(
                      title: 'Promo buat kamu',
                      subtitle: 'Deal pilihan yang lagi worth it',
                      actionLabel: 'Lihat Semua',
                      onAction: () => _showComingSoon('Daftar promo'),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEDEAEF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A2C183A),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Semantics(
                        button: true,
                        label: 'Promo gratis biaya keterlambatan',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: () => _showComingSoon('Detail promo'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 2.63,
                              child: Image.asset(
                                AppAssets.homePromo,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _PageDots(current: 0, count: 1, circular: true),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.primarySoft,
            minimumSize: const Size(86, 44),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const StadiumBorder(),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.current,
    required this.count,
    this.circular = false,
  });

  final int current;
  final int count;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(count, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: circular
              ? 8
              : active
              ? 20
              : 6,
          height: circular ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFD1C8D7),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
