import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/category_model.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/order_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/models/stock_movement_model.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/pages/app_shell_page.dart';
import 'package:inventory_app_project/pages/categories/add_category_dialog.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/orders/order_page.dart';
import 'package:inventory_app_project/pages/orders/add_order_dialog.dart';
import 'package:inventory_app_project/pages/products/add_product_dialog.dart';
import 'package:inventory_app_project/pages/products/edit_product_dialog.dart';
import 'package:inventory_app_project/pages/products/product_detail.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/pages/stock_movements/add_stock_movement_dialog.dart';
import 'package:inventory_app_project/pages/suppliers/add_supplier_dialog.dart';
import 'package:inventory_app_project/services/category_service.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/order_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/services/stock_movement_service.dart';
import 'package:inventory_app_project/services/supplier_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';
import 'package:inventory_app_project/widgets/page_loading_view.dart';
import 'package:inventory_app_project/widgets/quick_actions_section.dart';

class InventoryPage extends StatefulWidget {
  final bool showBottomNav;
  final InventoryQuickAction? initialQuickAction;
  final String? initialSearchQuery;
  final String? initialStockBarcode;
  final String? initialOpenProductBarcode;
  final int refreshTick;

  const InventoryPage({
    super.key,
    this.showBottomNav = true,
    this.initialQuickAction,
    this.initialSearchQuery,
    this.initialStockBarcode,
    this.initialOpenProductBarcode,
    this.refreshTick = 0,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const int _defaultStoreId = 1;

  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  final StockMovementService _stockMovementService = StockMovementService();
  final OrderService _orderService = OrderService();
  final CategoryService _categoryService = CategoryService();
  final SupplierService _supplierService = SupplierService();
  final ProductService _imageService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // RFC 4122 variant and version bits.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');

    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }

  bool _isLoading = true;
  String? _error;
  List<_InventoryItem> _items = const [];
  Map<int, CategoryModel> _categoriesById = const {};
  String _searchQuery = '';
  String _selectedFilter = 'All Categories';
  String _selectedStockStatus = 'All Status';
  bool _didRunInitialQuickAction = false;
  bool _didOpenInitialProductDetail = false;

  List<String> get _filters {
    final names = _categoriesById.values.map((c) => c.name).toList()..sort();
    return <String>['All Categories', ...names];
  }

  List<String> get _stockStatusFilters => const <String>[
    'All Status',
    'In Stock',
    'Low Stock',
    'Out of Stock',
  ];

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchQuery = initialQuery;
      _searchController.text = initialQuery;
    }
    _loadInventory();
  }

  @override
  void didUpdateWidget(covariant InventoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadInventory();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final errors = <String>[];
    List<ProductModel> products = const [];
    List<InventoryModel> inventories = const [];
    List<CategoryModel> categories = const [];

    try {
      products = await _productService.getProductsByStoreId(_defaultStoreId);
    } catch (e) {
      errors.add('products: $e');
    }

    try {
      inventories = await _inventoryService.getInventoriesByStoreId(
        _defaultStoreId,
      );
    } catch (e) {
      errors.add('inventories: $e');
    }

    try {
      categories = await _categoryService.getCategoriesByStoreId(
        _defaultStoreId,
      );
    } catch (e) {
      errors.add('categories: $e');
      debugPrint('Failed to fetch categories: $e');
    }

    if (!mounted) return;

    final inventoryByProductId = <String, InventoryModel>{
      for (final inventory in inventories) inventory.productId: inventory,
    };
    final categoriesById = <int, CategoryModel>{
      for (final category in categories) category.id: category,
    };

    final items = products
        .map(
          (product) => _InventoryItem(
            product: product,
            inventory: inventoryByProductId[product.id],
          ),
        )
        .toList();

    setState(() {
      _items = items;
      _categoriesById = categoriesById;
      _error = errors.isEmpty ? null : errors.first;
      if (_selectedFilter != 'All Categories' &&
          !_filters.contains(_selectedFilter)) {
        _selectedFilter = 'All Categories';
      }
      _isLoading = false;
    });

    if (!_didRunInitialQuickAction && widget.initialQuickAction != null) {
      _didRunInitialQuickAction = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _handleQuickAction(widget.initialQuickAction!);
      });
    }

    final initialOpenBarcode = widget.initialOpenProductBarcode?.trim() ?? '';
    if (!_didOpenInitialProductDetail && initialOpenBarcode.isNotEmpty) {
      _didOpenInitialProductDetail = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        _InventoryItem? matchedItem;
        for (final item in _items) {
          final barcode = item.product.barcode?.trim();
          if (barcode != null &&
              barcode.isNotEmpty &&
              barcode == initialOpenBarcode) {
            matchedItem = item;
            break;
          }
        }

        if (matchedItem == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Product with barcode "$initialOpenBarcode" not found.',
              ),
            ),
          );
          return;
        }

        await _navigateToProductDetail(matchedItem);
      });
    }
  }

  String _resolveCategoryName(ProductModel product) {
    final categoryId = product.categoryId;
    if (categoryId == null) return 'Uncategorized';
    return _categoriesById[categoryId]?.name ?? 'Category $categoryId';
  }

  Future<void> _deleteProduct(_InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Delete product "${item.product.name}"?'),
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
      if (item.inventory != null) {
        await _inventoryService.deleteInventory(item.inventory!.id);
      }
      await _productService.deleteProduct(item.product.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully.')),
      );
      await _loadInventory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete product: $e')));
    }
  }

  Future<void> _addItemToWarehouse() async {
    final result = await AddProductDialog.show(
      context,
      categoriesById: _categoriesById,
    );
    if (!mounted) return;

    if (!result.created) {
      if (result.message != null && result.message!.trim().isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message!)));
      }
      return;
    }

    await _loadInventory();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ?? 'Item added to warehouse successfully.',
        ),
      ),
    );
  }

  Future<void> _addCategoryQuick() async {
    final name = await AddCategoryDialog.show(context);
    if (!mounted || name == null) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required.')),
      );
      return;
    }

    try {
      final existing = await _categoryService.getCategoriesByStoreId(
        _defaultStoreId,
      );
      final maxId = existing.isEmpty
          ? 0
          : existing.map((c) => c.id).reduce((a, b) => a > b ? a : b);
      final category = CategoryModel(
        id: maxId + 1,
        storeId: _defaultStoreId,
        name: name,
      );
      await _categoryService.createCategory(category);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully.')),
      );
      await _loadInventory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add category: $e')));
    }
  }

  Future<void> _addSupplierQuick() async {
    final input = await AddSupplierDialog.show(context);
    if (!mounted || input == null) return;

    if (input.name.isEmpty || input.phone.isEmpty || input.address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, phone, and address are required.')),
      );
      return;
    }

    try {
      final supplier = SupplierModel(
        id: _generateUuidV4(),
        name: input.name,
        phone: input.phone,
        address: input.address,
        email: input.email,
        storeId: _defaultStoreId,
      );
      await _supplierService.createSupplier(supplier);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier added successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add supplier: $e')));
    }
  }

  Future<void> _pickProductForStockChange({
    required bool isStockIn,
    String? preferredBarcode,
  }) async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products in inventory yet.')),
      );
      return;
    }

    final normalizedBarcode = preferredBarcode?.trim();
    if (normalizedBarcode != null && normalizedBarcode.isNotEmpty) {
      _InventoryItem? matched;
      for (final item in _items) {
        final barcode = item.product.barcode?.trim();
        if (barcode != null &&
            barcode.isNotEmpty &&
            barcode == normalizedBarcode) {
          matched = item;
          break;
        }
      }

      if (matched != null) {
        await _changeStock(item: matched, isStockIn: isStockIn);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Barcode "$normalizedBarcode" not found. Please select product manually.',
          ),
        ),
      );
    }

    final picked = await showModalBottomSheet<_InventoryItem>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Text(
                    isStockIn
                        ? 'Select Product for Stock In'
                        : 'Select Product for Stock Out',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    title: Text(item.product.name),
                    subtitle: Text(
                      '${_resolveCategoryName(item.product)} • ${item.stockQuantity} unit',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || picked == null) return;
    await _changeStock(item: picked, isStockIn: isStockIn);
  }

  Future<void> _addOrderQuick() async {
    final products = _items.map((e) => e.product).toList();
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available for order.')),
      );
      return;
    }

    final input = await AddOrderDialog.show(context, products: products);
    if (!mounted || input == null) return;

    try {
      final order = OrderModel(
        id: _generateUuidV4(),
        productId: input.productId,
        totalPrice: input.totalPrice,
        totalItem: input.totalItem,
        status: input.status,
        unitType: input.unitType,
        storeId: _defaultStoreId,
      );

      await _orderService.createOrder(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order added successfully.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShellPage(initialIndex: 2)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add order: $e')));
    }
  }

  Future<void> _handleQuickAction(InventoryQuickAction action) async {
    // Let the previous modal route fully settle before showing another route/dialog.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 220));

    switch (action) {
      case InventoryQuickAction.addItem:
        await _addItemToWarehouse();
        break;
      case InventoryQuickAction.addSupplier:
        await _addSupplierQuick();
        break;
      case InventoryQuickAction.addCategory:
        await _addCategoryQuick();
        break;
      case InventoryQuickAction.addOrder:
        await _addOrderQuick();
        break;
      case InventoryQuickAction.stockIn:
        await _pickProductForStockChange(
          isStockIn: true,
          preferredBarcode: widget.initialStockBarcode,
        );
        break;
      case InventoryQuickAction.stockOut:
        await _pickProductForStockChange(
          isStockIn: false,
          preferredBarcode: widget.initialStockBarcode,
        );
        break;
    }
  }

  Future<ProductDetailUpdate?> _editProduct(_InventoryItem item) async {
    final isUpdated = await EditProductDialog.show(
      context,
      product: item.product,
      inventory: item.inventory,
      productService: _productService,
      inventoryService: _inventoryService,
      categoriesById: _categoriesById,
      onUpdated: _loadInventory,
    );

    if (!isUpdated || !mounted) {
      return null;
    }

    _InventoryItem? updatedItem;
    for (final candidate in _items) {
      if (candidate.product.id == item.product.id) {
        updatedItem = candidate;
        break;
      }
    }
    if (updatedItem == null) {
      return null;
    }

    dynamic supplier;
    dynamic category;
    if (updatedItem.product.supplierId != null) {
      try {
        supplier = await _supplierService.getSupplierById(
          updatedItem.product.supplierId!,
        );
      } catch (e) {
        debugPrint('Failed to fetch updated supplier: $e');
      }
    }

    if (updatedItem.product.categoryId != null) {
      final categoryId = updatedItem.product.categoryId!;
      category = _categoriesById[categoryId];
      if (category == null) {
        try {
          category = await _categoryService.getCategoryById(categoryId);
        } catch (e) {
          debugPrint('Failed to fetch updated category by id $categoryId: $e');
        }
      }
    }

    if (!mounted) {
      return null;
    }

    return ProductDetailUpdate(
      product: updatedItem.product,
      inventory: updatedItem.inventory,
      category: category,
      categoryNameOverride: _resolveCategoryName(updatedItem.product),
      supplier: supplier,
    );
  }

  Future<void> _changeStock({
    required _InventoryItem item,
    required bool isStockIn,
  }) async {
    final inventory = item.inventory;
    if (inventory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory data not found.')),
      );
      return;
    }

    final input = await AddStockMovementDialog.show(
      context,
      isStockIn: isStockIn,
    );
    if (!mounted) return;
    if (input == null) return;

    final newStock = isStockIn
        ? inventory.stockQuantity + input.quantity
        : inventory.stockQuantity - input.quantity;

    if (newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock cannot be negative.')),
      );
      return;
    }

    final updatedInventory = InventoryModel(
      id: inventory.id,
      productId: inventory.productId,
      costPrice: inventory.costPrice,
      sellingPrice: inventory.sellingPrice,
      stockQuantity: newStock,
      lowStockThreshold: inventory.lowStockThreshold,
      updatedAt: DateTime.now(),
      storeId: inventory.storeId,
    );

    try {
      await _inventoryService.updateInventory(updatedInventory);
      await _stockMovementService.createStockMovementEntry(
        productId: inventory.productId,
        type: isStockIn ? 'IN' : 'OUT',
        quantity: input.quantity,
        stockAfter: newStock,
        reason: input.reason,
        note: input.note.isNotEmpty
            ? input.note
            : (isStockIn
                  ? 'Manual stock in from product detail'
                  : 'Manual stock out from product detail'),
        storeId: inventory.storeId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isStockIn
                ? 'Stock added successfully.'
                : 'Stock reduced successfully.',
          ),
        ),
      );
      await _loadInventory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update stock: $e')));
    }
  }

  Future<void> _navigateToProductDetail(_InventoryItem item) async {
    try {
      dynamic supplier;
      dynamic category;
      List<StockMovementModel> recentMovements = [];

      if (item.product.supplierId != null) {
        try {
          supplier = await _supplierService.getSupplierById(
            item.product.supplierId!,
          );
        } catch (e) {
          debugPrint('Failed to fetch supplier: $e');
        }
      }

      if (item.product.categoryId != null) {
        final categoryId = item.product.categoryId!;
        category = _categoriesById[categoryId];
        if (category == null) {
          try {
            category = await _categoryService.getCategoryById(categoryId);
          } catch (e) {
            debugPrint('Failed to fetch category by id $categoryId: $e');
          }
        }
      }

      try {
        recentMovements = await _stockMovementService
            .getStockMovementsByProductId(item.product.id);
      } catch (e) {
        debugPrint('Failed to fetch movements: $e');
      }

      if (!mounted) return;

      final resolvedCategoryName = _resolveCategoryName(item.product);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            product: item.product,
            inventory: item.inventory,
            category: category,
            categoryNameOverride: resolvedCategoryName,
            supplier: supplier,
            recentMovements: recentMovements,
            onEdit: () => _editProduct(item),
            onDelete: () => _deleteProduct(item),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error navigating to product detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _onBottomNavChanged(BuildContext context, int index) {
    if (index == 1) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AppShellPage(initialIndex: index)),
    );
  }

  List<_InventoryItem> get _visibleItems {
    final query = _searchQuery.trim().toLowerCase();
    return _items.where((item) {
      final nameMatches =
          query.isEmpty ||
          item.product.name.toLowerCase().contains(query) ||
          (item.product.barcode?.toLowerCase().contains(query) ?? false);
      if (!nameMatches) return false;

      final stockStatusMatches = switch (_selectedStockStatus) {
        'All Status' => true,
        'In Stock' => item.stockStatus == _StockStatus.inStock,
        'Low Stock' => item.stockStatus == _StockStatus.low,
        'Out of Stock' => item.stockStatus == _StockStatus.out,
        _ => true,
      };
      if (!stockStatusMatches) return false;

      if (_selectedFilter == 'All Categories') {
        return true;
      }

      return _resolveCategoryName(item.product) == _selectedFilter;
    }).toList();
  }

  Color _statusBg(_StockStatus status) => switch (status) {
    _StockStatus.inStock => const Color(0xFFFFF7ED),
    _StockStatus.low => const Color(0xFFFFEDD5),
    _StockStatus.out => const Color(0xFFFEE2E2),
  };

  Color _statusText(_StockStatus status) => switch (status) {
    _StockStatus.inStock => const Color(0xFFB45309),
    _StockStatus.low => const Color(0xFFEA580C),
    _StockStatus.out => const Color(0xFFDC2626),
  };

  String _statusLabel(_StockStatus status) => switch (status) {
    _StockStatus.inStock => 'In Stock',
    _StockStatus.low => 'Low Stock',
    _StockStatus.out => 'Out of Stock',
  };

  // ── Header (without add button) ─────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFFDFAF6),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFFC87F2E),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Main Warehouse',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search products, barcode...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((filter) {
                final selected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF92400E)
                          : AppColors.textMedium,
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFF59E0B)
                          : AppColors.borderColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedStockStatus,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
            ),
            items: _stockStatusFilters
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedStockStatus = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const PageLoadingView(itemCount: 5, topPadding: 16);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
              const SizedBox(height: 8),
              const Text(
                'Failed to load inventory data',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.errorDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadInventory,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final visibleItems = _visibleItems;

    if (visibleItems.isEmpty) {
      return const Center(
        child: Text(
          'No inventory data.',
          style: TextStyle(color: AppColors.textMedium),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: visibleItems.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'All Products (${visibleItems.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMedium,
                letterSpacing: 1,
              ),
            ),
          );
        }

        final item = visibleItems[index - 1];
        final status = item.stockStatus;
        final imageUrl = _imageService.resolveImageUrl(item.product.imageUrl);
        final proxyUrl = imageUrl != null
            ? _imageService.proxyImageUrl(imageUrl)
            : null;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _navigateToProductDetail(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFF1F5F9),
                    child: imageUrl != null
                        ? _InventoryProductImage(
                            key: ValueKey('${item.product.id}_${imageUrl}'),
                            primaryUrl: imageUrl,
                            fallbackUrl: proxyUrl,
                            productName: item.product.name,
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.textLight,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(status),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _statusText(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_resolveCategoryName(item.product)} • ${item.stockQuantity} units',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Rp${item.sellingPrice}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC87F2E),
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editProduct(item);
                              } else if (value == 'stock_in') {
                                _changeStock(item: item, isStockIn: true);
                              } else if (value == 'stock_out') {
                                _changeStock(item: item, isStockIn: false);
                              } else if (value == 'delete') {
                                _deleteProduct(item);
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
                                value: 'stock_in',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Stock In'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'stock_out',
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_upward_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Stock Out'),
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
                                      style: TextStyle(
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            icon: const Icon(Icons.more_horiz_rounded),
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            iconColor: AppColors.textMedium,
                            tooltip: 'Product options',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // FAB bottom offset: selalu di atas bottom nav bar
    final navBarHeight = BottomNavigation.heightFor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),

          // ── Bottom Navigation ─────────────────────────────────────────
          if (widget.showBottomNav)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavigation(
                selectedIndex: 1,
                onNavChanged: (index) => _onBottomNavChanged(context, index),
              ),
            ),

          // ── FAB: Quick Actions (+) ───────────────────────────────────
          InventoryQuickActionsSection(
            bottomOffset: navBarHeight + 12,
            onActionSelected: _handleQuickAction,
          ),
        ],
      ),
    );
  }
}

