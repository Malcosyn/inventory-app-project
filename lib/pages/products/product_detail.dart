import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/category_model.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/models/stock_movement_model.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/usecases/products/product_detail_usecase.dart';
import 'package:inventory_app_project/usecases/products/product_image_url_usecase.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFF5F3EF);
  static const surface    = Color(0xFFFFFFFF);
  static const border     = Color(0xFFE8E4DC);
  static const ink        = Color(0xFF1A1611);
  static const inkMid     = Color(0xFF6B6560);
  static const inkLight   = Color(0xFFA09A93);
  static const accent     = Color(0xFF2563EB);   // vivid blue
  static const accentBg   = Color(0xFFEFF4FF);
  static const green      = Color(0xFF16A34A);
  static const greenBg    = Color(0xFFDCFCE7);
  static const amber      = Color(0xFFD97706);
  static const amberBg    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFDC2626);
  static const redBg      = Color(0xFFFEE2E2);
}

// ─── Text styles ────────────────────────────────────────────────────────────
class _T {
  static const displayName = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: _C.ink,
    height: 1.2,
    letterSpacing: -0.4,
  );
  static const sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: _C.inkLight,
    letterSpacing: 1.2,
  );
  static const label = TextStyle(
    fontSize: 13.5,
    color: _C.inkMid,
    fontWeight: FontWeight.w400,
  );
  static const value = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: _C.ink,
  );
  static const tag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  ProductDetailPage
// ═══════════════════════════════════════════════════════════════════════════
class ProductDetailPage extends StatelessWidget {
  final ProductModel product;
  final InventoryModel? inventory;
  final CategoryModel? category;
  final String? categoryNameOverride;
  final SupplierModel? supplier;
  final List<StockMovementModel> recentMovements;
  final VoidCallback? onEdit;
  final VoidCallback? onStockIn;
  final VoidCallback? onStockOut;
  final VoidCallback? onDelete;
  final ProductDetailUseCase _useCase = const ProductDetailUseCase();

