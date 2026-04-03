import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  late TabController _tabController;
  bool _loading = false;
  bool _otpSent = false;
  bool _showPhoneLogin = false;
  String? _error;

  static const _gold = Color(0xFFCA8A04);
  static const _goldLight = Color(0xFFEAB308);
  static const _darkBg = Color(0xFF1C1917);
  static const _surfaceDark = Color(0xFF292524);
  static const _textLight = Color(0xFFFAFAF9);
  static const _muted = Color(0xFFA8A29E);
  static const _border = Color(0xFF44403C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() { _error = null; _showPhoneLogin = false; _otpSent = false; });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    setState(() { _loading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      if (_tabController.index == 1) {
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.raksichaiyo.customerapp://login-callback',
      );
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() { _error = 'Please enter your phone number'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.auth.signInWithOtp(phone: _phoneController.text.trim());
      setState(() { _otpSent = true; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.auth.verifyOTP(
        phone: _phoneController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _tabController.index == 1;

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // === TOP: Split Hero ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_surfaceDark, _darkBg],
                ),
              ),
              child: Stack(
                children: [
                  // Gold radial glow top-right
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [_gold.withValues(alpha: 0.12), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Decorative gold vertical bars on the right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          width: 3,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 3,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hero content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Now serving Nepal" badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.1),
                          border: Border.all(color: _gold.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Now serving Nepal',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Bold headline with gold accent
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _textLight,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(text: 'Raise a glass\nto '),
                            TextSpan(
                              text: 'great events',
                              style: TextStyle(color: _gold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Premium beverages, delivered to your celebration',
                        style: TextStyle(color: _muted, fontSize: 13.5, height: 1.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // === BOTTOM: Form Section ===
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                child: _showPhoneLogin
                    ? _buildPhoneForm()
                    : _buildEmailForm(isSignUp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm(bool isSignUp) {
    return Column(
      children: [
        // Tab switcher
        Container(
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: _darkBg,
            unselectedLabelColor: _muted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            dividerHeight: 0,
            tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
          ),
        ),
        const SizedBox(height: 24),

        // Full Name (sign up only)
        if (isSignUp) ...[
          _buildField(_nameController, 'Full Name'),
          const SizedBox(height: 12),
        ],

        _buildField(_emailController, 'Email address', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildField(_passwordController, 'Password', obscure: true),

        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Gold CTA button
        _buildGoldButton(
          label: isSignUp ? 'Create Account' : 'Sign In',
          onTap: _loading ? null : _submitEmail,
        ),
        const SizedBox(height: 22),

        // Divider
        Row(
          children: [
            Expanded(child: Container(height: 1, color: _border)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or continue with',
                style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 0.6),
              ),
            ),
            Expanded(child: Container(height: 1, color: _border)),
          ],
        ),
        const SizedBox(height: 18),

        // Social buttons
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Google',
                onTap: _signInWithGoogle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialButton(
                icon: Icons.phone_android_rounded,
                label: 'Phone',
                onTap: () => setState(() {
                  _showPhoneLogin = true;
                  _error = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Terms
        Text.rich(
          TextSpan(
            style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.5),
            children: [
              const TextSpan(text: 'By continuing, you agree to our '),
              TextSpan(
                text: 'Terms of Service',
                style: const TextStyle(color: _gold, fontWeight: FontWeight.w500),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: const TextStyle(color: _gold, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      children: [
        // Back to email
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() {
              _showPhoneLogin = false;
              _otpSent = false;
              _error = null;
            }),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: _gold, size: 18),
                SizedBox(width: 6),
                Text(
                  'Back to email login',
                  style: TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Phone Login',
          style: TextStyle(color: _textLight, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _otpSent
              ? 'Enter the OTP sent to your phone'
              : 'We\'ll send you a one-time verification code',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        if (!_otpSent) ...[
          _buildField(
            _phoneController,
            'Phone number (e.g. +977...)',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildGoldButton(label: 'Send OTP', onTap: _loading ? null : _sendOtp),
        ] else ...[
          _buildField(
            _otpController,
            'Enter OTP',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildGoldButton(label: 'Verify & Sign In', onTap: _loading ? null : _verifyOtp),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _sendOtp,
            child: const Text(
              'Resend OTP',
              style: TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textLight, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 14),
        filled: true,
        fillColor: _surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 2),
        ),
      ),
    );
  }

  Widget _buildGoldButton({required String label, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_gold, _goldLight]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Center(
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _darkBg),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.5,
                        color: _darkBg,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _surfaceDark,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _textLight, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
