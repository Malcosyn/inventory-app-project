import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/product_model.dart';

enum ProductStockState { inStock, low, out }

class ProductDetailViewData {
  final ProductModel product;
  final int stock;
  final int threshold;
  final int costPrice;
  final int sellingPrice;
  final int margin;
  final int stockValue;
  final ProductStockState stockState;

  const ProductDetailViewData({
    required this.product,
    required this.stock,
    required this.threshold,
    required this.costPrice,
    required this.sellingPrice,
    required this.margin,
    required this.stockValue,
    required this.stockState,
  });
}

class ProductDetailUseCase {
  const ProductDetailUseCase();

  ProductDetailViewData build(ProductModel product, InventoryModel? inventory) {
    final stock = inventory?.stockQuantity ?? 0;
    final threshold = inventory?.lowStockThreshold ?? 5;
    final costPrice = inventory?.costPrice ?? 0;
    final sellingPrice = inventory?.sellingPrice ?? 0;
    final margin = sellingPrice - costPrice;
    final stockValue = stock * costPrice;

    final ProductStockState state;
    if (stock <= 0) {
      state = ProductStockState.out;
    } else if (stock <= threshold) {
      state = ProductStockState.low;
    } else {
      state = ProductStockState.inStock;
    }

    return ProductDetailViewData(
      product: product,
      stock: stock,
      threshold: threshold,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      margin: margin,
      stockValue: stockValue,
      stockState: state,
    );
  }
}
