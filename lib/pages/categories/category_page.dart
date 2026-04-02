import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/category_model.dart';
import 'package:inventory_app_project/pages/categories/add_category_dialog.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/order_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/pages/suppliers/suppliers_page.dart';
import 'package:inventory_app_project/services/category_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';

class CategoryPage extends StatefulWidget {
  final bool showBottomNav;

  const CategoryPage({super.key, this.showBottomNav = true});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  static const int _defaultStoreId = 1;

  final CategoryService _categoryService = CategoryService();

  int _selectedNavIndex = 1;
  bool _isLoading = true;
  String? _error;
  List<CategoryModel> _categories = const [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _categoryService.getCategoriesByStoreId(_defaultStoreId);
      if (!mounted) return;

      setState(() {
        _categories = categories;
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

  List<CategoryModel> get _visibleCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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

  Future<void> _addCategory() async {
    final result = await AddCategoryDialog.show(context);
    if (result != null && result.isNotEmpty) {
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = BottomNavigation.heightFor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
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
              else if (_visibleCategories.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildCategoryCard(_visibleCategories[i]),
                    childCount: _visibleCategories.length,
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
                    'Categories',
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
          hintText: 'Search categories...',
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
                    'Failed to load categories',
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
            Icons.category_outlined,
            size: 80,
            color: AppColors.borderColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Categories Yet',
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
              'Add your first category to get started',
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

  Widget _buildCategoryCard(CategoryModel category) {
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.category_outlined,
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
                    category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${category.id}',
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
      ),
    );
  }
}