  const ProductDetailPage({
    super.key,
    required this.product,
    this.inventory,
    this.category,
    this.categoryNameOverride,
    this.supplier,
    this.recentMovements = const [],
    this.onEdit,
    this.onStockIn,
    this.onStockOut,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final vm         = _useCase.build(product, inventory);
    final stockState = _StockState.fromDomain(vm.stockState);
    final catName    = categoryNameOverride ??
        category?.name ??
        (product.categoryId != null ? 'Category ${product.categoryId}' : 'Uncategorized');

    return Scaffold(
      backgroundColor: _C.bg,
      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _C.bg,
        titleSpacing: 0,
        title: const Text(
          'Product Detail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _C.ink,
            letterSpacing: -0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: _C.ink),
        actions: [
          if (onEdit != null)
            _AppBarButton(
              icon: Icons.edit_outlined,
              color: _C.accent,
              onTap: onEdit!,
            ),
          if (onDelete != null)
            _AppBarButton(
              icon: Icons.delete_outline_rounded,
              color: _C.red,
              onTap: onDelete!,
            ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Hero header
          _HeroCard(
            product: product,
            categoryName: catName,
            stockLabel: stockState.label,
            stock: vm.stock,
            stateColor: stockState.color,
            stateBgColor: stockState.bgColor,
          ),

          const SizedBox(height: 8),

          // Quick stats row
          _QuickStatsRow(
            stock: vm.stock,
            threshold: vm.threshold,
            stockValue: 'Rp${vm.stockValue}',
            stockState: stockState,
          ),

          const SizedBox(height: 16),

          // Price card
          _SectionLabel('PRICING'),
          const SizedBox(height: 8),
          _PriceCard(
            costPrice: 'Rp${vm.costPrice}',
            sellingPrice: 'Rp${vm.sellingPrice}',
            margin: 'Rp${vm.margin}',
            marginPositive: vm.margin >= 0,
          ),

          const SizedBox(height: 16),

          // Supplier card
          _SectionLabel('SUPPLIER'),
          const SizedBox(height: 8),
          _SupplierCard(supplier: supplier),

          const SizedBox(height: 16),

          // Product info
          _SectionLabel('PRODUCT INFO'),
          const SizedBox(height: 8),
          _InfoCard(
            rows: [
              _RowData('Barcode', product.barcode ?? '—'),
              _RowData('Created At', _formatDate(product.createdAt), isLast: true),
            ],
          ),

          const SizedBox(height: 16),

          // Movements
          _SectionLabel('RECENT STOCK MOVEMENTS'),
          const SizedBox(height: 8),
          _MovementsCard(movements: recentMovements),

          const SizedBox(height: 16),
        ],
      ),

      // ── Bottom action bar ─────────────────────────────────────────────────
      bottomNavigationBar: _BottomActions(
        onEdit: onEdit,
        onStockIn: onStockIn,
        onStockOut: onStockOut,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

// ─── AppBar icon button ──────────────────────────────────────────────────────
class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AppBarButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── Section label ───────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(text, style: _T.sectionTitle),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Hero Card
// ═══════════════════════════════════════════════════════════════════════════
class _HeroCard extends StatelessWidget {
  final ProductModel product;
  final String categoryName;
  final int stock;
  final String stockLabel;
  final Color stateColor;
  final Color stateBgColor;
  final ProductImageUrlUseCase _imgUseCase = const ProductImageUrlUseCase();

  const _HeroCard({
    required this.product,
    required this.categoryName,
    required this.stock,
    required this.stockLabel,
    required this.stateColor,
    required this.stateBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imgUseCase.resolveImageUrl(product.imageUrl);
    final proxyUrl = imageUrl != null ? _imgUseCase.proxyImageUrl(imageUrl) : null;

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image strip
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFFF0EDE8),
              child: imageUrl == null
                  ? const Center(
                      child: Icon(Icons.inventory_2_outlined,
                          size: 56, color: Color(0xFFC4BDB5)),
                    )
                  : _ProductDetailImage(
                      primaryUrl: imageUrl,
                      fallbackUrl: proxyUrl,
                      productName: product.name,
                    ),
            ),
          ),

          // Info row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: _T.displayName),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.folder_outlined,
                              size: 13, color: _C.inkLight),
                          const SizedBox(width: 4),
                          Text(categoryName,
                              style: const TextStyle(
                                  fontSize: 13, color: _C.inkMid)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(
                    label: stockLabel,
                    fg: stateColor,
                    bg: stateBgColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status badge ────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _StatusBadge({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: fg.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: _T.tag.copyWith(color: fg)),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Quick Stats Row
// ═══════════════════════════════════════════════════════════════════════════
class _QuickStatsRow extends StatelessWidget {
  final int stock;
  final int threshold;
  final String stockValue;
  final _StockState stockState;

  const _QuickStatsRow({
    required this.stock,
    required this.threshold,
    required this.stockValue,
    required this.stockState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          icon: Icons.inventory_2_rounded,
          iconColor: stockState.color,
          iconBg: stockState.bgColor,
          label: 'Current Stock',
          value: '$stock unit',
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.warning_amber_rounded,
          iconColor: _C.amber,
          iconBg: _C.amberBg,
          label: 'Low Threshold',
          value: '$threshold unit',
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: _C.accent,
          iconBg: _C.accentBg,
          label: 'Stock Value',
          value: stockValue,
          compact: true,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;
  final bool compact;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 10.5, color: _C.inkLight, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w700,
                    color: _C.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Price Card
// ═══════════════════════════════════════════════════════════════════════════
class _PriceCard extends StatelessWidget {
  final String costPrice, sellingPrice, margin;
  final bool marginPositive;

  const _PriceCard({
    required this.costPrice,
    required this.sellingPrice,
    required this.margin,
    required this.marginPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'Cost Price', value: costPrice),
          _Divider(),
          _PriceRow(label: 'Selling Price', value: sellingPrice,
              valueStyle: _T.value.copyWith(color: _C.accent)),
          _Divider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: marginPositive ? _C.greenBg : _C.redBg,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  marginPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: marginPositive ? _C.green : _C.red,
                ),
                const SizedBox(width: 8),
                Text('Margin per Item',
                    style: _T.label.copyWith(
                        color: marginPositive ? _C.green : _C.red)),
                const Spacer(),
                Text(margin,
                    style: _T.value.copyWith(
                        color: marginPositive ? _C.green : _C.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final TextStyle? valueStyle;
  const _PriceRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Text(label, style: _T.label),
      const Spacer(),
      Text(value, style: valueStyle ?? _T.value),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: _C.border, indent: 16, endIndent: 16);
}

// ═══════════════════════════════════════════════════════════════════════════
//  Supplier Card
// ═══════════════════════════════════════════════════════════════════════════
class _SupplierCard extends StatelessWidget {
  final SupplierModel? supplier;
  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    if (supplier == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_off_outlined,
                  size: 18, color: _C.inkLight),
            ),
            const SizedBox(width: 12),
            const Text('No supplier assigned',
                style: TextStyle(color: _C.inkMid, fontSize: 13.5)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          // Supplier header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _C.accentBg,
                  child: Text(
                    supplier!.name.isNotEmpty
                        ? supplier!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: _C.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplier!.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _C.ink,
                              fontSize: 14)),
                      if (supplier!.email?.isNotEmpty ?? false)
                        Text(supplier!.email!,
                            style: const TextStyle(
                                color: _C.inkMid, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (supplier!.phone.isNotEmpty || (supplier!.address.isNotEmpty)) ...[
            const Divider(height: 1, thickness: 1, color: _C.border),
            _InfoCard(
              rounded: false,
              rows: [
                if (supplier!.phone.isNotEmpty)
                  _RowData('Phone', supplier!.phone,
                      icon: Icons.phone_outlined),
                if (supplier!.address.isNotEmpty)
                  _RowData('Address', supplier!.address,
                      icon: Icons.location_on_outlined, isLast: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Generic Info Card
// ═══════════════════════════════════════════════════════════════════════════
class _RowData {
  final String label, value;
  final IconData? icon;
  final bool isLast;
  const _RowData(this.label, this.value, {this.icon, this.isLast = false});
}

class _InfoCard extends StatelessWidget {
  final List<_RowData> rows;
  final bool rounded;
  const _InfoCard({required this.rows, this.rounded = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: rounded
          ? BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            )
          : null,
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (row.icon != null) ...[
                      Icon(row.icon, size: 15, color: _C.inkLight),
                      const SizedBox(width: 8),
                    ],
                    Text(row.label, style: _T.label),
                    const Spacer(),
                    Flexible(
                      child: Text(row.value,
                          style: _T.value,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              if (!row.isLast && i < rows.length - 1)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: _C.border,
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Movements Card
// ═══════════════════════════════════════════════════════════════════════════
class _MovementsCard extends StatelessWidget {
  final List<StockMovementModel> movements;
  const _MovementsCard({required this.movements});

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 32, color: _C.inkLight),
              SizedBox(height: 8),
              Text('No movement data yet.',
                  style: TextStyle(color: _C.inkMid, fontSize: 13.5)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: movements.take(10).toList().asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          final isIn = m.type.toUpperCase() == 'IN';
          final isLast = i == (movements.length < 10 ? movements.length - 1 : 9);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isIn ? _C.greenBg : _C.redBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                        color: isIn ? _C.green : _C.red,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Label + note
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isIn ? _C.greenBg : _C.redBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isIn ? 'IN' : 'OUT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isIn ? _C.green : _C.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${m.quantity} unit',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: _C.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(m.createdAt)}${m.note.isNotEmpty ? '  ·  ${m.note}' : ''}',
                            style: const TextStyle(
                                fontSize: 11.5, color: _C.inkMid),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Stock after
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('after',
                            style: TextStyle(fontSize: 10, color: _C.inkLight)),
                        Text(
                          '${m.stockAfter}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _C.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: _C.border,
                    indent: 62,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ═══════════════════════════════════════════════════════════════════════════
//  Bottom Actions Bar
// ═══════════════════════════════════════════════════════════════════════════
class _BottomActions extends StatelessWidget {
  final VoidCallback? onEdit, onStockIn, onStockOut;
  const _BottomActions({this.onEdit, this.onStockIn, this.onStockOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          // Edit (secondary)
          _ActionBtn(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onTap: onEdit,
            variant: _BtnVariant.outline,
          ),
          const SizedBox(width: 8),
          // Stock In
          Expanded(
            child: _ActionBtn(
              label: 'Stock In',
              icon: Icons.add_rounded,
              onTap: onStockIn,
              variant: _BtnVariant.filled,
              fillColor: _C.green,
            ),
          ),
          const SizedBox(width: 8),
          // Stock Out
          Expanded(
            child: _ActionBtn(
              label: 'Stock Out',
              icon: Icons.remove_rounded,
              onTap: onStockOut,
              variant: _BtnVariant.filled,
              fillColor: _C.red,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BtnVariant { outline, filled }

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final _BtnVariant variant;
  final Color? fillColor;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.variant,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final isOutline = variant == _BtnVariant.outline;
    return SizedBox(
      height: 48,
      child: Material(
        color: isOutline ? Colors.transparent : fillColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: isOutline
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border, width: 1.5),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: isOutline ? _C.ink : Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isOutline ? _C.ink : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Product Image (unchanged logic, same fallback pattern)
// ═══════════════════════════════════════════════════════════════════════════
class _ProductDetailImage extends StatefulWidget {
  final String primaryUrl;
  final String? fallbackUrl;
  final String productName;

  const _ProductDetailImage({
    required this.primaryUrl,
    required this.fallbackUrl,
    required this.productName,
  });

  @override
  State<_ProductDetailImage> createState() => _ProductDetailImageState();
}

class _ProductDetailImageState extends State<_ProductDetailImage> {
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
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                : null,
            color: _C.accent,
          ),
        );
      },
      errorBuilder: (_, error, __) {
        if (!_usingFallback && widget.fallbackUrl != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _usingFallback = true;
              _activeUrl = widget.fallbackUrl!;
            });
          });
          return const SizedBox.shrink();
        }
        return const Center(
          child: Icon(Icons.inventory_2_outlined,
              size: 48, color: Color(0xFFC4BDB5)),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Domain enum (unchanged)
// ═══════════════════════════════════════════════════════════════════════════
enum _StockState {
  inStock(label: 'In Stock',    color: _C.green, bgColor: _C.greenBg),
  low    (label: 'Low Stock',   color: _C.amber, bgColor: _C.amberBg),
  out    (label: 'Out of Stock',color: _C.red,   bgColor: _C.redBg);

  final String label;
  final Color color, bgColor;

  const _StockState({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  static _StockState fromDomain(ProductStockState state) => switch (state) {
    ProductStockState.inStock => _StockState.inStock,
    ProductStockState.low     => _StockState.low,
    ProductStockState.out     => _StockState.out,
  };
}