import 'package:flutter/material.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class BottomNavigation extends StatefulWidget {
  static const double _contentHeight = 37;
  static const double _topPadding = 10;
  static const double _bottomPadding = 8;

  final int selectedIndex;
  final Function(int) onNavChanged;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onNavChanged,
  });

  static double heightFor(BuildContext context) {
    return _contentHeight + _topPadding + _bottomPadding + MediaQuery.of(context).padding.bottom;
  }

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant BottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + BottomNavigation._bottomPadding,
        top: BottomNavigation._topPadding,
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            index: 0,
            isActive: _currentIndex == 0,
            onTap: () => _onTap(0),
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            index: 1,
            isActive: _currentIndex == 1,
            onTap: () => _onTap(1),
          ),
          _NavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Orders',
            index: 2,
            isActive: _currentIndex == 2,
            onTap: () => _onTap(2),
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'Stock Move',
            index: 3,
            isActive: _currentIndex == 3,
            onTap: () => _onTap(3),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            index: 4,
            isActive: _currentIndex == 4,
            onTap: () => _onTap(4),
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    widget.onNavChanged(index);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}