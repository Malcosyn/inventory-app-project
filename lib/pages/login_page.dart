import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.isLoading = false,
    this.onLogin,
    this.onForgotPassword,
    this.onSignup,
  });

  final bool isLoading;
  final VoidCallback? onLogin;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onSignup;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  static const Color _primary = Color(0xFFF2C287);
  static const Color _backgroundLight = Color(0xFFFAF7F2);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMedium = Color(0xFF64748B);
  static const Color _textLabel = Color(0xFF334155);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: Column(
              children: [
                _buildLogoSection(),
                const SizedBox(height: 32),
                _buildLoginCard(context, widget.isLoading, authService),
                const SizedBox(height: 32),
                _buildFooterLinks(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: _primary,
            size: 48,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'StockFlow',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, bool isLoading, AuthService service) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Text(
                    'Smart Inventory for Your Store',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Efficiently manage your minimarket stock',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textMedium, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildIllustrationBanner(),
            const SizedBox(height: 24),
            _buildFieldLabel('Email Address'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) {
                  return 'Email wajib diisi';
                }
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(email)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
              style: const TextStyle(color: _textDark, fontSize: 14),
              decoration: _inputDecoration(
                hint: 'name@store.com',
                prefixIcon: Icons.mail_outline_rounded,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFieldLabel('Password'),
                GestureDetector(
                  onTap: widget.onForgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final password = (value ?? '').trim();
                if (password.isEmpty) return 'Password wajib diisi';
                return null;
              },
              style: const TextStyle(color: _textDark, fontSize: 14),
              decoration: _inputDecoration(
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.blueGrey.shade300,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    onChanged: isLoading
                        ? null
                        : (v) => setState(() => _rememberMe = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember this device',
                  style: TextStyle(color: _textMedium, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async{
                        if (_formKey.currentState!.validate()) {
                          service.signInWithEmailAndPassword(
                            _emailController.text,
                            _passwordController.text,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  shadowColor: _primary.withValues(alpha: 0.4),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Log In to Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF292524),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.login_rounded,
                            size: 20,
                            color: Color(0xFF292524),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFF1F5F9), thickness: 1),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: isLoading ? null : widget.onSignup,
                child: const Text(
                  'Belum punya akun? Sign up',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustrationBanner() {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withValues(alpha: 0.3)),
        image: const DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCSNQbnG71k8XzHn76UxkOztOsy7VtJkdlV7d4F66R9Qhs_t3DrJqIeg4nAGcenL49qudDYJJ4Kwm4asV61QzUv7tpLH6njWbsG7eM1jMXf7bQ4sdHEAL0vtPHjFAVxR1AyCkl2JYsK4bDK6mnYFP-458yub9CsyQZdw5NaD6wa23Ja1eg6rT8heQdfhssuFQ7fvt5CAZymsco7SJYMJ-8ZE_cG49lVpGPyD4uD5vJSxbT_rdjmR4zACSwYXKVebYjVWc-XjeMqAv8',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _textLabel,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(prefixIcon, color: Colors.blueGrey.shade300, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
    );
  }

  Widget _buildFooterLinks() {
    const linkStyle = TextStyle(color: Color(0xFF94A3B8), fontSize: 13);
    const links = ['Privacy Policy', 'Terms of Service', 'Help Center'];

    return Wrap(
      spacing: 24,
      children: links
          .map(
            (l) => GestureDetector(
              onTap: () {},
              child: Text(l, style: linkStyle),
            ),
          )
          .toList(),
    );
  }
}
