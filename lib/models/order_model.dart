import 'dart:convert';

List<OrderModel> orderModelFromJson(String str) => List<OrderModel>.from(json.decode(str).map((x) => OrderModel.fromJson(x)));

String orderModelToJson(List<OrderModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OrderModel {
  String id;
  String productId;
  int totalPrice;
  int totalItem;
  String status;
  String unitType;
  int storeId;

  OrderModel({
    required this.id,
    required this.productId,
    required this.totalPrice,
    required this.totalItem,
    required this.status,
    required this.unitType,
    required this.storeId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: _asString(json["id"]),
    productId: _asString(json["product_id"]),
    totalPrice: _asInt(json["total_price"]),
    totalItem: _asInt(json["total_item"]),
    status: _asString(json["status"]),
    unitType: _asString(json["unit_type"]),
    storeId: _asInt(json["store_id"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "total_price": totalPrice,
    "total_item": totalItem,
    "status": status,
    "unit_type": unitType,
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
}
