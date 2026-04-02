import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/order_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/services/order_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';

class OrderPage extends StatefulWidget {
  final bool showBottomNav;

  const OrderPage({super.key, this.showBottomNav = true});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  static const int _defaultStoreId = 1;

  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  String? _error;
  List<OrderModel> _orders = const [];
  Map<String, ProductModel> _productsById = const {};
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadOrders();
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
      ]);

      if (!mounted) return;

      final orders = result[0] as List<OrderModel>;
      final products = result[1] as List<ProductModel>;

      setState(() {
        _orders = orders;
        _productsById = {for (final p in products) p.id: p};
        if (_selectedStatus != 'All' && !_statusFilters.contains(_selectedStatus)) {
          _selectedStatus = 'All';
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

  List<String> get _statusFilters {
    final statuses = _orders.map((e) => e.status.trim()).where((e) => e.isNotEmpty).toSet().toList()
      ..sort();
    return <String>['All', ...statuses];
  }

  List<OrderModel> get _visibleOrders {
    if (_selectedStatus == 'All') return _orders;
    return _orders.where((o) => o.status == _selectedStatus).toList();
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
    final s = status.toLowerCase();
    if (s.contains('complete') || s.contains('paid')) return const Color(0xFF4D7A35);
    if (s.contains('pending') || s.contains('process')) return const Color(0xFFB45309);
    if (s.contains('cancel') || s.contains('fail')) return AppColors.errorText;
    return AppColors.textMedium;
  }

  void _onBottomNavChanged(BuildContext context, int index) {
    final Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
      case 1:
        page = const InventoryPage();
      case 2:
        return;
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
            child: _Metric(label: 'Orders', value: '$totalOrders', color: AppColors.textDark),
          ),
          Container(width: 1, height: 34, color: AppColors.borderColor),
          Expanded(
            child: _Metric(label: 'Items', value: '$totalItems', color: const Color(0xFFC87F2E)),
          ),
          Container(width: 1, height: 34, color: AppColors.borderColor),
          Expanded(
            child: _Metric(label: 'Revenue', value: _formatCurrency(totalRevenue), color: const Color(0xFF4D7A35)),
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
                  order.status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
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
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.errorText),
              const SizedBox(height: 8),
              const Text(
                'Failed to load orders',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _loadOrders, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final visible = _visibleOrders;
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
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
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFC87F2E)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    Text('Store order overview', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ],
                ),
              ),
              IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSummary(),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _statusFilters.map((status) {
                final selected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedStatus = status),
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected ? const Color(0xFFF59E0B) : AppColors.borderColor,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFF92400E) : AppColors.textMedium,
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
                child: Text('No orders found.', style: TextStyle(color: AppColors.textMedium)),
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

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
      ],
    );
  }
}
