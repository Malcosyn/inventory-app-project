import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/stock_movement_service.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/secrets/supabase_secret.dart';

import '../models/product_model.dart';

class ProductService {
  final _client = Supabase.instance.client;
  final String _tableName = 'products';
  static const List<String> _storageBuckets = <String>[
    'PRODUCT-IMAGES',
    'product-images',
    'PRODUCT_BUCK',
    'product_buck',
    'products',
  ];

  Future<void> createProduct(ProductModel product) async {
    await _client.from(_tableName).insert(product.toJson());
  }

  Future<String> createProductEntry({
    required int storeId,
    required String name,
    int? categoryId,
    String? supplierId,
    String? imageUrl,
    String? barcode,
  }) async {
    final payload = <String, dynamic>{
      'store_id': storeId,
      'name': name,
      'category_id': categoryId,
      'supplier_id': supplierId,
      'image_url': imageUrl,
      'barcode': barcode,
      'created_at': DateTime.now().toIso8601String(),
    };

    payload.removeWhere((key, value) => value == null);

    final response = await _client
        .from(_tableName)
        .insert(payload)
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<void> createProductWithInventory({
    required int storeId,
    required String name,
    required int costPrice,
    required int sellingPrice,
    required int initialStock,
    required int threshold,
    int? categoryId,
    String? supplierId,
    String? imageUrl,
    String? barcode,
    required InventoryService inventoryService,
    required StockMovementService stockMovementService,
  }) async {
    final productId = await createProductEntry(
      storeId: storeId,
      name: name,
      categoryId: categoryId,
      supplierId: supplierId,
      imageUrl: imageUrl,
      barcode: barcode,
    );

    await inventoryService.createInventoryEntry(
      productId: productId,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stockQuantity: initialStock,
      lowStockThreshold: threshold,
      storeId: storeId,
    );

    if (initialStock > 0) {
      await stockMovementService.createStockMovementEntry(
        productId: productId,
        type: 'IN',
        quantity: initialStock,
        stockAfter: initialStock,
        reason: 'PURCHASE',
        note: 'Initial stock when adding item',
        storeId: storeId,
      );
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    await _client
        .from(_tableName)
        .update(product.toJson())
        .eq('id', product.id);
  }

  ProductDetailViewData buildDetailViewData(ProductModel product, InventoryModel? inventory) {
    final stock = inventory?.stockQuantity ?? 0;
    final threshold = inventory?.lowStockThreshold ?? 5;
    final costPrice = inventory?.costPrice ?? 0;
    final sellingPrice = inventory?.sellingPrice ?? 0;
    final margin = sellingPrice - costPrice;
    final stockValue = stock * costPrice;

    final ProductStockState state;
    if (stock <= 0) {
      state = ProductStockState.out;
    } else if (stock <= threshold) {
      state = ProductStockState.low;
    } else {
      state = ProductStockState.inStock;
    }

    return ProductDetailViewData(
      product: product,
      stock: stock,
      threshold: threshold,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      margin: margin,
      stockValue: stockValue,
      stockState: state,
    );
  }

  String? validateProductName(String name) {
    if (name.trim().isEmpty) {
      return 'Product name cannot be empty.';
    }
    return null;
  }

  ProductModel buildUpdatedProduct({
    required ProductModel original,
    required String name,
    required String barcode,
    required String imageUrl,
    required int? categoryId,
    required String? supplierId,
  }) {
    return ProductModel(
      id: original.id,
      storeId: original.storeId,
      categoryId: categoryId,
      supplierId: supplierId,
      imageUrl: imageUrl.trim().isEmpty ? null : imageUrl.trim(),
      name: name.trim(),
      barcode: barcode.trim().isEmpty ? null : barcode.trim(),
      createdAt: original.createdAt,
    );
  }

  Future<String> uploadProductImage({
    required Uint8List bytes,
    required String originalName,
  }) async {
    final ext = _resolveExtension(originalName);
    final fileName =
        'product_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}.$ext';
    final storagePath = 'uploads/$fileName';
    final errors = <String>[];

    for (final bucket in _storageBuckets) {
      try {
        final storage = _client.storage.from(bucket);
        await storage.uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFor(ext),
          ),
        );
        return storage.getPublicUrl(storagePath);
      } catch (e) {
        errors.add('$bucket: $e');
      }
    }

    throw Exception(
      'All upload buckets failed (${_storageBuckets.join(', ')}). ${errors.join(' | ')}',
    );
  }

  String? resolveImageUrl(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    final value = rawValue.trim();
    if (value.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    final base = SupabaseSecret.supabaseUrl;
    if (value.startsWith('/')) {
      final encodedPath = _encodePathSegments(value);
      return '$base/$encodedPath';
    }

    final encodedPath = _encodePathSegments(value);
    return '$base/storage/v1/object/public/$encodedPath';
  }

  String? proxyImageUrl(String? absoluteUrl) {
    if (absoluteUrl == null || absoluteUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(absoluteUrl);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    if (uri.host.contains('supabase.co')) {
      return null;
    }

    final fullWithoutScheme =
        '${uri.host}${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(fullWithoutScheme)}';
  }

  Future<void> deleteProduct(String id) async {
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

  String _resolveExtension(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';

    final ext = parts.last.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp') {
      return ext;
    }

    return 'jpg';
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _encodePathSegments(String path) {
    return path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
          try {
            return Uri.encodeComponent(Uri.decodeComponent(segment));
          } catch (_) {
            return Uri.encodeComponent(segment);
          }
        })
        .join('/');
  }

}

enum ProductStockState { inStock, low, out }

class ProductDetailViewData {
  final ProductModel product;
  final int stock;
  final int threshold;
  final int costPrice;
  final int sellingPrice;
  final int margin;
  final int stockValue;
  final ProductStockState stockState;

  const ProductDetailViewData({
    required this.product,
    required this.stock,
    required this.threshold,
    required this.costPrice,
    required this.sellingPrice,
    required this.margin,
    required this.stockValue,
    required this.stockState,
  });
}
