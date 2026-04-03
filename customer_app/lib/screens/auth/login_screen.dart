import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        await authService.signUpWithEmail(_emailController.text.trim(), _passwordController.text, _nameController.text.trim());
      } else {
        await authService.signInWithEmail(_emailController.text.trim(), _passwordController.text);
      }
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFCA8A04);
    const darkBg = Color(0xFF1C1917);
    const surfaceDark = Color(0xFF292524);
    const textLight = Color(0xFFFAFAF9);
    const muted = Color(0xFFA8A29E);

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gold brand title
                const Text(
                  'RaksiChaiyo',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: gold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Beverages for every occasion',
                  style: TextStyle(color: muted, fontSize: 15),
                ),
                const SizedBox(height: 48),

                // Name field (sign up only)
                if (_isSignUp) _DarkTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  surfaceDark: surfaceDark,
                  gold: gold,
                  textLight: textLight,
                  muted: muted,
                ),
                if (_isSignUp) const SizedBox(height: 16),

                // Email field
                _DarkTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  surfaceDark: surfaceDark,
                  gold: gold,
                  textLight: textLight,
                  muted: muted,
                ),
                const SizedBox(height: 16),

                // Password field
                _DarkTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  surfaceDark: surfaceDark,
                  gold: gold,
                  textLight: textLight,
                  muted: muted,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                ],
                const SizedBox(height: 28),

                // Gold gradient Sign In / Sign Up button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCA8A04), Color(0xFFEAB308)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: gold.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _loading ? null : _submit,
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1C1917),
                                  ),
                                )
                              : Text(
                                  _isSignUp ? 'Sign Up' : 'Sign In',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF1C1917),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                  child: Text(
                    _isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Sign Up",
                    style: const TextStyle(color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dark-styled text field for the login screen
class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Color surfaceDark;
  final Color gold;
  final Color textLight;
  final Color muted;

  const _DarkTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    required this.surfaceDark,
    required this.gold,
    required this.textLight,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: textLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: muted),
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF44403C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF44403C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gold, width: 2),
        ),
      ),
    );
  }
}
