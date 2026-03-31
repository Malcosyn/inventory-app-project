

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

}