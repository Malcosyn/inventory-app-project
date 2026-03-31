import 'dart:convert';

import 'package:inventory_app_project/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final client = Supabase.instance.client;

  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'user',
      }
    );

    return response;
  }

  Future<String> signInWithEmailAndPassword(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response.session!.accessToken;
  }
}
