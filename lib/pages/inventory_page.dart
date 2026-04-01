import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/category_model.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/models/stock_movement_model.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/order_page.dart';
import 'package:inventory_app_project/pages/products/product_detail.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/services/category_service.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/services/stock_movement_service.dart';
import 'package:inventory_app_project/services/supplier_service.dart';
import 'package:inventory_app_project/usecases/products/product_image_url_usecase.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const int _defaultStoreId = 1;

  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  final StockMovementService _stockMovementService = StockMovementService();
  final CategoryService _categoryService = CategoryService();
  final SupplierService _supplierService = SupplierService();
  final ProductImageUrlUseCase _imageUrlUseCase = const ProductImageUrlUseCase();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<_InventoryItem> _items = const [];
  Map<int, CategoryModel> _categoriesById = const {};
  String _searchQuery = '';
  String _selectedFilter = 'All Categories';

  static const List<String> _filters = <String>[
    'All Categories',
    'Low Stock',
    'Out of Stock',
    'In Stock',
  ];

  @override
  void initState() {
    super.initState();
    _loadInventory();
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

    try {
      final result = await Future.wait([
        _productService.getProductsByStoreId(_defaultStoreId),
        _inventoryService.getInventoriesByStoreId(_defaultStoreId),
      ]);

      if (!mounted) return;

      final products = result[0] as List<ProductModel>;
      final inventories = result[1] as List<InventoryModel>;

      final categoryIds = products
          .map((p) => p.categoryId)
          .whereType<int>()
          .toSet()
          .toList();

      List<CategoryModel> categories = const [];
      try {
        categories = await _categoryService.getCategoriesByIds(categoryIds);
      } catch (e) {
        // Category is optional for list rendering; do not fail inventory page.
        debugPrint('Failed to fetch categories: $e');
      }
      final inventoryByProductId = <String, InventoryModel>{
        for (final inventory in inventories) inventory.productId: inventory,
      };
      final categoriesById = <int, CategoryModel>{
        for (final category in categories) category.id: category,
      };

      final items = products
          .map((product) => _InventoryItem(
                product: product,
                inventory: inventoryByProductId[product.id],
              ))
          .toList();

      setState(() {
        _items = items;
        _categoriesById = categoriesById;
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

  String _resolveCategoryName(ProductModel product) {
    final categoryId = product.categoryId;
    if (categoryId == null) {
      return 'Uncategorized';
    }

    return _categoriesById[categoryId]?.name ?? 'Category $categoryId';
  }
  Future<void> _deleteProduct(_InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Hapus produk "${item.product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Delete inventory row first to avoid FK violations, then product.
      if (item.inventory != null) {
        await _inventoryService.deleteInventory(item.inventory!.id);
      }
      await _productService.deleteProduct(item.product.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil dihapus.')),
      );
      await _loadInventory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }

  Future<void> _addItemToWarehouse() async {
    final nameController = TextEditingController();
    final barcodeController = TextEditingController();
    final imageUrlController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final thresholdController = TextEditingController(text: '5');

    int? selectedCategoryId;
    String? selectedSupplierId;

    final categories = _categoriesById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    List<SupplierModel> suppliers = const [];
    try {
      suppliers = await _supplierService.getSuppliersByStoreId(_defaultStoreId);
    } catch (e) {
      debugPrint('Failed to fetch suppliers for create form: $e');
    }

    if (!mounted) return;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Item Gudang'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedCategoryId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Tanpa kategori'),
                          ),
                          ...categories.map(
                            (category) => DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedCategoryId = value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedSupplierId,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tanpa supplier'),
                          ),
                          ...suppliers.map(
                            (supplier) => DropdownMenuItem<String?>(
                              value: supplier.id,
                              child: Text(supplier.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedSupplierId = value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: costPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Modal *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: sellingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Awal *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Low Stock Threshold *',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );

    final name = nameController.text.trim();
    final barcode = barcodeController.text.trim();
    final imageUrl = imageUrlController.text.trim();
    final costPrice = int.tryParse(costPriceController.text.trim());
    final sellingPrice = int.tryParse(sellingPriceController.text.trim());
    final initialStock = int.tryParse(stockController.text.trim());
    final threshold = int.tryParse(thresholdController.text.trim());

    nameController.dispose();
    barcodeController.dispose();
    imageUrlController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    stockController.dispose();
    thresholdController.dispose();

    if (!mounted || shouldCreate != true) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk wajib diisi.')),
      );
      return;
    }

    if (costPrice == null ||
        sellingPrice == null ||
        initialStock == null ||
        threshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field angka wajib diisi dengan benar.')),
      );
      return;
    }

    if (costPrice < 0 || sellingPrice < 0 || initialStock < 0 || threshold < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai angka tidak boleh negatif.')),
      );
      return;
    }

    try {
      final productId = await _productService.createProductEntry(
        storeId: _defaultStoreId,
        name: name,
        categoryId: selectedCategoryId,
        supplierId: selectedSupplierId,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        barcode: barcode.isEmpty ? null : barcode,
      );

      await _inventoryService.createInventoryEntry(
        productId: productId,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        stockQuantity: initialStock,
        lowStockThreshold: threshold,
        storeId: _defaultStoreId,
      );

      if (initialStock > 0) {
        await _stockMovementService.createStockMovementEntry(
          productId: productId,
          type: 'IN',
          quantity: initialStock,
          stockAfter: initialStock,
          note: 'Initial stock saat tambah item',
          storeId: _defaultStoreId,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item berhasil ditambahkan ke gudang.')),
      );
      await _loadInventory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambah item: $e')),
      );
    }
  }

  Future<void> _editProduct(_InventoryItem item) async {
    final nameController = TextEditingController(text: item.product.name);
    final sellingController = TextEditingController(
      text: item.inventory?.sellingPrice.toString() ?? '',
    );
    final thresholdController = TextEditingController(
      text: item.inventory?.lowStockThreshold.toString() ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sellingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Selling Price'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Threshold',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    final updatedName = nameController.text.trim();
    final parsedSelling = int.tryParse(sellingController.text.trim());
    final parsedThreshold = int.tryParse(thresholdController.text.trim());

    nameController.dispose();
    sellingController.dispose();
    thresholdController.dispose();

    if (!mounted || shouldSave != true) return;

    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk tidak boleh kosong.')),
      );
      return;
    }

    if (item.inventory != null) {
      if (parsedSelling == null || parsedSelling < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harga jual tidak valid.')),
        );
        return;
      }

      if (parsedThreshold == null || parsedThreshold < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Threshold tidak valid.')),
        );
        return;
      }
    }

    final updatedProduct = ProductModel(
      id: item.product.id,
      storeId: item.product.storeId,
      categoryId: item.product.categoryId,
      supplierId: item.product.supplierId,
      imageUrl: item.product.imageUrl,
      name: updatedName,
      barcode: item.product.barcode,
      createdAt: item.product.createdAt,
    );

    try {
      await _productService.updateProduct(updatedProduct);

      if (item.inventory != null) {
        final inv = item.inventory!;
        final updatedInventory = InventoryModel(
          id: inv.id,
          productId: inv.productId,
          costPrice: inv.costPrice,
          sellingPrice: parsedSelling!,
          stockQuantity: inv.stockQuantity,
          lowStockThreshold: parsedThreshold!,
          updatedAt: DateTime.now(),
          storeId: inv.storeId,
        );
        await _inventoryService.updateInventory(updatedInventory);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil diperbarui.')),
      );
      await _loadInventory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update produk: $e')),
      );
    }
  }

  Future<void> _changeStock({
    required _InventoryItem item,
    required bool isStockIn,
  }) async {
    final inventory = item.inventory;
    if (inventory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data inventory tidak ditemukan.')),
      );
      return;
    }

    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    final input = await showDialog<_StockChangeInput>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isStockIn ? 'Stock In' : 'Stock Out'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Masukkan jumlah',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    hintText: 'Contoh: Retur supplier / Penjualan offline',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(qtyController.text.trim());
                if (parsed == null || parsed <= 0) {
                  return;
                }
                Navigator.of(context).pop(
                  _StockChangeInput(
                    quantity: parsed,
                    reason: reasonController.text.trim(),
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    qtyController.dispose();
    reasonController.dispose();
    if (!mounted) return;
    if (input == null) return;

    final newStock = isStockIn
        ? inventory.stockQuantity + input.quantity
        : inventory.stockQuantity - input.quantity;

    if (newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock tidak boleh minus.')),
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
        note: input.reason.isNotEmpty
            ? input.reason
            : (isStockIn
                ? 'Manual stock in from product detail'
                : 'Manual stock out from product detail'),
        storeId: inventory.storeId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isStockIn ? 'Stock berhasil ditambah.' : 'Stock berhasil dikurangi.',
          ),
        ),
      );
      await _loadInventory();
      
      // Pop back to InventoryPage to show updated data
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update stock: $e')),
      );
    }
  }

  Future<void> _navigateToProductDetail(_InventoryItem item) async {
    try {
      dynamic supplier;
      dynamic category;
      List<StockMovementModel> recentMovements = [];

      // Fetch supplier if ID exists
      if (item.product.supplierId != null) {
        try {
          supplier = await _supplierService.getSupplierById(item.product.supplierId!);
        } catch (e) {
          debugPrint('Failed to fetch supplier: $e');
        }
      }

      // Fetch category if ID exists
      if (item.product.categoryId != null) {
        final categoryId = item.product.categoryId!;
        category = _categoriesById[categoryId];

        // Fallback: query single category if it is not present in cache.
        if (category == null) {
          try {
            category = await _categoryService.getCategoryById(categoryId);
          } catch (e) {
            debugPrint('Failed to fetch category by id $categoryId: $e');
          }
        }
      }

      // Fetch recent movements
      try {
        recentMovements = await _stockMovementService.getStockMovementsByProductId(item.product.id);
      } catch (e) {
        debugPrint('Failed to fetch movements: $e');
      }

      if (!mounted) return;

      // Navigate with complete data
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
            onStockIn: () => _changeStock(item: item, isStockIn: true),
            onStockOut: () => _changeStock(item: item, isStockIn: false),
            onDelete: () => _deleteProduct(item),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error navigating to product detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _onBottomNavChanged(BuildContext context, int index) {
    final Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
      case 1:
        return;
      case 2:
        page = const OrderPage();
      case 3:
        page = const StockMovementPage();
      case 4:
        page = const SettingPage();
      default:
        return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  List<_InventoryItem> get _visibleItems {
    final query = _searchQuery.trim().toLowerCase();

    return _items.where((item) {
      final nameMatches = query.isEmpty ||
          item.product.name.toLowerCase().contains(query) ||
          (item.product.barcode?.toLowerCase().contains(query) ?? false);

      if (!nameMatches) {
        return false;
      }

      switch (_selectedFilter) {
        case 'Low Stock':
          return item.stockStatus == _StockStatus.low;
        case 'Out of Stock':
          return item.stockStatus == _StockStatus.out;
        case 'In Stock':
          return item.stockStatus == _StockStatus.inStock;
        default:
          return true;
      }
    }).toList();
  }

  Color _statusBg(_StockStatus status) {
    switch (status) {
      case _StockStatus.inStock:
        return const Color(0xFFFFF7ED);
      case _StockStatus.low:
        return const Color(0xFFFFEDD5);
      case _StockStatus.out:
        return const Color(0xFFFEE2E2);
    }
  }

  Color _statusText(_StockStatus status) {
    switch (status) {
      case _StockStatus.inStock:
        return const Color(0xFFB45309);
      case _StockStatus.low:
        return const Color(0xFFEA580C);
      case _StockStatus.out:
        return const Color(0xFFDC2626);
    }
  }

  String _statusLabel(_StockStatus status) {
    switch (status) {
      case _StockStatus.inStock:
        return 'In Stock';
      case _StockStatus.low:
        return 'Low Stock';
      case _StockStatus.out:
        return 'Out of Stock';
    }
  }

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
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final selected = filter == _selectedFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedFilter = filter);
                          },
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
              ),
              OutlinedButton.icon(
                onPressed: _addItemToWarehouse,
                icon: const Icon(Icons.add_box_outlined, size: 18),
                label: const Text('Tambah Item'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _loadInventory,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Reload',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                'Gagal memuat data inventory',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadInventory,
                child: const Text('Coba lagi'),
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
          'Tidak ada data inventory.',
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
        final imageUrl = _imageUrlUseCase.resolveImageUrl(item.product.imageUrl);
        final proxyUrl = (imageUrl != null) 
			? _imageUrlUseCase.proxyImageUrl(imageUrl)
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
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_horiz_rounded),
                            visualDensity: VisualDensity.compact,
                            color: AppColors.textMedium,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigation(
              selectedIndex: 1,
              onNavChanged: (index) => _onBottomNavChanged(context, index),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockChangeInput {
  final int quantity;
  final String reason;

  const _StockChangeInput({required this.quantity, required this.reason});
}

class _InventoryItem {
  final ProductModel product;
  final InventoryModel? inventory;

  const _InventoryItem({required this.product, required this.inventory});

  int get stockQuantity => inventory?.stockQuantity ?? 0;
  int get sellingPrice => inventory?.sellingPrice ?? 0;

  _StockStatus get stockStatus {
    if (stockQuantity <= 0) {
      return _StockStatus.out;
    }

    final threshold = inventory?.lowStockThreshold ?? 5;
    if (stockQuantity <= threshold) {
      return _StockStatus.low;
    }

    return _StockStatus.inStock;
  }
}

enum _StockStatus { inStock, low, out }

class _InventoryProductImage extends StatefulWidget {
  final String primaryUrl;
  final String? fallbackUrl;
  final String productName;

  const _InventoryProductImage({
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
  Widget build(BuildContext context) {
    return Image.network(
      _activeUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, error, stackTrace) {
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
