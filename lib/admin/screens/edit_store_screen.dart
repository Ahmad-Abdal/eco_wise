import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_store_management_providers.dart';
import '../providers/dashboard_providers.dart';
import 'pick_location_screen.dart';

class EditStoreScreen extends ConsumerStatefulWidget {
  final String storeId;

  const EditStoreScreen({Key? key, required this.storeId}) : super(key: key);

  @override
  ConsumerState<EditStoreScreen> createState() => EditStoreScreenState();
}

class EditStoreScreenState extends ConsumerState<EditStoreScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
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

  bool isLoading = true;
  bool isSaving = false;
  bool isDeleting = false;
  String? existingImageUrl;
  File? newImageFile;
  PickedLocation? pickedLocation;
  String storeType = 'physical';

  @override
  void initState() {
    super.initState();
    loadStore();
  }

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

  Future<void> loadStore() async {
    final store = await ref.read(adminStoreDetailProvider(widget.storeId).future);
    if (!mounted || store == null) return;
    setState(() {
      nameController.text = store.name;
      storeType = store.storeType;
      phoneController.text = store.phone ?? '';
      openingHoursController.text = store.openingHours ?? '';
      descriptionController.text = store.description ?? '';
      existingImageUrl = store.imageUrl;

      if (store.storeType == 'physical') {
        locationController.text = store.address ?? '';
        websiteController.text = store.website ?? '';
        if (store.latitude != null && store.longitude != null && store.address != null) {
          pickedLocation = PickedLocation(
            address: store.address!,
            latitude: store.latitude!,
            longitude: store.longitude!,
          );
        }
      } else {
        onlineLinkController.text = store.website ?? '';
      }

      isLoading = false;
    });
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGray)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGray)),
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
      setState(() => newImageFile = File(picked.path));
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

    setState(() => isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      var imageUrl = existingImageUrl;

      if (newImageFile != null) {
        final fileExtension = newImageFile!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        await supabase.storage.from('store-images').upload(fileName, newImageFile!);
        imageUrl = supabase.storage.from('store-images').getPublicUrl(fileName);
      }

      await supabase.from('stores').update({
        'name': nameController.text.trim(),
        'image_url': imageUrl,
        'store_type': storeType,
        'address': storeType == 'physical' ? pickedLocation!.address : null,
        'latitude': storeType == 'physical' ? pickedLocation!.latitude : null,
        'longitude': storeType == 'physical' ? pickedLocation!.longitude : null,
        'website': storeType == 'online'
            ? onlineLinkController.text.trim()
            : (websiteController.text.trim().isEmpty ? null : websiteController.text.trim()),
        'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        'opening_hours': openingHoursController.text.trim().isEmpty ? null : openingHoursController.text.trim(),
        'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      }).eq('id', widget.storeId);

      ref.invalidate(adminStoreDetailProvider(widget.storeId));
      ref.invalidate(storesOverviewProvider);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save changes: $error')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> handleDeleteStore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this store?', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete "${nameController.text}" and every product listed under it. '
          'Users will no longer be able to see this store or any of its products. This cannot be undone.',
          style: const TextStyle(color: textGray, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: textGray, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isDeleting = true);
    try {
      await deleteStoreAndProducts(widget.storeId);
      ref.invalidate(storesOverviewProvider);
      ref.invalidate(dashboardStatsProvider);

      if (!mounted) return;
      Navigator.pop(context); // close EditStoreScreen
      Navigator.pop(context); // close AdminStoreDetailScreen (store no longer exists)
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete store: $error')),
      );
      setState(() => isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('Edit store', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : SafeArea(
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
                              image: newImageFile != null
                                  ? DecorationImage(image: FileImage(newImageFile!), fit: BoxFit.cover)
                                  : (existingImageUrl != null && existingImageUrl!.isNotEmpty)
                                      ? DecorationImage(image: NetworkImage(existingImageUrl!), fit: BoxFit.cover)
                                      : null,
                            ),
                            child: (newImageFile == null && (existingImageUrl == null || existingImageUrl!.isEmpty))
                                ? const Icon(Icons.add_a_photo_outlined, color: textGray, size: 32)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text('Tap to change photo', style: TextStyle(color: textGray, fontSize: 12)),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: textDark),
                        decoration: buildInputDecoration(label: 'Store name', icon: Icons.storefront_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the store name' : null,
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: storeType,
                        decoration: buildInputDecoration(label: 'Store type', icon: Icons.category_outlined),
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
                                suffixIcon: const Icon(Icons.map_outlined, color: primaryGreen),
                              ),
                              validator: (v) => (storeType == 'physical' && pickedLocation == null)
                                  ? 'Pin the store location'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: websiteController,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(color: textDark),
                          decoration: buildInputDecoration(label: 'Website (optional)', icon: Icons.language_outlined),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: onlineLinkController,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(color: textDark),
                          decoration: buildInputDecoration(label: 'Website / store link', icon: Icons.language_outlined),
                          validator: (v) => (storeType == 'online' && (v == null || v.trim().isEmpty))
                              ? "Enter the store's website or link"
                              : null,
                        ),
                      ],
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: textDark),
                        decoration: buildInputDecoration(label: 'Phone (optional)', icon: Icons.call_outlined),
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
                        decoration: buildInputDecoration(label: 'Description (optional)', icon: Icons.notes_outlined),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isSaving ? null : handleSave,
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : const Text('Save changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 1.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isDeleting ? null : handleDeleteStore,
                          icon: isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                )
                              : const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          label: const Text('Delete store', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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