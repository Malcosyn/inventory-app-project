import 'dart:convert';

List<InventoryModel> inventoryModelFromJson(String str) => List<InventoryModel>.from(json.decode(str).map((x) => InventoryModel.fromJson(x)));

String inventoryModelToJson(List<InventoryModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class InventoryModel {
  String id;
  String productId;
  int costPrice;
  int sellingPrice;
  int stockQuantity;
  int lowStockThreshold;
  DateTime updatedAt;
  int storeId;

  InventoryModel({
    required this.id,
    required this.productId,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.updatedAt,
    required this.storeId,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
    id: _asString(json["id"]),
    productId: _asString(json["product_id"]),
    costPrice: _asInt(json["cost_price"]),
    sellingPrice: _asInt(json["selling_price"]),
    stockQuantity: _asInt(json["stock_quantity"]),
    lowStockThreshold: _asInt(json["low_stock_threshold"]),
    updatedAt: _asDateTime(json["updated_at"]),
    storeId: _asInt(json["store_id"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "cost_price": costPrice,
    "selling_price": sellingPrice,
    "stock_quantity": stockQuantity,
    "low_stock_threshold": lowStockThreshold,
    "updated_at": updatedAt.toIso8601String(),
    "store_id": storeId,
  };

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
