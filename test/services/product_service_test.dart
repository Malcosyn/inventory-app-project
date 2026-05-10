import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/services/product_service.dart';

void main() {
  group('ProductService - Static Methods', () {
    group('validateProductName', () {
      test('empty string → error', () {
        expect(ProductService.validateProductName(''), isNotNull);
      });

      test('whitespace only → error', () {
        expect(ProductService.validateProductName('   '), isNotNull);
        expect(ProductService.validateProductName('\t'), isNotNull);
        expect(ProductService.validateProductName('\n'), isNotNull);
      });

      test('valid name → null (no error)', () {
        expect(ProductService.validateProductName('Beras'), isNull);
        expect(ProductService.validateProductName('Gula Pasir'), isNull);
        expect(ProductService.validateProductName('Minyak Goreng 2L'), isNull);
      });

      test('name with leading/trailing spaces → null after trim', () {
        expect(ProductService.validateProductName('  Beras  '), isNull);
        expect(ProductService.validateProductName('\tMinyak\n'), isNull);
      });

      test('single character name → null', () {
        expect(ProductService.validateProductName('A'), isNull);
      });

      test('very long name → null', () {
        final longName = 'A' * 500;
        expect(ProductService.validateProductName(longName), isNull);
      });
    });
  });

  group('ProductDetailViewData - Logic Testing', () {
    /// Helper: replicate the buildDetailViewData logic
    ProductDetailViewData buildDetailViewData(
      ProductModel product,
      InventoryModel? inventory,
    ) {
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

    group('stock state determination', () {
      final product = ProductModel(
        id: 'p1',
        storeId: 1,
        name: 'Gula',
        createdAt: DateTime.now(),
      );

      test('stock = 0 → ProductStockState.out', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: 0,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.stockState, ProductStockState.out);
      });

      test('stock < 0 (negative) → ProductStockState.out', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: -5,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.stockState, ProductStockState.out);
      });

      test('stock = threshold → ProductStockState.low', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: 5,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.stockState, ProductStockState.low);
      });

      test('stock < threshold → ProductStockState.low', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: 3,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.stockState, ProductStockState.low);
      });

      test('stock > threshold → ProductStockState.inStock', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: 20,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.stockState, ProductStockState.inStock);
      });

      test('null inventory → defaults: stock=0, threshold=5 → out', () {
        final result = buildDetailViewData(product, null);

        expect(result.stockState, ProductStockState.out);
        expect(result.stock, 0);
        expect(result.threshold, 5);
      });
    });

    group('financial calculations', () {
      final product = ProductModel(
        id: 'p1',
        storeId: 1,
        name: 'Gula',
        createdAt: DateTime.now(),
      );

      test('margin = sellingPrice - costPrice', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: 10,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.margin, 5000);
      });

      test('stockValue = stock * costPrice', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: 10,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.stockValue, 100000);
      });

      test('negative margin when selling < cost', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 20000,
          sellingPrice: 15000,
          stockQuantity: 10,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.margin, -5000);
      });

      test('zero margin when selling = cost', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 15000,
          sellingPrice: 15000,
          stockQuantity: 10,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.margin, 0);
      });

      test('stockValue = 0 when stock = 0', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: 0,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.stockValue, 0);
      });

      test('null inventory → defaults to 0 costs', () {
        final result = buildDetailViewData(product, null);

        expect(result.costPrice, 0);
        expect(result.sellingPrice, 0);
        expect(result.margin, 0);
        expect(result.stockValue, 0);
      });

      test('preserves ProductModel in result', () {
        final inventory = InventoryModel(
          id: 'i1',
          productId: 'p1',
          costPrice: 10000,
          sellingPrice: 15000,
          stockQuantity: 10,
          lowStockThreshold: 5,
          updatedAt: DateTime.now(),
          storeId: 1,
        );

        final result = buildDetailViewData(product, inventory);
        expect(result.product, product);
      });
    });
  });

  group('ProductDetailViewData', () {
    test('contains all required fields', () {
      final product = ProductModel(
        id: 'p1',
        storeId: 1,
        name: 'Beras',
        createdAt: DateTime.now(),
      );

      final data = ProductDetailViewData(
        product: product,
        stock: 100,
        threshold: 10,
        costPrice: 5000,
        sellingPrice: 7500,
        margin: 2500,
        stockValue: 500000,
        stockState: ProductStockState.inStock,
      );

      expect(data.product, product);
      expect(data.stock, 100);
      expect(data.threshold, 10);
      expect(data.costPrice, 5000);
      expect(data.sellingPrice, 7500);
      expect(data.margin, 2500);
      expect(data.stockValue, 500000);
      expect(data.stockState, ProductStockState.inStock);
    });
  });

  group('ProductStockState enum', () {
    test('has all three required states', () {
      expect(ProductStockState.inStock, isNotNull);
      expect(ProductStockState.low, isNotNull);
      expect(ProductStockState.out, isNotNull);
    });
  });
}
