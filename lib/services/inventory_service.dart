import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final _client = Supabase.instance.client;
  final String _tableName = 'inventories';

  Future<List<InventoryModel>> getInventoriesByStoreId(int storeId) async {
    final productResponse = await _client
        .from('products')
        .select('id')
        .eq('store_id', storeId);

    final productIds = productResponse
        .map((product) => product['id'] as String)
        .toList();

    if (productIds.isEmpty) {
      return [];
    }

    final inventoryResponse = await _client
        .from(_tableName)
        .select()
        .inFilter('product_id', productIds);

    return inventoryResponse.map((e) => InventoryModel.fromJson(e)).toList();
  }

  Future<void> createInventory(InventoryModel inventory) async {
    await _client.from(_tableName).insert(inventory.toJson());
  }

  Future<void> createInventoryEntry({
    required String productId,
    required int costPrice,
    required int sellingPrice,
    required int stockQuantity,
    required int lowStockThreshold,
    required int storeId,
  }) async {
    await _client.from(_tableName).insert({
      'product_id': productId,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'updated_at': DateTime.now().toIso8601String(),
      'store_id': storeId,
    });
  }

  Future<void> updateInventory(InventoryModel inventory) async {
    await _client
        .from(_tableName)
        .update(inventory.toJson())
        .eq('id', inventory.id);
  }

  String? validateInventoryUpdateInput({
    required int? costPrice,
    required int? sellingPrice,
    required int? threshold,
  }) {
    if (costPrice == null || costPrice < 0) {
      return 'Invalid cost price.';
    }
    if (sellingPrice == null || sellingPrice < 0) {
      return 'Invalid selling price.';
    }
    if (threshold == null || threshold < 0) {
      return 'Invalid threshold.';
    }
    return null;
  }

  String? validateInventoryCreateInput({
    required int? costPrice,
    required int? sellingPrice,
    required int? initialStock,
    required int? threshold,
  }) {
    if (costPrice == null ||
        sellingPrice == null ||
        initialStock == null ||
        threshold == null) {
      return 'Numeric fields are required and must be valid.';
    }

    if (costPrice < 0 || sellingPrice < 0 || initialStock < 0 || threshold < 0) {
      return 'Numeric values cannot be negative.';
    }

    return null;
  }

  InventoryModel? buildUpdatedInventory({
    required InventoryModel? original,
    required int? costPrice,
    required int? sellingPrice,
    required int? threshold,
  }) {
    if (original == null) {
      return null;
    }

    return InventoryModel(
      id: original.id,
      productId: original.productId,
      costPrice: costPrice!,
      sellingPrice: sellingPrice!,
      stockQuantity: original.stockQuantity,
      lowStockThreshold: threshold!,
      updatedAt: DateTime.now(),
      storeId: original.storeId,
    );
  }

  Future<void> deleteInventory(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  Future<InventoryModel> getInventoryById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .single();
    return InventoryModel.fromJson(response);
  }

  Future<List<InventoryModel>> getInventoriesByProductName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return [];
    }

    final productResponse = await _client
        .from('products')
        .select('id')
        .ilike('name', '%$trimmedName%');

    final productIds = productResponse
        .map((product) => product['id'] as String)
        .toList();

    if (productIds.isEmpty) {
      return [];
    }

    final inventoryResponse = await _client
        .from(_tableName)
        .select()
        .inFilter('product_id', productIds);

    return inventoryResponse.map((e) => InventoryModel.fromJson(e)).toList();
  }
}
