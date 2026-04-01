import 'package:flutter/material.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/order_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';

class StockMovementPage extends StatelessWidget {
  const StockMovementPage({super.key});

  void _onBottomNavChanged(BuildContext context, int index) {
    final Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
      case 1:
        page = const InventoryPage();
      case 2:
        page = const OrderPage();
      case 3:
        return;
      case 4:
        page = const SettingPage();
      default:
        return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          const Center(
            child: Text(
              'Stock Movement Page',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigation(
              selectedIndex: 3,
              onNavChanged: (index) => _onBottomNavChanged(context, index),
            ),
          ),
        ],
      ),
    );
  }
}
