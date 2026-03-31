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
    id: json["id"],
    productId: json["product_id"],
    costPrice: json["cost_price"],
    sellingPrice: json["selling_price"],
    stockQuantity: json["stock_quantity"],
    lowStockThreshold: json["low_stock_threshold"],
    updatedAt: DateTime.parse(json["updated_at"]),
    storeId: json["store_id"],
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
}
