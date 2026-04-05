import 'dart:math';

import 'package:inventory_app_project/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final _client = Supabase.instance.client;
  final String _tableName = 'orders';

  Future<OrderModel> getOrderById(String id) async {
    final response = await _client.from(_tableName).select().eq('id', id).single();
    return OrderModel.fromJson(response);
  }

  Future<List<OrderModel>> getOrdersByStoreId(int storeId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('store_id', storeId);
    return response.map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<void> createOrder(OrderModel order) async {
    await _client.from(_tableName).insert(order.toJson());
  }

  Future<void> createOrderEntry({
    required String productId,
    required int totalPrice,
    required int totalItem,
    required String status,
    required String unitType,
    required int storeId,
  }) async {
    await _client.from(_tableName).insert({
      'id': _generateUuidV4(),
      'product_id': productId,
      'total_price': totalPrice,
      'total_item': totalItem,
      'status': status,
      'unit_type': unitType,
      'store_id': storeId,
    });
  }

  Future<void> updateOrder(OrderModel order) async {
    await _client.from(_tableName).update(order.toJson()).eq('id', order.id);
  }

  Future<void> deleteOrder(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  Future<List<OrderModel>> getOrdersByProductId(String productId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('product_id', productId);
    return response.map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<List<OrderModel>> getOrdersByProductName(String name) async {
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

    final response = await _client
        .from(_tableName)
        .select()
        .inFilter('product_id', productIds);

    return response.map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    final response = await _client.from(_tableName).select().eq('status', status);
    return response.map((e) => OrderModel.fromJson(e)).toList();
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');

    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }
}
