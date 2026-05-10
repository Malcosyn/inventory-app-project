import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_project/models/product_model.dart';

void main() {
  group('ProductModel', () {
    final now = DateTime(2024, 5, 8, 10, 30);

    group('Constructor', () {
      test('creates ProductModel with required fields', () {
        final product = ProductModel(
          id: 'p1',
          storeId: 1,
          name: 'Beras',
          createdAt: now,
        );

        expect(product.id, 'p1');
        expect(product.storeId, 1);
        expect(product.name, 'Beras');
        expect(product.createdAt, now);
        expect(product.categoryId, isNull);
        expect(product.supplierId, isNull);
        expect(product.imageUrl, isNull);
        expect(product.barcode, isNull);
      });

      test('creates ProductModel with all fields', () {
        final product = ProductModel(
          id: 'p1',
          storeId: 1,
          categoryId: 5,
          supplierId: 's1',
          imageUrl: 'https://example.com/image.jpg',
          name: 'Beras Premium',
          barcode: '123456789',
          createdAt: now,
        );

        expect(product.id, 'p1');
        expect(product.storeId, 1);
        expect(product.categoryId, 5);
        expect(product.supplierId, 's1');
        expect(product.imageUrl, 'https://example.com/image.jpg');
        expect(product.name, 'Beras Premium');
        expect(product.barcode, '123456789');
        expect(product.createdAt, now);
      });
    });

    group('toJson', () {
      test('converts ProductModel to JSON with required fields', () {
        final product = ProductModel(
          id: 'p1',
          storeId: 1,
          name: 'Beras',
          createdAt: now,
        );

        final json = product.toJson();

        expect(json['id'], 'p1');
        expect(json['store_id'], 1);
        expect(json['name'], 'Beras');
        expect(json['created_at'], now.toIso8601String());
        expect(json['category_id'], isNull);
        expect(json['supplier_id'], isNull);
        expect(json['image_url'], isNull);
        expect(json['barcode'], isNull);
      });

      test('converts ProductModel to JSON with optional fields', () {
        final product = ProductModel(
          id: 'p1',
          storeId: 1,
          categoryId: 5,
          supplierId: 's1',
          imageUrl: 'https://example.com/image.jpg',
          name: 'Beras Premium',
          barcode: '123456789',
          createdAt: now,
        );

        final json = product.toJson();

        expect(json['id'], 'p1');
        expect(json['storeId'] ?? json['store_id'], 1);
        expect(json['category_id'], 5);
        expect(json['supplier_id'], 's1');
        expect(json['image_url'], 'https://example.com/image.jpg');
        expect(json['name'], 'Beras Premium');
        expect(json['barcode'], '123456789');
      });
    });

    group('fromJson', () {
      test('creates ProductModel from JSON with required fields', () {
        final json = {
          'id': 'p1',
          'store_id': 1,
          'name': 'Beras',
          'created_at': now.toIso8601String(),
        };

        final product = ProductModel.fromJson(json);

        expect(product.id, 'p1');
        expect(product.storeId, 1);
        expect(product.name, 'Beras');
        expect(product.categoryId, isNull);
        expect(product.supplierId, isNull);
        expect(product.imageUrl, isNull);
        expect(product.barcode, isNull);
      });

      test('creates ProductModel from JSON with optional fields', () {
        final json = {
          'id': 'p1',
          'store_id': 1,
          'category_id': 5,
          'supplier_id': 's1',
          'image_url': 'https://example.com/image.jpg',
          'name': 'Beras Premium',
          'barcode': '123456789',
          'created_at': now.toIso8601String(),
        };

        final product = ProductModel.fromJson(json);

        expect(product.id, 'p1');
        expect(product.storeId, 1);
        expect(product.categoryId, 5);
        expect(product.supplierId, 's1');
        expect(product.imageUrl, 'https://example.com/image.jpg');
        expect(product.name, 'Beras Premium');
        expect(product.barcode, '123456789');
      });

      test('handles null optional fields in JSON', () {
        final json = {
          'id': 'p1',
          'store_id': 1,
          'category_id': null,
          'supplier_id': null,
          'image_url': null,
          'name': 'Beras',
          'barcode': null,
          'created_at': now.toIso8601String(),
        };

        final product = ProductModel.fromJson(json);

        expect(product.categoryId, isNull);
        expect(product.supplierId, isNull);
        expect(product.imageUrl, isNull);
        expect(product.barcode, isNull);
      });

      test('handles empty string as null for optional fields', () {
        final json = {
          'id': 'p1',
          'store_id': 1,
          'supplier_id': '',
          'image_url': '',
          'name': 'Beras',
          'barcode': '',
          'created_at': now.toIso8601String(),
        };

        final product = ProductModel.fromJson(json);

        expect(product.supplierId, isNull);
        expect(product.imageUrl, isNull);
        expect(product.barcode, isNull);
      });

      test('converts string store_id to int', () {
        final json = {
          'id': 'p1',
          'store_id': '1',
          'name': 'Beras',
          'created_at': now.toIso8601String(),
        };

        final product = ProductModel.fromJson(json);

        expect(product.storeId, 1);
      });

      test('handles invalid created_at by using DateTime.now()', () {
        final json = {
          'id': 'p1',
          'store_id': 1,
          'name': 'Beras',
          'created_at': 'invalid-date',
        };

        final product = ProductModel.fromJson(json);

        expect(product.createdAt, isNotNull);
      });

      test('handles missing null optional fields', () {
        final json = {
          'id': 'p1',
          'store_id': 1,
          'name': 'Beras',
          'created_at': now.toIso8601String(),
        };

        final product = ProductModel.fromJson(json);

        expect(product.categoryId, isNull);
        expect(product.supplierId, isNull);
        expect(product.imageUrl, isNull);
        expect(product.barcode, isNull);
      });

      test('handles missing required fields gracefully', () {
        final json = {
          'id': 'p1',
          // Missing store_id
          'name': 'Beras',
          'created_at': now.toIso8601String(),
        };

        final product = ProductModel.fromJson(json);

        expect(product.storeId, 0); // Default value
      });
    });

    group('Serialization round-trip', () {
      test('toJson → fromJson preserves data', () {
        final original = ProductModel(
          id: 'p1',
          storeId: 1,
          categoryId: 5,
          supplierId: 's1',
          imageUrl: 'https://example.com/image.jpg',
          name: 'Beras Premium',
          barcode: '123456789',
          createdAt: now,
        );

        final json = original.toJson();
        final restored = ProductModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.storeId, original.storeId);
        expect(restored.categoryId, original.categoryId);
        expect(restored.supplierId, original.supplierId);
        expect(restored.imageUrl, original.imageUrl);
        expect(restored.name, original.name);
        expect(restored.barcode, original.barcode);
        expect(restored.createdAt, original.createdAt);
      });

      test('round-trip with null optional fields', () {
        final original = ProductModel(
          id: 'p1',
          storeId: 1,
          name: 'Beras',
          createdAt: now,
        );

        final json = original.toJson();
        final restored = ProductModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.storeId, original.storeId);
        expect(restored.name, original.name);
        expect(restored.categoryId, isNull);
        expect(restored.supplierId, isNull);
        expect(restored.imageUrl, isNull);
        expect(restored.barcode, isNull);
      });
    });

    group('Helper methods', () {
      test('_asString converts null to empty string', () {
        expect(ProductModel.fromJson({'id': null, 'store_id': 1, 'name': '', 'created_at': '2024-05-08'}).id, '');
      });

      test('_asString converts number to string', () {
        final json = {
          'id': 123,
          'store_id': 1,
          'name': 'Beras',
          'created_at': DateTime.now().toIso8601String(),
        };
        final product = ProductModel.fromJson(json);
        expect(product.id, '123');
      });

      test('_asInt converts string to int', () {
        final json = {
          'id': 'p1',
          'store_id': '42',
          'name': 'Beras',
          'created_at': DateTime.now().toIso8601String(),
        };
        final product = ProductModel.fromJson(json);
        expect(product.storeId, 42);
      });

      test('_asInt handles invalid string as 0', () {
        final json = {
          'id': 'p1',
          'store_id': 'invalid',
          'name': 'Beras',
          'created_at': DateTime.now().toIso8601String(),
        };
        final product = ProductModel.fromJson(json);
        expect(product.storeId, 0);
      });
    });
  });
}
