import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../admin/screens/admin_sign_in_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpScreen> createState() => SignUpScreenState();
}

class SignUpScreenState extends ConsumerState<SignUpScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
      border: outline(borderGray, 1),
      enabledBorder: outline(borderGray, 1),
      focusedBorder: outline(primaryGreen, 1.6),
      errorBorder: outline(Colors.redAccent, 1.2),
      focusedErrorBorder: outline(Colors.redAccent, 1.6),
    );
  }

  Future<void> handleSignUp() async {
    if (!formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).signUp(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) {
      Navigator.pop(context, emailController.text.trim());
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
        const Icon(Icons.eco_rounded, color: primaryGreen, size: 34),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 1),
            Text(
              'EcoWise',
              style: TextStyle(color: textDark, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3),
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
          image: AssetImage('assets/images/signup_background.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 8, 26, 36),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: textDark),
                  ),
                  const SizedBox(height: 4),
                  buildBrandHeader(),
                  const SizedBox(height: 30),

                  // Title kept to the left so it doesn't overlap the illustration.
                  FractionallySizedBox(
                    widthFactor: 0.62,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Create Your Account',
                          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: textDark, height: 1.15),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Join our community and start making more sustainable choices today.',
                          style: TextStyle(fontSize: 14, color: textGray, fontWeight: FontWeight.w500, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                    decoration: buildInputDecoration(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
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
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                    decoration: buildInputDecoration(
                      label: 'Password',
                      hint: 'Create a strong password',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: textGray,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    style: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
                    decoration: buildInputDecoration(
                      label: 'Confirm Password',
                      hint: 'Confirm your password',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: textGray,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),

                  // Create account
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
                      onPressed: authState.isLoading ? null : handleSignUp,
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
                                Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildOrDivider(),
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 26),

                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(color: textGray, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Sign In', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: primaryGreen, size: 17),
                          ],
                        ),
                      ),
                    ],
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