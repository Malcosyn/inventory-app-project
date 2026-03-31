
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier_model.dart';

class SupplierService {
  final _client = Supabase.instance.client;
  final String _tableName = 'suppliers';

  Future<List<SupplierModel>> getSuppliers() async {
    final response = await _client.from(_tableName).select();
    return response.map((e) => SupplierModel.fromJson(e)).toList();
  }

  Future<void> createSupplier(SupplierModel supplier) async {
    await _client.from(_tableName).insert(supplier.toJson());
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    await _client.from(_tableName).update(supplier.toJson()).eq('id', supplier.id);
  }

  Future<void> deleteSupplier(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  Future<SupplierModel> getSupplierById(String id) async {
    final response = await _client.from(_tableName).select().eq('id', id).single();
    return SupplierModel.fromJson(response);
  }

  Future<List<SupplierModel>> getSuppliersByStoreId(int storeId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('store_id', storeId);
    return response.map((e) => SupplierModel.fromJson(e)).toList();
  }

}