import 'dart:convert';

List<SupplierModel> supplierModelFromJson(String str) => List<SupplierModel>.from(json.decode(str).map((x) => SupplierModel.fromJson(x)));

String supplierModelToJson(List<SupplierModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SupplierModel {
  String id;
  String name;
  String phone;
  String address;
  int storeId;

  SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.storeId,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
    id: json["id"],
    name: json["name"],
    phone: json["phone"],
    address: json["address"],
    storeId: json["store_id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone": phone,
    "address": address,
    "store_id": storeId,
  };
}
