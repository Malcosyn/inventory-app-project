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

  Future<void> updateInventory(InventoryModel inventory) async {
    await _client
        .from(_tableName)
        .update(inventory.toJson())
        .eq('id', inventory.id);
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
