import 'dart:convert';

List<CategoryModel> categoryModelFromJson(String str) => List<CategoryModel>.from(json.decode(str).map((x) => CategoryModel.fromJson(x)));

String categoryModelToJson(List<CategoryModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CategoryModel {
  int id;
  int storeId;
  String name;

  CategoryModel({
    required this.id,
    required this.storeId,
    required this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json["id"],
    storeId: json["store_id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "store_id": storeId,
    "name": name,
  };
}
