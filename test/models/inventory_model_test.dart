import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_project/models/inventory_model.dart';

void main() {
	group('InventoryModel', () {
		final now = DateTime(2024, 5, 8, 10, 30);

		test('constructor and fields', () {
			final inv = InventoryModel(
				id: 'i1',
				productId: 'p1',
				costPrice: 10000,
				sellingPrice: 15000,
				stockQuantity: 5,
				lowStockThreshold: 2,
				updatedAt: now,
				storeId: 1,
			);

			expect(inv.id, 'i1');
			expect(inv.productId, 'p1');
			expect(inv.costPrice, 10000);
			expect(inv.sellingPrice, 15000);
			expect(inv.stockQuantity, 5);
			expect(inv.lowStockThreshold, 2);
			expect(inv.updatedAt, now);
			expect(inv.storeId, 1);
		});

		test('toJson and fromJson round-trip', () {
			final inv = InventoryModel(
				id: 'i1',
				productId: 'p1',
				costPrice: 10000,
				sellingPrice: 15000,
				stockQuantity: 5,
				lowStockThreshold: 2,
				updatedAt: now,
				storeId: 1,
			);

			final json = inv.toJson();
			final restored = InventoryModel.fromJson(json);

			expect(restored.id, inv.id);
			expect(restored.productId, inv.productId);
			expect(restored.costPrice, inv.costPrice);
			expect(restored.sellingPrice, inv.sellingPrice);
			expect(restored.stockQuantity, inv.stockQuantity);
			expect(restored.lowStockThreshold, inv.lowStockThreshold);
			expect(restored.storeId, inv.storeId);
			expect(restored.updatedAt, isNotNull);
		});

		test('handles string numeric values', () {
			final json = {
				'id': 'i1',
				'product_id': 'p1',
				'cost_price': '12345',
				'selling_price': '54321',
				'stock_quantity': '7',
				'low_stock_threshold': '3',
				'updated_at': now.toIso8601String(),
				'store_id': '2',
			};

			final inv = InventoryModel.fromJson(json);

			expect(inv.costPrice, 12345);
			expect(inv.sellingPrice, 54321);
			expect(inv.stockQuantity, 7);
			expect(inv.lowStockThreshold, 3);
			expect(inv.storeId, 2);
		});

		test('handles missing/invalid date gracefully', () {
			final json = {
				'id': 'i1',
				'product_id': 'p1',
				'cost_price': 10000,
				'selling_price': 15000,
				'stock_quantity': 5,
				'low_stock_threshold': 2,
				'updated_at': 'invalid-date',
				'store_id': 1,
			};

			final inv = InventoryModel.fromJson(json);
			expect(inv.updatedAt, isNotNull);
		});
	});
}
