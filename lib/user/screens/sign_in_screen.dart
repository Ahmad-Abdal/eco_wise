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
    String? hint,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: textGray.withOpacity(0.6), fontSize: 14),
      labelStyle: const TextStyle(color: textGray, fontWeight: FontWeight.w500, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: textGray, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: pureWhite,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: outline(borderGray, 1),
      enabledBorder: outline(borderGray, 1),
      focusedBorder: outline(primaryGreen, 1.6),
      errorBorder: outline(Colors.redAccent, 1.2),
      focusedErrorBorder: outline(Colors.redAccent, 1.6),
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

  // ---------- UI pieces ----------

  Widget buildBrandHeader() {
    return Row(
      children: [
        const Icon(Icons.eco_rounded, color: primaryGreen, size: 36),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 1),
            Text(
              'EcoWise',
              style: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            SizedBox(height: 1),
            // Text(
            //   'Better Choices. A Greener Tomorrow.',
            //   style: TextStyle(color: textGray, fontSize: 11.5, fontWeight: FontWeight.w500),
            // ),
          ],
        ),
      ],
    );
  }

  Widget buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: borderGray, thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('OR', style: TextStyle(color: textGray, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        ),
        Expanded(child: Divider(color: borderGray, thickness: 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Background sits outside the Scaffold so it doesn't squash
    // when the keyboard opens.
    return Container(
      decoration: const BoxDecoration(
        color: pureWhite,
        image: DecorationImage(
          image: AssetImage('assets/images/signin_background.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 36),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildBrandHeader(),
                  const SizedBox(height: 56),

                  // Title kept to the left so it doesn't overlap the illustration.
                  FractionallySizedBox(
                    widthFactor: 0.62,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Welcome Back!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textDark, height: 1.15),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Sign in to continue your journey towards a more sustainable lifestyle.',
                          style: TextStyle(fontSize: 14, color: textGray, fontWeight: FontWeight.w500, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                    decoration: buildInputDecoration(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      icon: Icons.mail_outline_rounded,
                    ),
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
                    style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                    decoration: buildInputDecoration(
                      label: 'Password',
                      hint: 'Enter your password',
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
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sign in
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        disabledBackgroundColor: primaryGreen.withOpacity(0.7),
                        elevation: 4,
                        shadowColor: primaryGreen.withOpacity(0.35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: authState.isLoading ? null : handleSignIn,
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  buildOrDivider(),
                  const SizedBox(height: 26),

                  // Login as admin
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: pureWhite,
                        side: const BorderSide(color: borderGray, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminSignInScreen()),
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings_outlined, color: primaryGreen, size: 21),
                      label: const Text(
                        'Login as admin',
                        style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign up link
                  Center(
                    child: Column(
                      children: [
                        const Text("Don't have an account?", style: TextStyle(color: textGray, fontSize: 13)),
                        const SizedBox(height: 6),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Sign Up', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, color: primaryGreen, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}