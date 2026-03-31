import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class ProductService {
  final _client = Supabase.instance.client;
  final String _tableName = 'products';

  Future<void> createProduct(ProductModel product) async {
    await _client.from(_tableName).insert(product.toJson());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _client
        .from(_tableName)
        .update(product.toJson())
        .eq('id', product.id);
  }

  Future<void> deleteProduct(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  Future<ProductModel> getProductById(String id) async {
    final response = await _client.from(_tableName).select().eq('id', id).single();
    return ProductModel.fromJson(response);
  }

  Future<List<ProductModel>> getProductsByStoreId(int storeId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('store_id', storeId);
    return response.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> getProductsByCategoryId(int categoryId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('category_id', categoryId);
    return response.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> getProductsBySupplierId(String supplierId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false);
    return response.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> getProductsByBarcode(String barcode) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('barcode', barcode)
        .order('created_at', ascending: false);
    return response.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> getProductsByName(String name) async {
    final response = await _client
        .from(_tableName)
        .select()
        .ilike('name', '%$name%')
        .order('created_at', ascending: false);
    return response.map((e) => ProductModel.fromJson(e)).toList();
  }

}
