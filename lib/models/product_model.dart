import 'dart:convert';

List<ProductModel> productModelFromJson(String str) => List<ProductModel>.from(json.decode(str).map((x) => ProductModel.fromJson(x)));

String productModelToJson(List<ProductModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductModel {
  String id;
  int storeId;
  int categoryId;
  String supplierId;
  String imageUrl;
  String name;
  String barcode;
  DateTime createdAt;

  ProductModel({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.supplierId,
    required this.imageUrl,
    required this.name,
    required this.barcode,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json["id"],
    storeId: json["store_id"],
    categoryId: json["category_id"],
    supplierId: json["supplier_id"],
    imageUrl: json["image_url"],
    name: json["name"],
    barcode: json["barcode"],
    createdAt: DateTime.parse(json["created_at"]),
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
}
