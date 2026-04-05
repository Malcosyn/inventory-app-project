import 'package:flutter/material.dart';
import 'package:inventory_app_project/pages/login_page.dart';
import 'package:inventory_app_project/services/auth_service.dart';

class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  static const Color _primary = Color(0xFFF2C287);
  static const Color _backgroundLight = Color(0xFFFAF7F2);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMedium = Color(0xFF64748B);
  static const Color _textLabel = Color(0xFF334155);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final AuthService authService = AuthService();

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
                _buildSignupCard(context, authService),
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
          child: const Icon(Icons.inventory_2_outlined, color: _primary, size: 48),
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

  Widget _buildSignupCard(BuildContext context, AuthService service) {
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Column(
              children: [
                Text(
                  'Create your account',
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
                  'Start managing inventory in minutes',
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
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _textDark, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'name@store.com',
              prefixIcon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Password'),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: _textDark, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'At least 6 characters',
              prefixIcon: Icons.lock_outline_rounded,
              suffix: Icon(
                Icons.visibility_outlined,
                color: Colors.blueGrey,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                service.signUpWithEmailAndPassword(
                  _emailController.text,
                  _passwordController.text,
                );
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF292524),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.person_add_alt_1_rounded,
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
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                );
              },
              child: const Text(
                'Already have an account? Log in',
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
    );
  }

  Widget _buildIllustrationBanner() {
    return Container(
      height: 120,
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
            (label) => GestureDetector(
              onTap: () {},
              child: Text(label, style: linkStyle),
            ),
          )
          .toList(),
    );
  }
}
