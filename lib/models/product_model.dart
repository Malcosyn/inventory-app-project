import 'dart:convert';

List<ProductModel> productModelFromJson(String str) => List<ProductModel>.from(json.decode(str).map((x) => ProductModel.fromJson(x)));

String productModelToJson(List<ProductModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductModel {
  String id;
  int storeId;
  int? categoryId;
  String? supplierId;
  String? imageUrl;
  String name;
  String? barcode;
  DateTime createdAt;

  ProductModel({
    required this.id,
    required this.storeId,
    this.categoryId,
    this.supplierId,
    this.imageUrl,
    required this.name,
    this.barcode,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: _asString(json["id"]),
    storeId: _asInt(json["store_id"]),
    categoryId: _asIntOrNull(json["category_id"]),
    supplierId: _asStringOrNull(json["supplier_id"]),
    imageUrl: _asStringOrNull(json["image_url"]),
    name: _asString(json["name"]),
    barcode: _asStringOrNull(json["barcode"]),
    createdAt: _asDateTime(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "store_id": storeId,
    "category_id": categoryId,
    "supplier_id": supplierId,
    "image_url": imageUrl,
    "name": name,
    "barcode": barcode,
    "created_at": createdAt.toIso8601String(),
  };

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _asStringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
