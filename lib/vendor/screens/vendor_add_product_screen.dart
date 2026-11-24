import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../admin/providers/add_product_providers.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/eco_score.dart';
import '../providers/vendor_dashboard_providers.dart';

class VendorAddProductScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const VendorAddProductScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  ConsumerState<VendorAddProductScreen> createState() => VendorAddProductScreenState();
}

class VendorAddProductScreenState extends ConsumerState<VendorAddProductScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  File? productImage;
  String? selectedCategory;

  String material = 'Recycled material';
  String reusable = 'Yes';
  String recyclable = 'Yes';
  String certification = 'Certified organic/sustainable';
  String packaging = 'Low';

  int get liveEcoScore => EcoScoreCalculator.calculate(
        material: material,
        reusable: reusable,
        recyclable: recyclable,
        packaging: packaging,
        certification: certification,
      );

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGray, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryGreen),
      filled: true,
      fillColor: sectionFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGray)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGray)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
    );
  }

  Widget buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: buildInputDecoration(label: label, icon: icon),
      dropdownColor: pureWhite,
      style: const TextStyle(color: textDark),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => productImage = File(picked.path));
    }
  }

  Future<void> handleSave() async {
    if (!formKey.currentState!.validate()) return;
    if (productImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a product image')),
      );
      return;
    }
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    await ref.read(addProductNotifierProvider.notifier).saveProduct(
          storeId: widget.storeId,
          imageFile: productImage!,
          name: nameController.text.trim(),
          brand: brandController.text.trim().isEmpty ? null : brandController.text.trim(),
          category: selectedCategory!,
          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
          price: double.tryParse(priceController.text.trim()) ?? 0,
          material: material,
          recyclable: recyclable,
          reusable: reusable,
          certification: certification,
          packaging: packaging,
        );

    if (!mounted) return;

    final saveState = ref.read(addProductNotifierProvider);
    if (saveState.isSaved && saveState.savedProduct != null) {
      ref.invalidate(vendorStoreProductsProvider(widget.storeId));
      ref.invalidate(vendorMetricsProvider(widget.storeId));
      showQrDialog(saveState.savedProduct!.id!, saveState.savedProduct!.name);
    } else if (saveState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saveState.errorMessage!), backgroundColor: Colors.redAccent),
      );
    }
  }

  void showQrDialog(String productId, String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Product Saved', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 260,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(productName, style: const TextStyle(color: textGray)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderGray),
                  ),
                  child: QrImageView(
                    data: productId,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Print or save this QR code to attach to your physical store product.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textGray, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to products
            },
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(addProductNotifierProvider);
    final existingBrandsAsync = ref.watch(existingBrandsProvider);

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(
          'Add Product · ${widget.storeName}',
          style: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderGray),
                        image: productImage != null
                            ? DecorationImage(image: FileImage(productImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: productImage == null
                          ? const Icon(Icons.add_a_photo_outlined, color: primaryGreen, size: 32)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text('Product image (required)', style: TextStyle(color: textGray, fontSize: 12)),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Product Name', icon: Icons.inventory_2_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: buildInputDecoration(label: 'Category', icon: Icons.category_outlined),
                  dropdownColor: pureWhite,
                  style: const TextStyle(color: textDark),
                  hint: const Text('Select a category'),
                  items: productCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 16),

                existingBrandsAsync.when(
                  loading: () => TextFormField(
                    controller: brandController,
                    style: const TextStyle(color: textDark),
                    decoration: buildInputDecoration(label: 'Brand (optional)', icon: Icons.label_outline),
                  ),
                  error: (_, __) => TextFormField(
                    controller: brandController,
                    style: const TextStyle(color: textDark),
                    decoration: buildInputDecoration(label: 'Brand (optional)', icon: Icons.label_outline),
                  ),
                  data: (brands) => Autocomplete<String>(
                    optionsBuilder: (textVal) {
                      if (textVal.text.isEmpty) return brands;
                      return brands.where((b) => b.toLowerCase().contains(textVal.text.toLowerCase()));
                    },
                    onSelected: (sel) => brandController.text = sel,
                    fieldViewBuilder: (ctx, ctrl, fNode, _) {
                      ctrl.addListener(() => brandController.text = ctrl.text);
                      return TextFormField(
                        controller: ctrl,
                        focusNode: fNode,
                        style: const TextStyle(color: textDark),
                        decoration: buildInputDecoration(label: 'Brand (optional)', icon: Icons.label_outline),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Description (optional)', icon: Icons.notes_outlined),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Price', icon: Icons.attach_money_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter price';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Eco Attributes
                buildDropdown(
                  label: 'Material',
                  icon: Icons.eco_outlined,
                  value: material,
                  options: EcoScoreCalculator.materialScores.keys.toList(),
                  onChanged: (v) => setState(() => material = v!),
                ),
                const SizedBox(height: 16),

                buildDropdown(
                  label: 'Recyclable',
                  icon: Icons.recycling_outlined,
                  value: recyclable,
                  options: const ['Yes', 'Depends', 'No', 'Unknown'],
                  onChanged: (v) => setState(() => recyclable = v!),
                ),
                const SizedBox(height: 16),

                buildDropdown(
                  label: 'Reusable',
                  icon: Icons.autorenew_rounded,
                  value: reusable,
                  options: const ['Yes', 'No', 'Unknown'],
                  onChanged: (v) => setState(() => reusable = v!),
                ),
                const SizedBox(height: 16),

                buildDropdown(
                  label: 'Sustainable Certification',
                  icon: Icons.verified_outlined,
                  value: certification,
                  options: const [
                    'Certified organic/sustainable',
                    'Not certified',
                    'Explicitly conventional/non-organic',
                    'Unknown',
                  ],
                  onChanged: (v) => setState(() => certification = v!),
                ),
                const SizedBox(height: 16),

                buildDropdown(
                  label: 'Packaging',
                  icon: Icons.inventory_outlined,
                  value: packaging,
                  options: const ['Low', 'Medium', 'High', 'Unknown'],
                  onChanged: (v) => setState(() => packaging = v!),
                ),
                const SizedBox(height: 20),

                // Live Eco-Score Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightGreenBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Eco Score (auto-calculated)',
                        style: TextStyle(color: textDark, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$liveEcoScore',
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: saveState.isSaving ? null : handleSave,
                    child: saveState.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text('Save & Generate QR', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
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
