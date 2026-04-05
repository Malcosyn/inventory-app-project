
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final client = Supabase.instance.client;

  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'user',
        'store_id': '1'
      }
    );

    return response;
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    response;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('token', response.session!.accessToken);
  }
}
