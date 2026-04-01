import 'dart:convert';

List<SupplierModel> supplierModelFromJson(String str) => List<SupplierModel>.from(json.decode(str).map((x) => SupplierModel.fromJson(x)));

String supplierModelToJson(List<SupplierModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SupplierModel {
  String id;
  String name;
  String phone;
  String address;
  String? email;
  int storeId;

  SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.email,
    required this.storeId,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
    id: json["id"],
    name: json["name"],
    phone: json["phone"],
    address: json["address"],
    email: json["email"],
    storeId: json["store_id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone": phone,
    "address": address,
    "email": email,
    "store_id": storeId,
  };
}
