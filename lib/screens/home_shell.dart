import 'dart:ui';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/ad_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_slot.dart';
import 'discover_screen.dart';
import 'explore_screen.dart';
import 'library_screen.dart';
import 'stats_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Only the tabs the user has actually opened get mounted. Building every
  // tab up front made them all fire their initial API calls at once,
  // competing with Discover's over Jikan's single shared, throttled
  // connection and slowing down the very first screen the user sees.
  final Set<int> _visited = {0};

  static const _screens = [
    DiscoverScreen(),
    ExploreScreen(),
    LibraryScreen(),
    StatsScreen(),
  ];

  static const _items = [
    (_NavData(Icons.style_rounded, 'nav_discover')),
    (_NavData(Icons.explore_rounded, 'nav_explore')),
    (_NavData(Icons.collections_bookmark_rounded, 'nav_library')),
    (_NavData(Icons.insights_rounded, 'nav_stats')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _screens.length; i++)
            _visited.contains(i) ? _screens[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavBar(
            index: _index,
            items: _items,
            onTap: (i) {
              AdGate.onTap();
              setState(() {
                _index = i;
                _visited.add(i);
              });
            },
          ),
          const AdBannerSlot(slot: 'home'),
        ],
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;
  const _NavData(this.icon, this.label);
}

class _NavBar extends StatelessWidget {
  final int index;
  final List<_NavData> items;
  final ValueChanged<int> onTap;
  const _NavBar(
      {required this.index, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < items.length; i++)
                  _NavItem(
                    data: items[i],
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavData data;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem(
      {required this.data, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12),
        height: 46,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brand : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(data.icon,
                color: selected ? Colors.white : AppColors.textLow, size: 24),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).t(data.label),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
