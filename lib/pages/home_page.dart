import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/models/stock_movement_model.dart';
import 'package:inventory_app_project/pages/categories/category_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/order_page.dart';
import 'package:inventory_app_project/pages/setting_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/pages/suppliers/suppliers_page.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/services/stock_movement_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';
import 'package:inventory_app_project/widgets/quick_actions_section.dart';

class HomePage extends StatelessWidget {
  final bool showBottomNav;

  const HomePage({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    return _HomePageContent(showBottomNav: showBottomNav);
  }
}

class _HomePageContent extends StatefulWidget {
  final bool showBottomNav;

  const _HomePageContent({required this.showBottomNav});

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  static const int _defaultStoreId = 1;

  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  final StockMovementService _stockMovementService = StockMovementService();

  int _selectedNavIndex = 0;
  bool _isLoadingSummary = true;
  String? _summaryError;
  List<ProductModel> _products = const [];
  List<InventoryModel> _inventories = const [];
  List<StockMovementModel> _stockMovements = const [];
  String _selectedRange = 'Last 7 Days';

  int get _selectedDays => _selectedRange == 'Last 30 Days' ? 30 : 7;

  _TrendData get _trendData => _buildTrendData(days: _selectedDays);

  int get _todayTransactions {
    final now = DateTime.now();
    return _stockMovements.where((movement) {
      final local = movement.createdAt.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;
  }

  String get _transactionTrendPercent {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayCount = _stockMovements.where((movement) {
      final local = movement.createdAt.toLocal();
      return local.year == today.year &&
          local.month == today.month &&
          local.day == today.day;
    }).length;

    final yesterdayCount = _stockMovements.where((movement) {
      final local = movement.createdAt.toLocal();
      return local.year == yesterday.year &&
          local.month == yesterday.month &&
          local.day == yesterday.day;
    }).length;

    if (yesterdayCount == 0) {
      if (todayCount == 0) return '0%';
      return '+100%';
    }

    final diff = ((todayCount - yesterdayCount) / yesterdayCount) * 100;
    final rounded = diff.round();
    if (rounded > 0) return '+$rounded%';
    return '$rounded%';
  }

  _TrendData _buildTrendData({required int days}) {
    if (days <= 0) {
      return const _TrendData(
        bars: [0, 0, 0, 0, 0, 0, 0],
        labels: ['-', '-', '-', '-', '-', '-', '-'],
      );
    }

    const int bucketCount = 7;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));

    final totalsByDay = <DateTime, int>{};
    for (final movement in _stockMovements) {
      final local = movement.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(start) || day.isAfter(today)) continue;
      totalsByDay.update(day, (value) => value + movement.quantity,
          ifAbsent: () => movement.quantity);
    }

    final bucketSize = (days / bucketCount).ceil();
    final bucketValues = <int>[];
    final bucketLabels = <String>[];

    for (var i = 0; i < bucketCount; i++) {
      final bucketStart = start.add(Duration(days: i * bucketSize));
      if (bucketStart.isAfter(today)) {
        bucketValues.add(0);
        bucketLabels.add('-');
        continue;
      }

      var bucketEnd = bucketStart.add(Duration(days: bucketSize - 1));
      if (bucketEnd.isAfter(today)) {
        bucketEnd = today;
      }

      var total = 0;
      var cursor = bucketStart;
      while (!cursor.isAfter(bucketEnd)) {
        total += totalsByDay[cursor] ?? 0;
        cursor = cursor.add(const Duration(days: 1));
      }

      bucketValues.add(total);
      bucketLabels.add(days == 7
          ? _weekdayShort(bucketStart.weekday)
          : '${bucketStart.day}/${bucketStart.month}');
    }

    final maxValue = bucketValues.fold<int>(0, (max, value) => value > max ? value : max);
    final bars = bucketValues
        .map((value) {
          if (maxValue == 0) return 0.0;
          final fraction = value / maxValue;
          return value > 0 ? fraction.clamp(0.12, 1.0) : 0.0;
        })
        .toList();

