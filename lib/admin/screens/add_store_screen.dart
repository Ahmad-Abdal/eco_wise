import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/add_store_providers.dart';
import '../providers/dashboard_providers.dart';
import 'pick_location_screen.dart';

class AddStoreScreen extends ConsumerStatefulWidget {
  const AddStoreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddStoreScreen> createState() => AddStoreScreenState();
}

class AddStoreScreenState extends ConsumerState<AddStoreScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final onlineLinkController = TextEditingController();
  final phoneController = TextEditingController();
  final websiteController = TextEditingController();
  final openingHoursController = TextEditingController();
  final descriptionController = TextEditingController();

  File? storeImage;
  PickedLocation? pickedLocation;

  // 'physical' → map picker for a real address.
  // 'online'   → a single link field replaces the map entirely.
  String storeType = 'physical';

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    onlineLinkController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    openingHoursController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGray),
      prefixIcon: Icon(icon, color: primaryGreen),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: sectionFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
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
        locationController.text = result.address;
      });
    }
  }

  Future<void> handleSave() async {
    if (!formKey.currentState!.validate()) return;

    if (storeImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a store image')),
      );
      return;
    }
    if (storeType == 'physical' && pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pin the store location')),
      );
      return;
    }
    if (storeType == 'online' && onlineLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the store's website or link")),
      );
      return;
    }

    await ref.read(addStoreNotifierProvider.notifier).saveStore(
          imageFile: storeImage!,
          name: nameController.text.trim(),
          storeType: storeType,
          address: storeType == 'physical' ? pickedLocation!.address : null,
          latitude: storeType == 'physical' ? pickedLocation!.latitude : null,
          longitude: storeType == 'physical' ? pickedLocation!.longitude : null,
          website: storeType == 'online'
              ? onlineLinkController.text.trim()
              : (websiteController.text.trim().isEmpty ? null : websiteController.text.trim()),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          openingHours: openingHoursController.text.trim().isEmpty
              ? null
              : openingHoursController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        );

    if (!mounted) return;

    final saveState = ref.read(addStoreNotifierProvider);
    if (saveState.isSaved) {
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(storesOverviewProvider);
      Navigator.pop(context);
    } else if (saveState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saveState.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(addStoreNotifierProvider);

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text(
          'Add store',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: sectionFill,
                        shape: BoxShape.circle,
                        image: storeImage != null
                            ? DecorationImage(
                                image: FileImage(storeImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: storeImage == null
                          ? const Icon(
                              Icons.add_a_photo_outlined,
                              color: textGray,
                              size: 32,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Store image (required)',
                    style: TextStyle(color: textGray, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: 'Store name',
                    icon: Icons.storefront_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the store name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: storeType,
                  decoration: buildInputDecoration(
                    label: 'Store type',
                    icon: Icons.category_outlined,
                  ),
                  dropdownColor: pureWhite,
                  style: const TextStyle(color: textDark),
                  items: const [
                    DropdownMenuItem(value: 'physical', child: Text('Physical store')),
                    DropdownMenuItem(value: 'online', child: Text('Online store')),
                  ],
                  onChanged: (value) => setState(() => storeType = value ?? 'physical'),
                ),
                const SizedBox(height: 18),
                if (storeType == 'physical') ...[
                  GestureDetector(
                    onTap: pickLocation,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: locationController,
                        style: const TextStyle(color: textDark),
                        decoration: buildInputDecoration(
                          label: 'Location',
                          icon: Icons.location_on_outlined,
                          suffixIcon: const Icon(
                            Icons.map_outlined,
                            color: primaryGreen,
                          ),
                        ),
                        validator: (value) {
                          if (storeType == 'physical' && pickedLocation == null) {
                            return 'Pin the store location on the map';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: websiteController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(color: textDark),
                    decoration: buildInputDecoration(
                      label: 'Website (optional)',
                      icon: Icons.language_outlined,
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: onlineLinkController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(color: textDark),
                    decoration: buildInputDecoration(
                      label: 'Website / store link',
                      icon: Icons.language_outlined,
                    ),
                    validator: (value) {
                      if (storeType == 'online' && (value == null || value.trim().isEmpty)) {
                        return "Enter the store's website or link";
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 18),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: 'Phone (optional)',
                    icon: Icons.call_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: openingHoursController,
                  maxLines: 2,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: storeType == 'physical' ? 'Opening hours (optional)' : 'Hours of operation (optional)',
                    icon: Icons.schedule_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: 'Eco-friendly description (optional)',
                    icon: Icons.eco_outlined,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: saveState.isSaving ? null : handleSave,
                    child: saveState.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save store',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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