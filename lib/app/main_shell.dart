import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/widgets/ad_banner.dart';
import 'theme.dart';

/// Shell com Bottom Navigation (5 abas) estilizado conforme o design system.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (
      label: 'Início',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    (
      label: 'Manutenções',
      icon: Icons.precision_manufacturing_outlined,
      activeIcon: Icons.precision_manufacturing_rounded,
    ),
    (
      label: 'Lembretes',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_active_rounded,
    ),
    (
      label: 'Gastos',
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
    ),
    (
      label: 'Mais',
      icon: Icons.more_horiz_rounded,
      activeIcon: Icons.more_horiz_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBanner(),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.96),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    for (var i = 0; i < _destinations.length; i++) ...[
                      Expanded(
                        child: _NavItem(
                          label: _destinations[i].label,
                          icon: _destinations[i].icon,
                          activeIcon: _destinations[i].activeIcon,
                          isSelected: selectedIndex == i,
                          onTap: () => navigationShell.goBranch(
                            i,
                            initialLocation: i == selectedIndex,
                          ),
                        ),
                      ),
                    ],
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
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textMutedColor;

    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
