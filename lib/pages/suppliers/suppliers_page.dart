import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/orders/order_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/pages/suppliers/add_supplier_dialog.dart';
import 'package:inventory_app_project/pages/suppliers/edit_supplier_dialog.dart';
import 'package:inventory_app_project/services/supplier_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';
import 'package:inventory_app_project/widgets/page_loading_view.dart';

class SuppliersPage extends StatefulWidget {
  final bool showBottomNav;

  const SuppliersPage({super.key, this.showBottomNav = false});

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
      final suppliers = await _supplierService.getSuppliersByStoreId(
        _defaultStoreId,
      );
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
        .where(
          (s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.phone.contains(_searchQuery) ||
              s.address.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
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

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _addSupplier() async {
    final result = await AddSupplierDialog.show(context);
    if (result != null) {
      _loadSuppliers();
    }
  }

  Future<void> _editSupplier(SupplierModel supplier) async {
    final result = await EditSupplierDialog.show(
      context,
      initialName: supplier.name,
      initialPhone: supplier.phone,
      initialAddress: supplier.address,
      initialEmail: supplier.email,
    );
    if (result == null) return;

    try {
      await _supplierService.updateSupplier(
        SupplierModel(
          id: supplier.id,
          name: result.name,
          phone: result.phone,
          address: result.address,
          email: result.email,
          storeId: supplier.storeId,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier updated successfully.')),
      );
      await _loadSuppliers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update supplier: $e')));
    }
  }

  Future<void> _deleteSupplier(SupplierModel supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Supplier'),
          content: Text('Delete supplier "${supplier.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _supplierService.deleteSupplier(supplier.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier deleted successfully.')),
      );
      await _loadSuppliers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete supplier: $e')));
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
                  child: PageLoadingView(itemCount: 4, topPadding: 16),
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
          if (widget.showBottomNav)
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Color(0xFFC87F2E),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Suppliers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Store supplier overview',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
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
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.errorText,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load suppliers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.errorDark,
                    ),
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
              style: TextStyle(fontSize: 13, color: AppColors.textMedium),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editSupplier(supplier);
                    } else if (value == 'delete') {
                      _deleteSupplier(supplier);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  iconColor: AppColors.textMedium,
                  tooltip: 'Supplier options',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textMedium,
                ),
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
                  const Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: AppColors.textMedium,
                  ),
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