// ── Supporting types (unchanged) ─────────────────────────────────────────────

class _InventoryItem {
  final ProductModel product;
  final InventoryModel? inventory;
  const _InventoryItem({required this.product, required this.inventory});

  int get stockQuantity => inventory?.stockQuantity ?? 0;
  int get sellingPrice => inventory?.sellingPrice ?? 0;

  _StockStatus get stockStatus {
    if (stockQuantity <= 0) return _StockStatus.out;
    final threshold = inventory?.lowStockThreshold ?? 5;
    if (stockQuantity <= threshold) return _StockStatus.low;
    return _StockStatus.inStock;
  }
}

enum _StockStatus { inStock, low, out }

class _InventoryProductImage extends StatefulWidget {
  final String primaryUrl;
  final String? fallbackUrl;
  final String productName;

  const _InventoryProductImage({
    super.key,
    required this.primaryUrl,
    required this.fallbackUrl,
    required this.productName,
  });

  @override
  State<_InventoryProductImage> createState() => _InventoryProductImageState();
}

class _InventoryProductImageState extends State<_InventoryProductImage> {
  late String _activeUrl;
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.primaryUrl;
  }

  @override
  void didUpdateWidget(covariant _InventoryProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryUrl != widget.primaryUrl ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _usingFallback = false;
      _activeUrl = widget.primaryUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _activeUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (!_usingFallback && widget.fallbackUrl != null) {
          debugPrint(
            'Image load failed for ${widget.productName}: ${widget.primaryUrl} | $error. Trying proxy ${widget.fallbackUrl}',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _usingFallback = true;
              _activeUrl = widget.fallbackUrl!;
            });
          });
          return const SizedBox.shrink();
        }
        debugPrint(
          'Image load failed for ${widget.productName}: $_activeUrl | $error',
        );
        return const Icon(
          Icons.inventory_2_outlined,
          color: AppColors.textLight,
        );
      },
    );
  }
}
