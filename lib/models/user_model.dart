// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  String accessToken;
  String tokenType;
  int expiresIn;
  int expiresAt;
  String refreshToken;
  User user;

  UserModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.expiresAt,
    required this.refreshToken,
    required this.user,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    accessToken: json["access_token"],
    tokenType: json["token_type"],
    expiresIn: json["expires_in"],
    expiresAt: json["expires_at"],
    refreshToken: json["refresh_token"],
    user: User.fromJson(json["user"]),
  );

  Map<String, dynamic> toJson() => {
    "access_token": accessToken,
    "token_type": tokenType,
    "expires_in": expiresIn,
    "expires_at": expiresAt,
    "refresh_token": refreshToken,
    "user": user.toJson(),
  };
}

class User {
  String id;
  String aud;
  String role;
  String email;
  DateTime emailConfirmedAt;
  String phone;
  DateTime lastSignInAt;
  AppMetadata appMetadata;
  Data userMetadata;
  List<Identity> identities;
  DateTime createdAt;
  DateTime updatedAt;
  bool isAnonymous;

  User({
    required this.id,
    required this.aud,
    required this.role,
    required this.email,
    required this.emailConfirmedAt,
    required this.phone,
    required this.lastSignInAt,
    required this.appMetadata,
    required this.userMetadata,
    required this.identities,
    required this.createdAt,
    required this.updatedAt,
    required this.isAnonymous,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    aud: json["aud"],
    role: json["role"],
    email: json["email"],
    emailConfirmedAt: DateTime.parse(json["email_confirmed_at"]),
    phone: json["phone"],
    lastSignInAt: DateTime.parse(json["last_sign_in_at"]),
    appMetadata: AppMetadata.fromJson(json["app_metadata"]),
    userMetadata: Data.fromJson(json["user_metadata"]),
    identities: List<Identity>.from(json["identities"].map((x) => Identity.fromJson(x))),
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    isAnonymous: json["is_anonymous"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "aud": aud,
    "role": role,
    "email": email,
    "email_confirmed_at": emailConfirmedAt.toIso8601String(),
    "phone": phone,
    "last_sign_in_at": lastSignInAt.toIso8601String(),
    "app_metadata": appMetadata.toJson(),
    "user_metadata": userMetadata.toJson(),
    "identities": List<dynamic>.from(identities.map((x) => x.toJson())),
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "is_anonymous": isAnonymous,
  };
}

class AppMetadata {
  String provider;
  List<String> providers;

  AppMetadata({
    required this.provider,
    required this.providers,
  });

  factory AppMetadata.fromJson(Map<String, dynamic> json) => AppMetadata(
    provider: json["provider"],
    providers: List<String>.from(json["providers"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "provider": provider,
    "providers": List<dynamic>.from(providers.map((x) => x)),
  };
}

class Identity {
  String identityId;
  String id;
  String userId;
  Data identityData;
  String provider;
  DateTime lastSignInAt;
  DateTime createdAt;
  DateTime updatedAt;
  String email;

  Identity({
    required this.identityId,
    required this.id,
    required this.userId,
    required this.identityData,
    required this.provider,
    required this.lastSignInAt,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
  });

  factory Identity.fromJson(Map<String, dynamic> json) => Identity(
    identityId: json["identity_id"],
    id: json["id"],
    userId: json["user_id"],
    identityData: Data.fromJson(json["identity_data"]),
    provider: json["provider"],
    lastSignInAt: DateTime.parse(json["last_sign_in_at"]),
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    email: json["email"],
  );

  Map<String, dynamic> toJson() => {
    "identity_id": identityId,
    "id": id,
    "user_id": userId,
    "identity_data": identityData.toJson(),
    "provider": provider,
    "last_sign_in_at": lastSignInAt.toIso8601String(),
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "email": email,
  };
}

class Data {
  String email;
  bool emailVerified;
  bool phoneVerified;
  String sub;

  Data({
    required this.email,
    required this.emailVerified,
    required this.phoneVerified,
    required this.sub,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    email: json["email"],
    emailVerified: json["email_verified"],
    phoneVerified: json["phone_verified"],
    sub: json["sub"],
  );

  Map<String, dynamic> toJson() => {
    "email": email,
    "email_verified": emailVerified,
    "phone_verified": phoneVerified,
    "sub": sub,
  };
}
