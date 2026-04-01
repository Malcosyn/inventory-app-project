import 'package:flutter/material.dart';

class BottomNavColors {
  static const primary = Color(0xFFF2C287);
  static const borderColor = Color(0xFFE2E8F0);
  static const textLight = Color(0xFF94A3B8);
}

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavChanged;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onNavChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: BottomNavColors.borderColor)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 10,
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
            isActive: selectedIndex == 0,
            onTap: onNavChanged,
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            index: 1,
            isActive: selectedIndex == 1,
            onTap: onNavChanged,
          ),
          _NavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Orders',
            index: 2,
            isActive: selectedIndex == 2,
            onTap: onNavChanged,
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'Stock Move',
            index: 3,
            isActive: selectedIndex == 3,
            onTap: onNavChanged,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            index: 4,
            isActive: selectedIndex == 4,
            onTap: onNavChanged,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isActive;
  final Function(int) onTap;

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
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive
                  ? BottomNavColors.primary
                  : BottomNavColors.textLight,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? BottomNavColors.primary
                    : BottomNavColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
