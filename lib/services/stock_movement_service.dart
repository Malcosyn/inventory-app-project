import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/stock_movement_model.dart';

class StockMovementService {
  final _client = Supabase.instance.client;
  final String _tableName = 'stock_movement';

  Future<void> createStockMovementEntry({
    required String productId,
    required String type,
    required int quantity,
    required int stockAfter,
    String? reason,
    required String note,
    required int storeId,
  }) async {
    await _client.from(_tableName).insert({
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'stock_after': stockAfter,
      'reason': reason,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
      'store_id': storeId,
    });
  }

  Future<void> createStockMovement(StockMovementModel stockMovement) async {
    await _client.from(_tableName).insert(stockMovement.toJson());
  }

  Future<void> updateStockMovement(StockMovementModel stockMovement) async {
    await _client
        .from(_tableName)
        .update(stockMovement.toJson())
        .eq('id', stockMovement.id);
  }

  Future<void> deleteStockMovement(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  Future<StockMovementModel> getStockMovementById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .single();
    return StockMovementModel.fromJson(response);
  }

  Future<List<StockMovementModel>> getStockMovements() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);
    return response.map((e) => StockMovementModel.fromJson(e)).toList();
  }

  Future<List<StockMovementModel>> getStockMovementsByStoreId(
    int storeId,
  ) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return response.map((e) => StockMovementModel.fromJson(e)).toList();
  }

  Future<List<StockMovementModel>> getStockMovementsByProductId(
    String productId,
  ) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return response.map((e) => StockMovementModel.fromJson(e)).toList();
  }

  Future<List<StockMovementModel>> getStockMovementsByType(String type) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('type', type)
        .order('created_at', ascending: false);
    return response.map((e) => StockMovementModel.fromJson(e)).toList();
  }
}
