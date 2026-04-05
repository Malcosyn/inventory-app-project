import 'package:flutter/material.dart';
import 'package:inventory_app_project/pages/login_page.dart';
import 'package:inventory_app_project/secrets/supabase_secret.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
    url: SupabaseSecret.supabaseUrl,
    anonKey: SupabaseSecret.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory App',
      theme: AppTheme.light(),
      home: LoginPage(),
    );
  }
}