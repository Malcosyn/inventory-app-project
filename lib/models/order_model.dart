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
    id: json["id"],
    productId: json["product_id"],
    totalPrice: json["total_price"],
    totalItem: json["total_item"],
    status: json["status"],
    unitType: json["unit_type"],
    storeId: json["store_id"],
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
}
