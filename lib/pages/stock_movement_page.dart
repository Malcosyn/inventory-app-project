import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/models/stock_movement_model.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/order_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/services/stock_movement_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';
import 'package:inventory_app_project/widgets/quick_actions_section.dart';

class StockMovementPage extends StatefulWidget {
  final bool showBottomNav;

  const StockMovementPage({super.key, this.showBottomNav = true});

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  static const int _defaultStoreId = 1;

  final StockMovementService _stockMovementService = StockMovementService();
  final ProductService _productService = ProductService();
  final ProductService _imageService = ProductService();

  bool _isLoading = true;
  String? _error;
  List<StockMovementModel> _movements = const [];
  Map<String, ProductModel> _productsById = const {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await Future.wait([
        _stockMovementService.getStockMovementsByStoreId(_defaultStoreId),
        _productService.getProductsByStoreId(_defaultStoreId),
      ]);

      if (!mounted) return;

      final movements = (result[0] as List<StockMovementModel>)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final products = result[1] as List<ProductModel>;

      setState(() {
        _movements = movements;
        _productsById = {
          for (final p in products) p.id: p,
        };
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

  bool _isStockIn(StockMovementModel movement) {
    return movement.type.toUpperCase() == 'IN';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatReason(String reason) {
    if (reason.trim().isEmpty) return 'ADJUSTMENT';
    return reason.trim().toUpperCase();
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day ago';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _openStockAction(bool stockIn) async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InventoryPage(
          initialQuickAction:
              stockIn ? InventoryQuickAction.stockIn : InventoryQuickAction.stockOut,
        ),
      ),
    );
  }

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

  Widget _buildQuickCards() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_circle_rounded,
            iconColor: const Color(0xFF4D7A35),
            iconBg: const Color(0xFFEAF5DF),
            title: 'Stock In',
            subtitle: 'Add new arrivals',
            onTap: () => _openStockAction(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.remove_circle_rounded,
            iconColor: AppColors.errorText,
            iconBg: AppColors.errorBg,
            title: 'Stock Out',
            subtitle: 'Record sales or waste',
            onTap: () => _openStockAction(false),
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _openStockAction(true),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Scan to Adjust',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(StockMovementModel movement) {
    final product = _productsById[movement.productId];
    final name = product?.name ?? 'Unknown Product';
    final isIn = _isStockIn(movement);
    final amountText = '${isIn ? '+' : '-'}${movement.quantity} units';
    final amountColor = isIn ? const Color(0xFF4D7A35) : AppColors.errorText;
    final reasonLabel = _formatReason(movement.reason);

    final imageUrl = _imageService.resolveImageUrl(product?.imageUrl);
    final proxyUrl = _imageService.proxyImageUrl(imageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.iconBgLight,
              child: imageUrl == null
                  ? const Icon(Icons.inventory_2_outlined, color: AppColors.textLight)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        if (proxyUrl != null) {
                          return Image.network(
                            proxyUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.textLight,
                              );
                            },
                          );
                        }
                        return const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textLight,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isIn
                            ? const Color(0xFFEAF5DF)
                            : AppColors.errorBg.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        reasonLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(movement.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ],
            ),
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
                'Failed to load stock movements',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final stockInToday = _movements
        .where((m) => _isStockIn(m) && _isSameDay(m.createdAt, now))
        .fold<int>(0, (total, m) => total + m.quantity);
    final stockOutToday = _movements
        .where((m) => !_isStockIn(m) && _isSameDay(m.createdAt, now))
        .fold<int>(0, (total, m) => total + m.quantity);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
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
                child: const Icon(Icons.swap_vert_rounded, color: Color(0xFFC87F2E)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Inventory flow overview',
                      style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Reload',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'In Today',
                    value: '$stockInToday',
                    color: const Color(0xFF4D7A35),
                  ),
                ),
                Container(width: 1, height: 34, color: AppColors.borderColor),
                Expanded(
                  child: _MetricTile(
                    label: 'Out Today',
                    value: '$stockOutToday',
                    color: AppColors.errorText,
                  ),
                ),
                Container(width: 1, height: 34, color: AppColors.borderColor),
                Expanded(
                  child: _MetricTile(
                    label: 'Activity',
                    value: '${_movements.length}',
                    color: const Color(0xFFC87F2E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildQuickCards(),
          const SizedBox(height: 14),
          _buildScanButton(),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: _loadData,
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_movements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No stock movement yet.',
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ),
            )
          else
            ..._movements.take(20).map(_buildActivityItem),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = BottomNavigation.heightFor(context);

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
                selectedIndex: 3,
                onNavChanged: (index) => _onBottomNavChanged(context, index),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
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
          style: TextStyle(
            fontSize: 18,
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
