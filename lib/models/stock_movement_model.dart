import 'dart:convert';

List<StockMovementModel> stockMovementModelFromJson(String str) =>
    List<StockMovementModel>.from(
      json.decode(str).map((x) => StockMovementModel.fromJson(x)),
    );

String stockMovementModelToJson(List<StockMovementModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class StockMovementModel {
  String id;
  String productId;
  String type;
  int quantity;
  int stockAfter;
  String reason;
  String? note;
  DateTime createdAt;
  int storeId;

  StockMovementModel({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.stockAfter,
    required this.reason,
    required this.note,
    required this.createdAt,
    required this.storeId,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) =>
      StockMovementModel(
        id: json["id"],
        productId: json["product_id"],
        type: json["type"],
        quantity: json["quantity"],
        stockAfter: json["stock_after"],
        reason: (json["reason"] ?? '').toString(),
        note: json["note"] == null ? null : json["note"].toString(),
        createdAt: DateTime.parse(json["created_at"]),
        storeId: json["store_id"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "type": type,
    "quantity": quantity,
    "stock_after": stockAfter,
    "reason": reason,
    "note": note,
    "created_at": createdAt.toIso8601String(),
    "store_id": storeId,
  };
}
