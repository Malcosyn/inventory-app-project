import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/category_model.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/models/stock_movement_model.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/usecases/products/product_detail_usecase.dart';
import 'package:inventory_app_project/usecases/products/product_image_url_usecase.dart';

class ProductDetailPage extends StatelessWidget {
	final ProductModel product;
	final InventoryModel? inventory;
	final CategoryModel? category;
	final SupplierModel? supplier;
	final List<StockMovementModel> recentMovements;
	final VoidCallback? onEdit;
	final VoidCallback? onStockIn;
	final VoidCallback? onStockOut;
	final ProductDetailUseCase _useCase = const ProductDetailUseCase();

	const ProductDetailPage({
		super.key,
		required this.product,
		this.inventory,
		this.category,
		this.supplier,
		this.recentMovements = const [],
		this.onEdit,
		this.onStockIn,
		this.onStockOut,
	});

	@override
	Widget build(BuildContext context) {
		final vm = _useCase.build(product, inventory);
		final stockState = _StockState.fromDomain(vm.stockState);

		return Scaffold(
			backgroundColor: const Color(0xFFFCF9F5),
			appBar: AppBar(
				title: const Text('Product Detail'),
				backgroundColor: Colors.white,
				elevation: 0,
				scrolledUnderElevation: 0,
				surfaceTintColor: Colors.white,
			),
			body: ListView(
				padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
				children: [
					_HeaderCard(
						product: vm.product,
						categoryName: category?.name ?? 'Uncategorized',
						stockLabel: stockState.label,
						stock: vm.stock,
						stateColor: stockState.color,
						stateBgColor: stockState.bgColor,
					),
					const SizedBox(height: 12),
					_SectionCard(
						title: 'Stock Information',
						child: Column(
							children: [
								_InfoRow(label: 'Current Stock', value: '${vm.stock} unit'),
								_InfoRow(
									label: 'Low Stock Threshold',
									value: '${vm.threshold} unit',
								),
								_InfoRow(
									label: 'Stock Value',
									value: 'Rp${vm.stockValue}',
									isLast: true,
								),
							],
						),
					),
					const SizedBox(height: 12),
					_SectionCard(
						title: 'Price',
						child: Column(
							children: [
								_InfoRow(label: 'Cost Price', value: 'Rp${vm.costPrice}'),
								_InfoRow(
									label: 'Selling Price',
									value: 'Rp${vm.sellingPrice}',
								),
								_InfoRow(
									label: 'Margin per Item',
									value: 'Rp${vm.margin}',
									valueColor: vm.margin >= 0
											? const Color(0xFF16A34A)
											: const Color(0xFFDC2626),
									isLast: true,
								),
							],
						),
					),
					const SizedBox(height: 12),
					_SectionCard(
						title: 'Supplier & Metadata',
						child: Column(
							children: [
								_InfoRow(label: 'Supplier', value: supplier?.name ?? '-'),
								_InfoRow(label: 'Supplier Phone', value: supplier?.phone ?? '-'),
								_InfoRow(label: 'Barcode', value: product.barcode),
								_InfoRow(
									label: 'Created At',
									value: _formatDate(product.createdAt),
									isLast: true,
								),
							],
						),
					),
					const SizedBox(height: 12),
					_SectionCard(
						title: 'Recent Stock Movements',
						child: recentMovements.isEmpty
								? const Padding(
										padding: EdgeInsets.symmetric(vertical: 8),
										child: Text(
											'No movement data yet.',
											style: TextStyle(color: Color(0xFF64748B)),
										),
									)
								: Column(
										children: recentMovements.take(10).map((movement) {
											final isIn = movement.type.toLowerCase() == 'in';
											return ListTile(
												dense: true,
												contentPadding: EdgeInsets.zero,
												leading: CircleAvatar(
													radius: 14,
													backgroundColor: isIn
															? const Color(0xFFDCFCE7)
															: const Color(0xFFFEE2E2),
													child: Icon(
														isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
														color: isIn
																? const Color(0xFF16A34A)
																: const Color(0xFFDC2626),
														size: 16,
													),
												),
												title: Text(
													'${movement.type.toUpperCase()} • ${movement.quantity} unit',
													style: const TextStyle(
														fontWeight: FontWeight.w700,
														fontSize: 13,
													),
												),
												subtitle: Text(
													'${_formatDate(movement.createdAt)}${movement.note.isNotEmpty ? ' • ${movement.note}' : ''}',
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												trailing: Text(
													'Stock: ${movement.stockAfter}',
													style: const TextStyle(
														fontSize: 12,
														color: Color(0xFF475569),
													),
												),
											);
										}).toList(),
									),
					),
					const SizedBox(height: 16),
					Row(
						children: [
							Expanded(
								child: OutlinedButton.icon(
									onPressed: onEdit,
									icon: const Icon(Icons.edit_outlined),
									label: const Text('Edit'),
								),
							),
							const SizedBox(width: 8),
							Expanded(
								child: ElevatedButton.icon(
									onPressed: onStockIn,
									style: ElevatedButton.styleFrom(
										backgroundColor: const Color(0xFF16A34A),
										foregroundColor: Colors.white,
									),
									icon: const Icon(Icons.add_rounded),
									label: const Text('Stock In'),
								),
							),
							const SizedBox(width: 8),
							Expanded(
								child: ElevatedButton.icon(
									onPressed: onStockOut,
									style: ElevatedButton.styleFrom(
										backgroundColor: const Color(0xFFDC2626),
										foregroundColor: Colors.white,
									),
									icon: const Icon(Icons.remove_rounded),
									label: const Text('Stock Out'),
								),
							),
						],
					),
				],
			),
		);
	}

	static String _formatDate(DateTime date) {
		final d = date.day.toString().padLeft(2, '0');
		final m = date.month.toString().padLeft(2, '0');
		final y = date.year;
		return '$d/$m/$y';
	}
}

class _HeaderCard extends StatelessWidget {
	final ProductModel product;
	final String categoryName;
	final int stock;
	final String stockLabel;
	final Color stateColor;
	final Color stateBgColor;
	final ProductImageUrlUseCase _imageUrlUseCase = const ProductImageUrlUseCase();

