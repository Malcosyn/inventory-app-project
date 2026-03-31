import 'package:inventory_app_project/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  final _client = Supabase.instance.client;
  final String _tableName = 'categories';

  Future<CategoryModel> getCategoryById(int id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .single();
    return CategoryModel.fromJson(response);
  }

  Future<List<CategoryModel>> getCategoriesByStoreId(int storeId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('store_id', storeId);
    return response.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<void> createCategory(CategoryModel category) async {
    await _client.from(_tableName).insert(category.toJson());
  }

  Future<void> deleteCategory(int id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

}
