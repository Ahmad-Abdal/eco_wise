import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_providers.dart';
import 'sign_up_screen.dart';
import 'user_home_shell.dart';
import 'profile_setup_screen.dart';
import 'onboarding_screen.dart';
import '../../admin/screens/admin_sign_in_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  final String? prefillEmail;

  const SignInScreen({Key? key, this.prefillEmail}) : super(key: key);

  @override
  ConsumerState<SignInScreen> createState() => SignInScreenState();
}

class SignInScreenState extends ConsumerState<SignInScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.prefillEmail ?? '');
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGray, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: primaryGreen, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: sectionFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderGray, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderGray, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryGreen, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  Future<void> handleSignIn() async {
    if (!formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) {
      final signedInEmail = Supabase.instance.client.auth.currentUser?.email?.toLowerCase();

      if (signedInEmail == AdminIdentity.email.toLowerCase()) {
        // Admin credentials used on the user-facing sign-in — block it.
        await Supabase.instance.client.auth.signOut();
        ref.read(authNotifierProvider.notifier).reset();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This is an admin account. Use "Login as admin" instead.')),
        );
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;

      // profile_completed (not "does a row exist") is the real signal —
      // signUp already creates a stub profiles row for the Users count,
      // so row-existence alone would skip setup on every first sign-in.
      var profileCompleted = false;
      var onboardingCompleted = false;
      if (userId != null) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('profile_completed, onboarding_completed')
            .eq('id', userId)
            .maybeSingle();
        profileCompleted = row?['profile_completed'] as bool? ?? false;
        onboardingCompleted = row?['onboarding_completed'] as bool? ?? false;
      }

      if (!mounted) return;

      // Three-tier gate: profile setup first, then onboarding, then
      // home — each only shown once per user, same pattern as
      // profile_completed above.
      Widget destination;
      if (!profileCompleted) {
        destination = const ProfileSetupScreen();
      } else if (!onboardingCompleted) {
        destination = const OnboardingScreen();
      } else {
        destination = const UserHomeShell();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: pureWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
               Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lightGreenBg,
                      border: Border.all(color: borderGray, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 54,
                      color: primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue your green journey.',
                  style: TextStyle(fontSize: 14, color: textGray, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Email', icon: Icons.mail_outline_rounded),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter your email';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: textGray,
                        size: 20,
                      ),
                      onPressed: () => setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter your password';
                    if (value.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to forgot password flow
                    },
                    child: const Text('Forgot password?', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: authState.isLoading ? null : handleSignIn,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Sign in', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: textGray, fontSize: 13)),
                    GestureDetector(
                      onTap: () async {
                        final email = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                        if (email != null && mounted) {
                          setState(() => emailController.text = email);
                        }
                      },
                      child: const Text('Sign up', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: borderGray)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: textGray, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: borderGray)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: sectionFill,
                      side: BorderSide(color: borderGray, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminSignInScreen()),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_outlined, color: textDark, size: 20),
                    label: const Text('Login as admin', style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 14)),
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