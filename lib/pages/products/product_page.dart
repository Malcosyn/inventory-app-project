import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class ProductPage extends StatefulWidget {
	const ProductPage({super.key});

	@override
	State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
	static const int _defaultStoreId = 1;

	final ProductService _productService = ProductService();
	final TextEditingController _searchController = TextEditingController();

	bool _isLoading = true;
	String? _error;
	List<ProductModel> _products = const [];
	String _searchQuery = '';

	@override
	void initState() {
		super.initState();
		_loadProducts();
	}

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	Future<void> _loadProducts() async {
		setState(() {
			_isLoading = true;
			_error = null;
		});

		try {
			final products = await _productService.getProductsByStoreId(_defaultStoreId);
			if (!mounted) return;

			setState(() {
				_products = products;
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

	List<ProductModel> get _visibleProducts {
		final query = _searchQuery.trim().toLowerCase();
		if (query.isEmpty) return _products;

		return _products.where((product) {
			final byName = product.name.toLowerCase().contains(query);
			final byBarcode = (product.barcode ?? '').toLowerCase().contains(query);
			return byName || byBarcode;
		}).toList();
	}

	Widget _buildProductCard(ProductModel product) {
		final imageUrl = _productService.resolveImageUrl(product.imageUrl);

		return Container(
			margin: const EdgeInsets.only(bottom: 10),
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.borderColor),
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
						clipBehavior: Clip.antiAlias,
						child: imageUrl == null
								? const Icon(
										Icons.inventory_2_outlined,
										color: AppColors.textMedium,
										size: 22,
									)
								: Image.network(
										imageUrl,
										fit: BoxFit.cover,
										errorBuilder: (_, __, ___) {
											return const Icon(
												Icons.image_not_supported_outlined,
												color: AppColors.textMedium,
												size: 22,
											);
										},
									),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									product.name,
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
									style: const TextStyle(
										fontSize: 14,
										fontWeight: FontWeight.w700,
										color: AppColors.textDark,
									),
								),
								const SizedBox(height: 4),
								Text(
									product.barcode?.isNotEmpty == true
											? 'Barcode: ${product.barcode}'
											: 'No barcode',
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
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
		);
	}

	@override
	Widget build(BuildContext context) {
		final visible = _visibleProducts;

		return Scaffold(
			backgroundColor: AppColors.backgroundLight,
			body: SafeArea(
				child: RefreshIndicator(
					onRefresh: _loadProducts,
					child: ListView(
						padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
						children: [
							Row(
								children: [
									GestureDetector(
										onTap: () => Navigator.of(context).pop(),
										child: const Icon(Icons.arrow_back, color: AppColors.textDark),
									),
									const SizedBox(width: 12),
									const Expanded(
										child: Text(
											'Products',
											style: TextStyle(
												fontSize: 20,
												fontWeight: FontWeight.w800,
												color: AppColors.textDark,
											),
										),
									),
									IconButton(
										onPressed: _loadProducts,
										icon: const Icon(Icons.refresh_rounded),
									),
								],
							),
							const SizedBox(height: 12),
							TextField(
								controller: _searchController,
								onChanged: (value) => setState(() => _searchQuery = value),
								decoration: InputDecoration(
									hintText: 'Search product or barcode...',
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
							const SizedBox(height: 12),
							Text(
								'Total: ${visible.length}',
								style: const TextStyle(
									fontSize: 12,
									fontWeight: FontWeight.w700,
									color: AppColors.textMedium,
								),
							),
							const SizedBox(height: 10),
							if (_isLoading)
								const Padding(
									padding: EdgeInsets.only(top: 24),
									child: Center(child: CircularProgressIndicator()),
								)
							else if (_error != null)
								Container(
									padding: const EdgeInsets.all(12),
									decoration: BoxDecoration(
										color: AppColors.errorBg,
										borderRadius: BorderRadius.circular(12),
										border: Border.all(color: AppColors.errorBorder),
									),
									child: Text(
										'Failed to load products: $_error',
										style: const TextStyle(color: AppColors.errorDark),
									),
								)
							else if (visible.isEmpty)
								const Padding(
									padding: EdgeInsets.only(top: 30),
									child: Center(
										child: Text(
											'No products found.',
											style: TextStyle(color: AppColors.textMedium),
										),
									),
								)
							else
								...visible.map(_buildProductCard),
						],
					),
				),
			),
		);
	}
}
