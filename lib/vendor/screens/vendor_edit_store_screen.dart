import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../admin/models/store.dart';
import '../../admin/screens/pick_location_screen.dart';
import '../providers/vendor_dashboard_providers.dart';

class VendorEditStoreScreen extends ConsumerStatefulWidget {
  final Store store;

  const VendorEditStoreScreen({Key? key, required this.store}) : super(key: key);

  @override
  ConsumerState<VendorEditStoreScreen> createState() => VendorEditStoreScreenState();
}

class VendorEditStoreScreenState extends ConsumerState<VendorEditStoreScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController locationController;
  late final TextEditingController phoneController;
  late final TextEditingController openingHoursController;
  late final TextEditingController websiteController;
  late final TextEditingController descriptionController;

  File? newImageFile;
  PickedLocation? pickedLocation;
  late String storeType;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.store.name);
    locationController = TextEditingController(text: widget.store.address ?? '');
    phoneController = TextEditingController(text: widget.store.phone ?? '');
    openingHoursController = TextEditingController(text: widget.store.openingHours ?? '');
    websiteController = TextEditingController(text: widget.store.website ?? '');
    descriptionController = TextEditingController(text: widget.store.description ?? '');
    storeType = widget.store.storeType;

    if (widget.store.latitude != null && widget.store.longitude != null && widget.store.address != null) {
      pickedLocation = PickedLocation(
        address: widget.store.address!,
        latitude: widget.store.latitude!,
        longitude: widget.store.longitude!,
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    phoneController.dispose();
    openingHoursController.dispose();
    websiteController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickNewImage() async {
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

    setState(() => isSaving = true);
    try {
      await ref.read(vendorStoreControllerProvider).updateStore(
            storeId: widget.store.id,
            name: nameController.text.trim(),
            storeType: storeType,
            address: storeType == 'physical'
                ? (pickedLocation?.address ?? locationController.text.trim())
                : null,
            latitude: storeType == 'physical' ? pickedLocation?.latitude : null,
            longitude: storeType == 'physical' ? pickedLocation?.longitude : null,
            phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
            openingHours: openingHoursController.text.trim().isEmpty
                ? null
                : openingHoursController.text.trim(),
            website: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            newImageFile: newImageFile,
          );

      if (!mounted) return;
      ref.invalidate(currentVendorStoreProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store information updated successfully'),
          backgroundColor: primaryGreen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update store: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> showRequestDeletionDialog() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Request Store Removal', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Per platform guidelines, removing your store requires Admin Approval. When approved, your store and listed products will be permanently removed.',
              style: TextStyle(color: textGray, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: textDark, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Reason for removal *',
                labelStyle: const TextStyle(color: textGray),
                hintText: 'e.g. Business closing, moving location, rebranding...',
                filled: true,
                fillColor: sectionFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGray)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGray)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: TextStyle(color: textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason for removal')),
                );
                return;
              }
              Navigator.pop(dialogCtx, true);
            },
            child: const Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(vendorStoreControllerProvider).requestStoreDeletion(
              widget.store.id,
              reasonController.text.trim(),
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store removal request submitted to Admin for review.'),
            backgroundColor: primaryGreen,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit removal request: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> handleCancelDeletionRequest() async {
    try {
      await ref.read(vendorStoreControllerProvider).cancelStoreDeletion(widget.store.id);
      if (!mounted) return;
      ref.invalidate(currentVendorStoreProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store removal request has been cancelled.'),
          backgroundColor: primaryGreen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ref.invalidate(currentVendorStoreProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel request: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGray, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryGreen),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: sectionFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderGray)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderGray)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('Edit Store Profile', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Deletion request banner if active
                if (store.deletionRequested) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEEBA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 22),
                            SizedBox(width: 8),
                            Text('Removal Request Pending', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF856404), fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You requested Admin to remove this store.\nReason: "${store.deletionReason ?? 'No reason provided'}"',
                          style: const TextStyle(color: Color(0xFF856404), fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF856404),
                            side: const BorderSide(color: Color(0xFF856404)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: handleCancelDeletionRequest,
                          child: const Text('Cancel Removal Request', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Store Image Picker
                Center(
                  child: GestureDetector(
                    onTap: pickNewImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: sectionFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderGray),
                        image: newImageFile != null
                            ? DecorationImage(image: FileImage(newImageFile!), fit: BoxFit.cover)
                            : (store.imageUrl.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(store.imageUrl), fit: BoxFit.cover)
                                : null,
                      ),
                      child: newImageFile == null && store.imageUrl.isEmpty
                          ? const Icon(Icons.add_a_photo_outlined, color: primaryGreen, size: 32)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text('Tap to change storefront photo', style: TextStyle(color: textGray, fontSize: 12)),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Store Name', icon: Icons.storefront_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter store name' : null,
                ),
                const SizedBox(height: 16),

                // Store Type Toggle
                const Text('Store Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => storeType = 'physical'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: storeType == 'physical' ? lightGreenBg : sectionFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: storeType == 'physical' ? primaryGreen : borderGray,
                              width: storeType == 'physical' ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_mall_directory_rounded,
                                  color: storeType == 'physical' ? primaryGreen : textGray, size: 20),
                              const SizedBox(width: 8),
                              Text('Physical Store',
                                  style: TextStyle(
                                    color: storeType == 'physical' ? primaryGreen : textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => storeType = 'online'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: storeType == 'online' ? lightGreenBg : sectionFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: storeType == 'online' ? primaryGreen : borderGray,
                              width: storeType == 'online' ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.language_rounded,
                                  color: storeType == 'online' ? primaryGreen : textGray, size: 20),
                              const SizedBox(width: 8),
                              Text('Online Store',
                                  style: TextStyle(
                                    color: storeType == 'online' ? primaryGreen : textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location Picker if Physical
                if (storeType == 'physical') ...[
                  GestureDetector(
                    onTap: pickLocation,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: locationController,
                        maxLines: 2,
                        style: const TextStyle(color: textDark),
                        decoration: buildInputDecoration(
                          label: 'Store Address (Tap to pin on map)',
                          icon: Icons.location_on_outlined,
                          suffixIcon: const Icon(Icons.map_outlined, color: primaryGreen),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Contact Phone
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Contact Phone', icon: Icons.phone_outlined),
                ),
                const SizedBox(height: 16),

                // Opening Hours
                TextFormField(
                  controller: openingHoursController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: 'Opening Hours (e.g. 9:00 AM - 8:00 PM)',
                    icon: Icons.access_time_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Website
                TextFormField(
                  controller: websiteController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(
                    label: storeType == 'online' ? 'Online Store Link / Website' : 'Website / Social Link',
                    icon: Icons.language_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Store Description', icon: Icons.notes_outlined),
                ),
                const SizedBox(height: 28),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
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
                            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 36),

                // Danger Zone: Store Removal
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFD2D2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                          SizedBox(width: 8),
                          Text('Danger Zone', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Want to remove your store? Store deletion requires Admin review. Once approved, your store and all associated products will be permanently removed.',
                        style: TextStyle(color: textDark, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      if (!store.deletionRequested)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.warning_amber_rounded, size: 18),
                          label: const Text('Request Store Removal', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: showRequestDeletionDialog,
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textDark,
                            side: const BorderSide(color: borderGray, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('Cancel Removal Request', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: handleCancelDeletionRequest,
                        ),
                    ],
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
