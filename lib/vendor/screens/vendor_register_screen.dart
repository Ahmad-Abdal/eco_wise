import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/categories.dart';
import '../../admin/screens/pick_location_screen.dart';
import '../../user/screens/sign_in_screen.dart';
import '../providers/vendor_auth_provider.dart';
import 'vendor_pending_screen.dart';

class VendorRegisterScreen extends ConsumerStatefulWidget {
  const VendorRegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VendorRegisterScreen> createState() => VendorRegisterScreenState();
}

class VendorRegisterScreenState extends ConsumerState<VendorRegisterScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final formKey = GlobalKey<FormState>();

  // Owner credentials
  final ownerNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final contactNumberController = TextEditingController();

  // Store information
  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final storeDescriptionController = TextEditingController();

  String storeType = 'physical'; // 'physical' or 'online'
  String? selectedCategory;
  File? storeImage;
  PickedLocation? pickedLocation;
  bool obscurePassword = true;

  @override
  void dispose() {
    ownerNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    contactNumberController.dispose();
    storeNameController.dispose();
    storeAddressController.dispose();
    storeDescriptionController.dispose();
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
      hintStyle: TextStyle(color: textGray.withOpacity(0.6), fontSize: 13),
      labelStyle: const TextStyle(color: textGray, fontWeight: FontWeight.w500, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: primaryGreen, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: sectionFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: outline(borderGray, 1),
      enabledBorder: outline(borderGray, 1),
      focusedBorder: outline(primaryGreen, 1.5),
      errorBorder: outline(Colors.redAccent, 1.2),
      focusedErrorBorder: outline(Colors.redAccent, 1.5),
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => storeImage = File(picked.path));
    }
  }

  Future<void> pickLocation() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (context) => const PickLocationScreen()),
    );
    if (result != null) {
      setState(() {
        pickedLocation = result;
        storeAddressController.text = result.address;
      });
    }
  }

  Future<void> handleRegister() async {
    if (!formKey.currentState!.validate()) return;

    if (storeImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a storefront or brand image')),
      );
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a primary store category')),
      );
      return;
    }

    final data = VendorRegistrationData(
      ownerName: ownerNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      contactNumber: contactNumberController.text.trim(),
      storeName: storeNameController.text.trim(),
      storeType: storeType,
      storeAddress: storeAddressController.text.trim(),
      latitude: pickedLocation?.latitude,
      longitude: pickedLocation?.longitude,
      storeCategory: selectedCategory!,
      storeDescription: storeDescriptionController.text.trim().isEmpty
          ? null
          : storeDescriptionController.text.trim(),
      storeImageFile: storeImage!,
    );

    final success = await ref.read(vendorAuthNotifierProvider.notifier).registerVendor(data);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VendorPendingScreen()),
      );
    } else {
      final error = ref.read(vendorAuthNotifierProvider).errorMessage ?? 'Registration failed';
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
          action: error.contains('already exists')
              ? SnackBarAction(
                  label: 'Sign In',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignInScreen(
                          prefillEmail: emailController.text.trim(),
                        ),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(vendorAuthNotifierProvider);

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text(
          'Register as Vendor',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: lightGreenBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.storefront_rounded, color: primaryGreen, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Join EcoWise to list your eco-friendly store & products. Applications are reviewed by our team.',
                          style: TextStyle(color: textDark, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1: Owner Information
                const Text(
                  '1. Vendor Account Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: ownerNameController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Full Name', icon: Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Email Address', icon: Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email address';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: textGray,
                      ),
                      onPressed: () => setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: contactNumberController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Contact Number', icon: Icons.phone_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter contact phone number' : null,
                ),
                const SizedBox(height: 28),

                // Section 2: Store Information
                const Text(
                  '2. Store Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                ),
                const SizedBox(height: 14),

                // Store Image Picker
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: sectionFill,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderGray),
                            image: storeImage != null
                                ? DecorationImage(image: FileImage(storeImage!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: storeImage == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: primaryGreen, size: 28),
                                    SizedBox(height: 6),
                                    Text('Store Photo', style: TextStyle(color: textGray, fontSize: 11)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Store or logo image (required)', style: TextStyle(color: textGray, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: storeNameController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Shop / Store Name', icon: Icons.storefront_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter store name' : null,
                ),
                const SizedBox(height: 14),

                // Store Category
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: buildInputDecoration(label: 'Store Category', icon: Icons.category_outlined),
                  dropdownColor: pureWhite,
                  style: const TextStyle(color: textDark),
                  hint: const Text('Select primary category'),
                  items: productCategories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v),
                  validator: (v) => v == null ? 'Select category' : null,
                ),
                const SizedBox(height: 14),

                // Store Type Selector
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => storeType = 'physical'),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: storeType == 'physical' ? lightGreenBg : pureWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: storeType == 'physical' ? primaryGreen : borderGray,
                              width: storeType == 'physical' ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: storeType == 'physical' ? primaryGreen : textGray,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Physical Store',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: storeType == 'physical' ? FontWeight.bold : FontWeight.w500,
                                    color: storeType == 'physical' ? primaryGreen : textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => storeType = 'online'),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: storeType == 'online' ? lightGreenBg : pureWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: storeType == 'online' ? primaryGreen : borderGray,
                              width: storeType == 'online' ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.language_rounded,
                                size: 18,
                                color: storeType == 'online' ? primaryGreen : textGray,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Online Store',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: storeType == 'online' ? FontWeight.bold : FontWeight.w500,
                                    color: storeType == 'online' ? primaryGreen : textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Store Address / Location
                TextFormField(
                  controller: storeAddressController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: storeType == 'physical' ? 'Store Address' : 'Website / Online Store URL',
                    icon: storeType == 'physical' ? Icons.location_on_outlined : Icons.link_rounded,
                    suffixIcon: storeType == 'physical'
                        ? IconButton(
                            icon: const Icon(Icons.map_outlined, color: primaryGreen),
                            tooltip: 'Pick on map',
                            onPressed: pickLocation,
                          )
                        : null,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (storeType == 'physical' ? 'Enter physical address' : 'Enter online store URL')
                      : null,
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: storeDescriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: 'Store Description (Eco focus, values, products sold)',
                    icon: Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: authState.isLoading ? null : handleRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Vendor Application',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
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
