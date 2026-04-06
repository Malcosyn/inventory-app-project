import 'package:flutter/material.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/orders/order_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';
import 'package:inventory_app_project/widgets/quick_actions_section.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    this.initialIndex = 0,
    this.initialInventoryQuickAction,
  });

  final int initialIndex;
  final InventoryQuickAction? initialInventoryQuickAction;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  late int _selectedIndex;
  int _homeRefreshTick = 0;
  int _inventoryRefreshTick = 0;
  int _orderRefreshTick = 0;
  int _stockMovementRefreshTick = 0;
  int _settingsRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 4);
  }

  @override
  void didUpdateWidget(covariant AppShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = widget.initialIndex.clamp(0, 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(showBottomNav: false, refreshTick: _homeRefreshTick),
      InventoryPage(
        showBottomNav: false,
        initialQuickAction: widget.initialInventoryQuickAction,
        refreshTick: _inventoryRefreshTick,
      ),
      OrderPage(showBottomNav: false, refreshTick: _orderRefreshTick),
      StockMovementPage(
        showBottomNav: false,
        refreshTick: _stockMovementRefreshTick,
      ),
      SettingPage(showBottomNav: false, refreshTick: _settingsRefreshTick),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavigation(
              selectedIndex: _selectedIndex,
              onNavChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 0) {
                    _homeRefreshTick++;
                  } else if (index == 1) {
                    _inventoryRefreshTick++;
                  } else if (index == 2) {
                    _orderRefreshTick++;
                  } else if (index == 3) {
                    _stockMovementRefreshTick++;
                  } else if (index == 4) {
                    _settingsRefreshTick++;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
