import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/order_page.dart';
import 'package:inventory_app_project/pages/products/product_detail.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
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
  final ProductImageUrlUseCase _imageUrlUseCase = const ProductImageUrlUseCase();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<_InventoryItem> _items = const [];
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
      final inventoryByProductId = <String, InventoryModel>{
        for (final inventory in inventories) inventory.productId: inventory,
      };

      final items = products
          .map((product) => _InventoryItem(
                product: product,
                inventory: inventoryByProductId[product.id],
              ))
          .toList();

      setState(() {
        _items = items;
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
          item.product.barcode.toLowerCase().contains(query);

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
        final proxyUrl = _imageUrlUseCase.proxyImageUrl(imageUrl);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(
                  product: item.product,
                  inventory: item.inventory,
                ),
              ),
            );
          },
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
                        'Category ${item.product.categoryId} • ${item.stockQuantity} units',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Color(0xFF292524)),
      ),
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
