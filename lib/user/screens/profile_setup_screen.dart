import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_providers.dart';
import 'onboarding_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => ProfileSetupScreenState();
}

class ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final cityController = TextEditingController();
  final bioController = TextEditingController();

  File? avatarFile;

  @override
  void dispose() {
    nameController.dispose();
    cityController.dispose();
    bioController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGray, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: primaryGreen, size: 20),
      filled: true,
      fillColor: sectionFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryGreen, width: 1.6),
      ),
    );
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => avatarFile = File(picked.path));
    }
  }

  Future<void> handleContinue() async {
    if (!formKey.currentState!.validate()) return;

    await ref.read(profileSetupNotifierProvider.notifier).saveProfile(
          name: nameController.text.trim(),
          avatarFile: avatarFile,
          city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
          bio: bioController.text.trim().isEmpty ? null : bioController.text.trim(),
        );

    if (!mounted) return;

    final state = ref.read(profileSetupNotifierProvider);
    if (state.isSaved) {
      // Onboarding hasn't run yet for a user who just finished profile
      // setup — go there next, not straight to the home shell.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(profileSetupNotifierProvider);

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
                const SizedBox(height: 4),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: lightGreenBg),
                  child: const Icon(Icons.eco_rounded, color: primaryGreen, size: 24),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Set up your profile',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tell us a little about you to get started.',
                  style: TextStyle(fontSize: 14, color: textGray.withOpacity(0.9), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                Center(
                  child: GestureDetector(
                    onTap: pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sectionFill,
                            border: Border.all(color: borderGray, width: 1.2),
                            image: avatarFile != null
                                ? DecorationImage(image: FileImage(avatarFile!), fit: BoxFit.cover)
                                : null,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: avatarFile == null
                              ? Icon(Icons.person_outline_rounded, color: textGray.withOpacity(0.7), size: 42)
                              : null,
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [primaryGreen, Color(0xFF2FA362)]),
                              border: Border.all(color: pureWhite, width: 2.5),
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text('Add a photo (optional)', style: TextStyle(color: textGray.withOpacity(0.8), fontSize: 12)),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Your name', icon: Icons.badge_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: cityController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'City (optional)', icon: Icons.location_city_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bioController,
                  maxLines: 2,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Short bio (optional)', icon: Icons.notes_outlined),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: setupState.isSaving ? null : handleContinue,
                    child: setupState.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Get started', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
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