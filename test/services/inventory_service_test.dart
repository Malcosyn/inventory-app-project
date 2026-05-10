import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/models/inventory_model.dart';

void main() {
	group('InventoryService - Pure Logic', () {
		final service = InventoryService();

		group('validateInventoryUpdateInput', () {
			test('valid inputs → null', () {
				expect(service.validateInventoryUpdateInput(costPrice: 100, sellingPrice: 150, threshold: 5), isNull);
			});

			test('null or negative costPrice → error', () {
				expect(service.validateInventoryUpdateInput(costPrice: null, sellingPrice: 150, threshold: 5), isNotNull);
				expect(service.validateInventoryUpdateInput(costPrice: -1, sellingPrice: 150, threshold: 5), isNotNull);
			});

			test('null or negative sellingPrice → error', () {
				expect(service.validateInventoryUpdateInput(costPrice: 100, sellingPrice: null, threshold: 5), isNotNull);
				expect(service.validateInventoryUpdateInput(costPrice: 100, sellingPrice: -5, threshold: 5), isNotNull);
			});

			test('null or negative threshold → error', () {
				expect(service.validateInventoryUpdateInput(costPrice: 100, sellingPrice: 150, threshold: null), isNotNull);
				expect(service.validateInventoryUpdateInput(costPrice: 100, sellingPrice: 150, threshold: -2), isNotNull);
			});
		});

		group('validateInventoryCreateInput', () {
			test('valid inputs → null', () {
				expect(service.validateInventoryCreateInput(costPrice: 100, sellingPrice: 150, initialStock: 10, threshold: 5), isNull);
			});

			test('missing numeric fields → error', () {
				expect(service.validateInventoryCreateInput(costPrice: null, sellingPrice: 150, initialStock: 10, threshold: 5), isNotNull);
				expect(service.validateInventoryCreateInput(costPrice: 100, sellingPrice: null, initialStock: 10, threshold: 5), isNotNull);
				expect(service.validateInventoryCreateInput(costPrice: 100, sellingPrice: 150, initialStock: null, threshold: 5), isNotNull);
				expect(service.validateInventoryCreateInput(costPrice: 100, sellingPrice: 150, initialStock: 10, threshold: null), isNotNull);
			});

			test('negative numeric values → error', () {
				expect(service.validateInventoryCreateInput(costPrice: -1, sellingPrice: 150, initialStock: 10, threshold: 5), isNotNull);
				expect(service.validateInventoryCreateInput(costPrice: 100, sellingPrice: -2, initialStock: 10, threshold: 5), isNotNull);
				expect(service.validateInventoryCreateInput(costPrice: 100, sellingPrice: 150, initialStock: -3, threshold: 5), isNotNull);
				expect(service.validateInventoryCreateInput(costPrice: 100, sellingPrice: 150, initialStock: 10, threshold: -4), isNotNull);
			});
		});

		group('buildUpdatedInventory', () {
			final original = InventoryModel(
				id: 'i1',
				productId: 'p1',
				costPrice: 10000,
				sellingPrice: 15000,
				stockQuantity: 7,
				lowStockThreshold: 3,
				updatedAt: DateTime(2024,1,1),
				storeId: 1,
			);

			test('original null → returns null', () {
				final result = service.buildUpdatedInventory(original: null, costPrice: 20000, sellingPrice: 25000, threshold: 5);
				expect(result, isNull);
			});

			test('returns new InventoryModel with updated numeric fields and preserved ids', () {
				final result = service.buildUpdatedInventory(original: original, costPrice: 20000, sellingPrice: 25000, threshold: 5)!;
				expect(result.id, original.id);
				expect(result.productId, original.productId);
				expect(result.storeId, original.storeId);
				expect(result.stockQuantity, original.stockQuantity);
				expect(result.costPrice, 20000);
				expect(result.sellingPrice, 25000);
				expect(result.lowStockThreshold, 5);
				expect(result.updatedAt.isAfter(original.updatedAt), isTrue);
			});
		});
	});
}
