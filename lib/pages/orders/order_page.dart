import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/order_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/pages/app_shell_page.dart';
import 'package:inventory_app_project/pages/orders/edit_order_dialog.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/order_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/services/stock_movement_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';
import 'package:inventory_app_project/widgets/page_loading_view.dart';

class OrderPage extends StatefulWidget {
  final bool showBottomNav;
  final int refreshTick;

  const OrderPage({super.key, this.showBottomNav = true, this.refreshTick = 0});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  static const int _defaultStoreId = 1;
  static const String _allStatusValue = '__all__';
  static const Map<String, String> _defaultStatusLabels = {
    'PROCESSING': 'Processing',
    'SHIPPED': 'Shipped',
    'DELIVERED': 'Delivered',
    'CANCELLED': 'Cancelled',
  };

  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  final StockMovementService _stockMovementService = StockMovementService();

  bool _isLoading = true;
  String? _error;
  List<OrderModel> _orders = const [];
  Map<String, ProductModel> _productsById = const {};
  Map<String, InventoryModel> _inventoriesByProductId = const {};
  String _selectedStatus = _allStatusValue;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didUpdateWidget(covariant OrderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await Future.wait([
        _orderService.getOrdersByStoreId(_defaultStoreId),
        _productService.getProductsByStoreId(_defaultStoreId),
        _inventoryService.getInventoriesByStoreId(_defaultStoreId),
      ]);

      if (!mounted) return;

      final orders = result[0] as List<OrderModel>;
      final products = result[1] as List<ProductModel>;
      final inventories = result[2] as List<InventoryModel>;

      setState(() {
        _orders = orders;
        _productsById = {for (final p in products) p.id: p};
        _inventoriesByProductId = {
          for (final inventory in inventories) inventory.productId: inventory,
        };
        final statusValues = _statusFilters.map((s) => s.value).toSet();
        if (_selectedStatus != _allStatusValue &&
            !statusValues.contains(_selectedStatus)) {
          _selectedStatus = _allStatusValue;
        }
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

  List<_StatusFilterOption> get _statusFilters {
    final normalizedStatusMap = <String, String>{..._defaultStatusLabels};

    for (final order in _orders) {
      final status = order.status.trim().toUpperCase();
      if (status.isEmpty) continue;
      normalizedStatusMap.putIfAbsent(status, () => _titleCaseStatus(status));
    }

    final entries = normalizedStatusMap.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    return [
      const _StatusFilterOption(value: _allStatusValue, label: 'All'),
      ...entries.map(
        (entry) => _StatusFilterOption(value: entry.key, label: entry.value),
      ),
    ];
  }

  String _titleCaseStatus(String statusValue) {
    final words = statusValue
        .split(RegExp(r'[_\s-]+'))
        .where((w) => w.isNotEmpty);
    return words
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .toList()
        .join(' ');
  }

  List<OrderModel> get _visibleOrders {
    if (_selectedStatus == _allStatusValue) return _orders;
    final selectedStatus = _selectedStatus.trim().toUpperCase();
    return _orders
        .where((o) => o.status.trim().toUpperCase() == selectedStatus)
        .toList();
  }

  String _formatCurrency(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final pos = text.length - i;
      buffer.write(text[i]);
      if (pos > 1 && pos % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp$buffer';
  }

  Color _statusColor(String status) {
    final s = status.trim().toUpperCase();
    if (s == 'DELIVERED') return const Color(0xFF4D7A35);
    if (s == 'PROCESSING' || s == 'SHIPPED') return const Color(0xFFB45309);
    if (s == 'CANCELLED') return AppColors.errorText;
    return AppColors.textMedium;
  }

  String _statusLabel(String status) {
    final value = status.trim().toUpperCase();
    return _defaultStatusLabels[value] ?? _titleCaseStatus(value);
  }

  bool _isDeliveredStatus(String status) {
    return status.trim().toUpperCase() == 'DELIVERED';
  }

  Future<void> _applyDeliveredStockIn({
    required String orderId,
    required String productId,
    required int quantity,
    required int storeId,
  }) async {
    final currentInventory = _inventoriesByProductId[productId];
    final stockAfter = (currentInventory?.stockQuantity ?? 0) + quantity;

    if (currentInventory != null) {
      await _inventoryService.updateInventory(
        InventoryModel(
          id: currentInventory.id,
          productId: currentInventory.productId,
          costPrice: currentInventory.costPrice,
          sellingPrice: currentInventory.sellingPrice,
          stockQuantity: stockAfter,
          lowStockThreshold: currentInventory.lowStockThreshold,
          updatedAt: DateTime.now(),
          storeId: currentInventory.storeId,
        ),
      );
    }

    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    await _stockMovementService.createStockMovementEntry(
      productId: productId,
      type: 'IN',
      quantity: quantity,
      stockAfter: stockAfter,
      reason: null,
      note: 'Auto stock-in from delivered order #$shortId',
      storeId: storeId,
    );
  }

  Future<void> _editOrder(OrderModel order) async {
    final products = _productsById.values.toList();
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product data is not available yet.')),
      );
      return;
    }

    final input = await EditOrderDialog.show(
      context,
      products: products,
      order: order,
    );

    if (!mounted || input == null) return;

    final wasDelivered = _isDeliveredStatus(order.status);
    final willBeDelivered = _isDeliveredStatus(input.status);

    try {
      await _orderService.updateOrder(
        OrderModel(
          id: order.id,
          productId: input.productId,
          totalPrice: input.totalPrice,
          totalItem: input.totalItem,
          status: input.status,
          unitType: input.unitType,
          storeId: order.storeId,
        ),
      );

      if (!wasDelivered && willBeDelivered) {
        await _applyDeliveredStockIn(
          orderId: order.id,
          productId: input.productId,
          quantity: input.totalItem,
          storeId: order.storeId,
        );
      }

      if (!mounted) return;
      final message = (!wasDelivered && willBeDelivered)
          ? 'Order updated and stock movement IN created.'
          : 'Order updated successfully.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update order: $e')));
    }
  }

  void _onBottomNavChanged(BuildContext context, int index) {
    if (index == 2) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AppShellPage(initialIndex: index)),
    );
  }

  Widget _buildSummary() {
    final totalOrders = _orders.length;
    final totalItems = _orders.fold<int>(0, (sum, o) => sum + o.totalItem);
    final totalRevenue = _orders.fold<int>(0, (sum, o) => sum + o.totalPrice);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'Orders',
              value: '$totalOrders',
              color: AppColors.textDark,
            ),
          ),
          Container(width: 1, height: 34, color: AppColors.borderColor),
          Expanded(
            child: _Metric(
              label: 'Items',
              value: '$totalItems',
              color: const Color(0xFFC87F2E),
            ),
          ),
          Container(width: 1, height: 34, color: AppColors.borderColor),
          Expanded(
            child: _Metric(
              label: 'Revenue',
              value: _formatCurrency(totalRevenue),
              color: const Color(0xFF4D7A35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final product = _productsById[order.productId];
    final productName = product?.name ?? 'Unknown Product';
    final color = _statusColor(order.status);
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editOrder(order);
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
                ],
                icon: const Icon(Icons.more_horiz_rounded),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                iconColor: AppColors.textMedium,
                tooltip: 'Order options',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Order #$shortId',
            style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${order.totalItem} ${order.unitType}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(order.totalPrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC87F2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return PageLoadingView(
        itemCount: 4,
        topPadding: MediaQuery.of(context).padding.top + 8,
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.errorText,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load orders',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = _visibleOrders;
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 8,
          16,
          100,
        ),
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFC87F2E),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Store order overview',
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
          const SizedBox(height: 14),
          _buildSummary(),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _statusFilters.map((statusOption) {
                final selected = _selectedStatus == statusOption.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(statusOption.label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = statusOption.value),
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFF59E0B)
                          : AppColors.borderColor,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF92400E)
                          : AppColors.textMedium,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  'No orders found.',
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ),
            )
          else
            ...visible.map(_buildOrderCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          _buildBody(),
          if (widget.showBottomNav)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavigation(
                selectedIndex: 2,
                onNavChanged: (index) => _onBottomNavChanged(context, index),
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
        ),
      ],
    );
  }
}

class _StatusFilterOption {
  final String value;
  final String label;

  const _StatusFilterOption({required this.value, required this.label});
}
