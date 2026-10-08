import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    required this.onItemTap,
    this.selectedItem = 'Home',
    super.key,
  });

  final ValueChanged<String> onItemTap;
  final String selectedItem;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 76 + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEAEF))),
        boxShadow: [
          BoxShadow(
            color: Color(0x142B153A),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    label: 'Home',
                    asset: AppAssets.homeNavHome,
                    selected: selectedItem == 'Home',
                    onTap: () => onItemTap('Home'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    label: 'Aktivitas',
                    asset: AppAssets.homeNavActivity,
                    selected: selectedItem == 'Aktivitas',
                    onTap: () => onItemTap('Aktivitas'),
                  ),
                ),
                const Spacer(),
                Expanded(
                  child: _NavItem(
                    label: 'Promo',
                    asset: AppAssets.homeNavPromo,
                    selected: selectedItem == 'Promo',
                    onTap: () => onItemTap('Promo'),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    label: 'Akun',
                    asset: AppAssets.homeNavAccount,
                    selected: selectedItem == 'Akun',
                    onTap: () => onItemTap('Akun'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -24,
            child: Semantics(
              button: true,
              label: 'Gadai Online',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onItemTap('Gadai Online'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3D632B8D),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AppAssets.homeNavOnline,
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Gadai',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.asset,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final String asset;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFF918D95);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 32,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
