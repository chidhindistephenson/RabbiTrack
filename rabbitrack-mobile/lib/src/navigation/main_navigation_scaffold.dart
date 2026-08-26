import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/rabbit_icon.dart';
import '../theme/rabbitrack_colors.dart';

class MainNavigationScaffold extends StatelessWidget {
  const MainNavigationScaffold({
    required this.currentPath,
    required this.child,
    super.key,
  });

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFor(currentPath);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          compact ? 12 : 16,
          0,
          compact ? 12 : 16,
          12,
        ),
        child: Container(
          height: compact ? 72 : 76,
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
          decoration: BoxDecoration(
            color: RabbiTrackColors.forestGreen,
            borderRadius: BorderRadius.circular(compact ? 24 : 28),
            boxShadow: [
              BoxShadow(
                color: RabbiTrackColors.forestGreen.withValues(alpha: 0.24),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                key: const ValueKey('nav-home'),
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                selected: selectedIndex == 0,
                compact: compact,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                key: const ValueKey('nav-rabbits'),
                label: 'Rabbits',
                icon: Icons.manage_search,
                activeIcon: Icons.manage_search,
                iconBuilder: (color, size, selected) =>
                    RabbitIcon(color: color, size: size, filled: selected),
                selected: selectedIndex == 1,
                compact: compact,
                onTap: () => context.go('/rabbits'),
              ),
              _NavItem(
                key: const ValueKey('nav-breeding'),
                label: 'Breed',
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                selected: selectedIndex == 2,
                compact: compact,
                onTap: () => context.go('/breeding'),
              ),
              _NavItem(
                key: const ValueKey('nav-health'),
                label: 'Health',
                icon: Icons.medical_services_outlined,
                activeIcon: Icons.medical_services,
                selected: selectedIndex == 3,
                compact: compact,
                onTap: () => context.go('/health'),
              ),
              _NavItem(
                key: const ValueKey('nav-more'),
                label: 'More',
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                selected: selectedIndex == 4,
                compact: compact,
                onTap: () => context.go('/more'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _selectedIndexFor(String path) {
    if (path.startsWith('/rabbits') || path.startsWith('/litters')) {
      return 1;
    }
    if (path.startsWith('/breeding')) {
      return 2;
    }
    if (path.startsWith('/health')) {
      return 3;
    }
    if (path.startsWith('/more') ||
        path.startsWith('/tasks') ||
        path.startsWith('/sales') ||
        path.startsWith('/locations') ||
        path.startsWith('/weights')) {
      return 4;
    }

    return 0;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.compact,
    required this.onTap,
    this.iconBuilder,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  final Widget Function(Color color, double size, bool selected)? iconBuilder;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? RabbiTrackColors.forestGreen
        : RabbiTrackColors.mintGreen;
    final background = selected ? RabbiTrackColors.warmTan : Colors.transparent;

    return Expanded(
      flex: selected ? 2 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: compact ? 48 : 52,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(compact ? 22 : 24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              iconBuilder?.call(color, compact ? 22 : 24, selected) ??
                  Icon(
                    selected ? activeIcon : icon,
                    color: color,
                    size: compact ? 22 : 24,
                  ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: RabbiTrackColors.forestGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
