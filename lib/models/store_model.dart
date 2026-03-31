import 'dart:convert';

List<StoreModel> storeModelFromJson(String str) => List<StoreModel>.from(json.decode(str).map((x) => StoreModel.fromJson(x)));

String storeModelToJson(List<StoreModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class StoreModel {
  int id;
  String ownerId;
  String name;
  String phone;
  String address;
  bool isOpen24H;
  DateTime createdAt;

  StoreModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.phone,
    required this.address,
    required this.isOpen24H,
    required this.createdAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
    id: json["id"],
    ownerId: json["owner_id"],
    name: json["name"],
    phone: json["phone"],
    address: json["address"],
    isOpen24H: json["is_open_24h"],
    createdAt: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "owner_id": ownerId,
    "name": name,
    "phone": phone,
    "address": address,
    "is_open_24h": isOpen24H,
    "created_at": createdAt.toIso8601String(),
  };
}
