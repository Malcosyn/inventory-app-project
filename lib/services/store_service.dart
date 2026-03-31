import 'package:inventory_app_project/models/store_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreService {
  final _client = Supabase.instance.client;
  final String _tableName = 'stores';

  Future<void> createStore(StoreModel store) async {
    await _client.from(_tableName).insert(store.toJson());
  }

  Future<void> updateStore(StoreModel store) async {
    await _client.from(_tableName).update(store.toJson()).eq('id', store.id);
  }

  Future<void> deleteStore(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  Future<StoreModel> getStoreById(int id) async {
    final response = await _client.from(_tableName).select().eq('id', id).single();
    return StoreModel.fromJson(response);
  }

  Future<List<StoreModel>> getStoresByOwnerId(String ownerId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('owner_id', ownerId);
    return response.map((e) => StoreModel.fromJson(e)).toList();
  }
}
