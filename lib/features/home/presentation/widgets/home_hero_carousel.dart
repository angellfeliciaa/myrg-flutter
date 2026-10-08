import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/carousel_auto_play.dart';

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({this.autoPlayEnabled = true, super.key});
  final bool autoPlayEnabled;

  // The image fills exported from Figma are both 1448 × 1086 (4:3).
  static const aspectRatio = 4 / 3;
  static const banners = [
    (asset: AppAssets.homeHeroInstant, label: 'Pencairan dana instan'),
    (asset: AppAssets.homeHeroGoods, label: 'Gadai elektronik dan kendaraan'),
  ];

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AspectRatio(
      aspectRatio: HomeHeroCarousel.aspectRatio,
      child: CarouselAutoPlay(
        controller: _controller,
        page: _page,
        itemCount: HomeHeroCarousel.banners.length,
        enabled: widget.autoPlayEnabled,
        child: ColoredBox(
          color: AppColors.primary,
          child: Stack(
            children: [
              PageView.builder(
                key: const ValueKey('home-hero-pages'),
                controller: _controller,
                itemCount: HomeHeroCarousel.banners.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final banner = HomeHeroCarousel.banners[index];
                  return Image.asset(
                    banner.asset,
                    fit: BoxFit.contain,
                    semanticLabel:
                        'Banner ${index + 1} dari ${HomeHeroCarousel.banners.length}: ${banner.label}',
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                top: constraints.maxWidth * (219 / 403) - 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (
                      int index = 0;
                      index < HomeHeroCarousel.banners.length;
                      index++
                    )
                      Semantics(
                        button: true,
                        selected: index == _page,
                        label: 'Tampilkan banner ${index + 1}',
                        child: Tooltip(
                          message: 'Tampilkan banner ${index + 1}',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _controller.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            ),
                            child: SizedBox(
                              width: 20,
                              height: 28,
                              child: Center(
                                child: AnimatedContainer(
                                  key: ValueKey('home-hero-dot-$index'),
                                  duration: const Duration(milliseconds: 200),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _page
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: .45),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