    return _TrendData(bars: bars, labels: bucketLabels);
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '-';
    }
  }

  void _onBottomNavChanged(int index) {
    if (index == 0) {
      if (_selectedNavIndex != 0) {
        setState(() => _selectedNavIndex = 0);
      }
      return;
    }

    final Widget page;
    switch (index) {
      case 1:
        page = const InventoryPage();
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

  @override
  void initState() {
    super.initState();
    _loadHomeSummary();
  }

  Future<void> _loadHomeSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    final errors = <String>[];
    List<ProductModel> products = const [];
    List<InventoryModel> inventories = const [];
    List<StockMovementModel> stockMovements = const [];

    try {
      products = await _productService.getProductsByStoreId(_defaultStoreId);
    } catch (e) {
      errors.add('products: $e');
    }

    try {
      inventories = await _inventoryService.getInventoriesByStoreId(_defaultStoreId);
    } catch (e) {
      errors.add('inventories: $e');
    }

    try {
      stockMovements = await _stockMovementService.getStockMovementsByStoreId(
        _defaultStoreId,
      );
    } catch (e) {
      errors.add('stock_movement: $e');
    }

    if (!mounted) return;

    setState(() {
      _products = products;
      _inventories = inventories;
      _stockMovements = stockMovements;
      _summaryError = errors.isEmpty ? null : errors.first;
      _isLoadingSummary = false;
    });
  }

  Future<void> _handleQuickAction(InventoryQuickAction action) async {
    switch (action) {
      case InventoryQuickAction.addOrder:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OrderPage()),
        );
        break;
      case InventoryQuickAction.addItem:
      case InventoryQuickAction.addSupplier:
      case InventoryQuickAction.addCategory:
      case InventoryQuickAction.stockIn:
      case InventoryQuickAction.stockOut:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InventoryPage(initialQuickAction: action),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = BottomNavigation.heightFor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildQuickAccessNav()),
              SliverToBoxAdapter(child: _buildInventorySummary()),
              SliverToBoxAdapter(child: _buildStockTrend()),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: widget.showBottomNav
                ? BottomNavigation(
                    selectedIndex: _selectedNavIndex,
                    onNavChanged: _onBottomNavChanged,
                  )
                : const SizedBox.shrink(),
          ),
          InventoryQuickActionsSection(
            bottomOffset: navBarHeight + 12,
            onActionSelected: _handleQuickAction,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.textMedium,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Good Morning, Admin',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          _headerIconBtn(Icons.search_rounded),
          const SizedBox(width: 8),
          _notificationBtn(),
        ],
      ),
    );
  }

  Widget _buildQuickAccessNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Quick Actions'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              _quickActionButton(
                icon: Icons.add_box_outlined,
                label: 'Add Item',
                bg: AppColors.primary,
                iconColor: AppColors.textOnPrimary,
                hasShadow: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InventoryPage(initialQuickAction: InventoryQuickAction.addItem),
                    ),
                  );
                },
              ),
              _quickActionButton(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                bg: AppColors.darkSurface,
                iconColor: Colors.white,
                hasShadow: true,
                onTap: () {},
              ),
              _quickActionButton(
                icon: Icons.person_add_outlined,
                label: 'Supplier',
                bg: Colors.white,
                iconColor: AppColors.textDark,
                hasBorder: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SuppliersPage(),
                    ),
                  );
                },
              ),
              _quickActionButton(
                icon: Icons.category_outlined,
                label: 'Category',
                bg: Colors.white,
                iconColor: AppColors.textDark,
                hasBorder: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CategoryPage(),
                    ),
                  );
                },
              ),
              _quickActionButton(
                icon: Icons.receipt_long_outlined,
                label: 'Order',
                bg: Colors.white,
                iconColor: AppColors.textDark,
                hasBorder: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrderPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color bg,
    required Color iconColor,
    bool hasShadow = false,
    bool hasBorder = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: hasBorder ? Border.all(color: AppColors.borderColor) : null,
              boxShadow: hasShadow
                  ? [
                      BoxShadow(
                        color: bg.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.iconBgLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.textSlate, size: 22),
    );
  }

  Widget _notificationBtn() {
    return Stack(
      children: [
        _headerIconBtn(Icons.notifications_outlined),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventorySummary() {
    final totalProducts = _products.length;
    final lowStockItems = _inventories
        .where((inv) => inv.stockQuantity < inv.lowStockThreshold)
        .length;
    final todayTransactions = _todayTransactions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Inventory Summary'),
          const SizedBox(height: 16),
          if (_summaryError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.errorText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Failed to load summary. Please try again.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.errorDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadHomeSummary,
                        child: const Text('Reload'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _summaryError!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.errorDark,
                    ),
                  ),
                ],
              ),
            ),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.inventory_2_outlined,
                      iconBg: AppColors.borderColor,
                      iconColor: AppColors.textMedium,
                      value: totalProducts.toString(),
                      label: 'Total Products',
                      isLoading: _isLoadingSummary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.warning_amber_rounded,
                      iconBg: AppColors.accentOrangeBg,
                      iconColor: AppColors.accentOrangeText,
                      value: lowStockItems.toString(),
                      valueColor: AppColors.accentOrangeText,
                      label: 'Low Stock Items',
                      borderColor: AppColors.accentOrangeBorder,
                      cardBg: AppColors.accentOrangeBg,
                      isLoading: _isLoadingSummary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _transactionCard(
                todayTransactions,
                _isLoadingSummary,
                _transactionTrendPercent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    Color? valueColor,
    Color? borderColor,
    Color? cardBg,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppColors.borderColor),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(
              width: 60,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionCard(int count, bool isLoading, String trendPercent) {
    return Container(
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF3B82F6),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 60,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              const Text(
                'Today Stock Movement',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                trendPercent.startsWith('-')
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                color: trendPercent.startsWith('-')
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
                size: 18,
              ),
              const SizedBox(width: 2),
              Text(
                trendPercent,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: trendPercent.startsWith('-')
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockTrend() {
    final trendData = _trendData;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Stock Trend'),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRange,
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontFamily: 'Manrope',
                  ),
                  items: ['Last 7 Days', 'Last 30 Days']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRange = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
              children: [
                SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(trendData.bars.length, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4,
                            right: i == trendData.bars.length - 1 ? 0 : 4,
                          ),
                          child: _Bar(heightFraction: trendData.bars[i]),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: trendData.labels
                      .map(
                        (d) => Text(
                          d,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textMedium,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  final double heightFraction;

  const _Bar({required this.heightFraction});

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight;
            return Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: maxH * widget.heightFraction.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: _hovered
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.55),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrendData {
  final List<double> bars;
  final List<String> labels;

  const _TrendData({required this.bars, required this.labels});
}