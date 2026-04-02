import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/order_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/pages/suppliers/add_supplier_dialog.dart';
import 'package:inventory_app_project/services/supplier_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';

class SuppliersPage extends StatefulWidget {
  final bool showBottomNav;

  const SuppliersPage({super.key, this.showBottomNav = true});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  static const int _defaultStoreId = 1;

  final SupplierService _supplierService = SupplierService();

  int _selectedNavIndex = 4;
  bool _isLoading = true;
  String? _error;
  List<SupplierModel> _suppliers = const [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suppliers = await _supplierService.getSuppliersByStoreId(_defaultStoreId);
      if (!mounted) return;

      setState(() {
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SupplierModel> get _visibleSuppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    return _suppliers
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.phone.contains(_searchQuery) ||
            s.address.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onBottomNavChanged(int index) {
    if (index == _selectedNavIndex) return;

    final Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
      case 1:
        page = const InventoryPage();
      case 2:
        page = const OrderPage();
      case 3:
        page = const StockMovementPage();
      case 4:
        page = const SuppliersPage();
      case 5:
        page = const SettingPage();
      default:
        return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _addSupplier() async {
    final result = await AddSupplierDialog.show(context);
    if (result != null) {
      _loadSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = BottomNavigation.heightFor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: _addSupplier,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearch()),
              if (_error != null) SliverToBoxAdapter(child: _buildError()),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_visibleSuppliers.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildSupplierCard(_visibleSuppliers[i]),
                    childCount: _visibleSuppliers.length,
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: navBarHeight + 16)),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigation(
              selectedIndex: _selectedNavIndex,
              onNavChanged: _onBottomNavChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, color: AppColors.textDark),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Suppliers',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search suppliers...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textMedium),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.errorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.errorText, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load suppliers',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.errorDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.errorDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: AppColors.borderColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Suppliers Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add your first supplier to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(SupplierModel supplier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.textMedium,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        supplier.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMedium),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    supplier.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            ),
            if (supplier.email != null && supplier.email!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16, color: AppColors.textMedium),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      supplier.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