	const _HeaderCard({
		required this.product,
		required this.categoryName,
		required this.stock,
		required this.stockLabel,
		required this.stateColor,
		required this.stateBgColor,
	});

	@override
	Widget build(BuildContext context) {
		final imageUrl = _imageUrlUseCase.resolveImageUrl(product.imageUrl);
		final proxyUrl = _imageUrlUseCase.proxyImageUrl(imageUrl);

		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: const Color(0xFFE2E8F0)),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					ClipRRect(
						borderRadius: BorderRadius.circular(12),
						child: Container(
							width: 88,
							height: 88,
							color: const Color(0xFFF1F5F9),
							child: imageUrl == null
									? const Icon(
											Icons.inventory_2_outlined,
											color: Color(0xFF94A3B8),
										)
									: _ProductDetailImage(
											primaryUrl: imageUrl,
											fallbackUrl: proxyUrl,
											productName: product.name,
										),
						),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									product.name,
									style: const TextStyle(
										fontSize: 16,
										fontWeight: FontWeight.w800,
										color: Color(0xFF0F172A),
									),
								),
								const SizedBox(height: 4),
								Text(
									categoryName,
									style: const TextStyle(color: Color(0xFF64748B)),
								),
								const SizedBox(height: 8),
								Wrap(
									spacing: 8,
									runSpacing: 8,
									children: [
										_Tag(label: stockLabel, fg: stateColor, bg: stateBgColor),
										_Tag(
											label: 'Stock: $stock',
											fg: const Color(0xFF475569),
											bg: const Color(0xFFF1F5F9),
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
}

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
						'Product detail image failed for ${widget.productName}: ${widget.primaryUrl} | $error. Trying proxy ${widget.fallbackUrl}',
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
					'Product detail image failed for ${widget.productName}: $_activeUrl | $error',
				);
				return const Icon(
					Icons.inventory_2_outlined,
					color: Color(0xFF94A3B8),
				);
			},
		);
	}
}

class _SectionCard extends StatelessWidget {
	final String title;
	final Widget child;

	const _SectionCard({required this.title, required this.child});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: const Color(0xFFE2E8F0)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						title,
						style: const TextStyle(
							fontSize: 13,
							fontWeight: FontWeight.w800,
							color: Color(0xFF334155),
							letterSpacing: 0.3,
						),
					),
					const SizedBox(height: 10),
					child,
				],
			),
		);
	}
}

class _InfoRow extends StatelessWidget {
	final String label;
	final String value;
	final Color? valueColor;
	final bool isLast;

	const _InfoRow({
		required this.label,
		required this.value,
		this.valueColor,
		this.isLast = false,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(vertical: 8),
			decoration: BoxDecoration(
				border: Border(
					bottom: isLast
							? BorderSide.none
							: const BorderSide(color: Color(0xFFF1F5F9)),
				),
			),
			child: Row(
				children: [
					Expanded(
						child: Text(
							label,
							style: const TextStyle(color: Color(0xFF64748B)),
						),
					),
					Text(
						value,
						style: TextStyle(
							fontWeight: FontWeight.w700,
							color: valueColor ?? const Color(0xFF0F172A),
						),
					),
				],
			),
		);
	}
}

class _Tag extends StatelessWidget {
	final String label;
	final Color fg;
	final Color bg;

	const _Tag({required this.label, required this.fg, required this.bg});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
			decoration: BoxDecoration(
				color: bg,
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				label,
				style: TextStyle(
					fontSize: 11,
					fontWeight: FontWeight.w700,
					color: fg,
				),
			),
		);
	}
}

enum _StockState {
	inStock(
		label: 'In Stock',
		color: Color(0xFF16A34A),
		bgColor: Color(0xFFDCFCE7),
	),
	low(
		label: 'Low Stock',
		color: Color(0xFFEA580C),
		bgColor: Color(0xFFFFEDD5),
	),
	out(
		label: 'Out of Stock',
		color: Color(0xFFDC2626),
		bgColor: Color(0xFFFEE2E2),
	);

	final String label;
	final Color color;
	final Color bgColor;

	const _StockState({
		required this.label,
		required this.color,
		required this.bgColor,
	});

	static _StockState fromDomain(ProductStockState state) {
		switch (state) {
			case ProductStockState.inStock:
				return _StockState.inStock;
			case ProductStockState.low:
				return _StockState.low;
			case ProductStockState.out:
				return _StockState.out;
		}
	}
}
