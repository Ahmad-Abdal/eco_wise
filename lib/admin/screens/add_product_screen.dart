import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/add_product_providers.dart';
import '../providers/dashboard_providers.dart';
import '../../core/utils/eco_score.dart';
import '../../core/constants/categories.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const AddProductScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  ConsumerState<AddProductScreen> createState() => AddProductScreenState();
}

class AddProductScreenState extends ConsumerState<AddProductScreen> {
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
      labelStyle: const TextStyle(color: textGray),
      prefixIcon: Icon(icon, color: primaryGreen),
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
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget buildBrandAutocomplete(List<String> existingBrands) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return existingBrands;
        return existingBrands.where(
          (brand) => brand.toLowerCase().contains(textEditingValue.text.toLowerCase()),
        );
      },
      onSelected: (selection) => brandController.text = selection,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Keep our own controller in sync so handleSave can read it
        // whether the admin picked a suggestion or just typed freely.
        controller.addListener(() => brandController.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: textDark),
          decoration: buildInputDecoration(
            label: 'Brand (optional — pick existing or type new)',
            icon: Icons.label_outline,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: pureWhite,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options.map((brand) {
                  return ListTile(
                    title: Text(brand, style: const TextStyle(color: textDark)),
                    onTap: () => onSelected(brand),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
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
      ref.invalidate(dashboardStatsProvider);
      showQrDialog(saveState.savedProduct!.id!, saveState.savedProduct!.name);
    } else if (saveState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saveState.errorMessage!)),
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
        title: const Text(
          'Product saved',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
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
                const SizedBox(height: 8),
                Text(
                  'Print or save this QR code and attach it to the product.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textGray.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to store detail
            },
            child: const Text('Done', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
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
          'Add product · ${widget.storeName}',
          style: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
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
                        borderRadius: BorderRadius.circular(16),
                        image: productImage != null
                            ? DecorationImage(image: FileImage(productImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: productImage == null
                          ? const Icon(Icons.add_a_photo_outlined, color: textGray, size: 32)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Product image (required)', style: TextStyle(color: textGray, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Product name', icon: Icons.inventory_2_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 18),
                existingBrandsAsync.when(
                  loading: () => TextFormField(
                    controller: brandController,
                    style: const TextStyle(color: textDark),
                    decoration: buildInputDecoration(label: 'Brand (optional)', icon: Icons.label_outline),
                  ),
                  error: (error, stack) => TextFormField(
                    controller: brandController,
                    style: const TextStyle(color: textDark),
                    decoration: buildInputDecoration(label: 'Brand (optional)', icon: Icons.label_outline),
                  ),
                  data: (existingBrands) => buildBrandAutocomplete(existingBrands),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: textDark),
                  decoration: buildInputDecoration(label: 'Description (optional)', icon: Icons.notes_outlined),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 18),
                buildDropdown(
                  label: 'Material',
                  icon: Icons.eco_outlined,
                  value: material,
                  options: EcoScoreCalculator.materialScores.keys.toList(),
                  onChanged: (v) => setState(() => material = v!),
                ),
                const SizedBox(height: 18),
                buildDropdown(
                  label: 'Recyclable',
                  icon: Icons.recycling_outlined,
                  value: recyclable,
                  options: const ['Yes', 'Depends', 'No', 'Unknown'],
                  onChanged: (v) => setState(() => recyclable = v!),
                ),
                const SizedBox(height: 18),
                buildDropdown(
                  label: 'Reusable',
                  icon: Icons.autorenew_rounded,
                  value: reusable,
                  options: const ['Yes', 'No', 'Unknown'],
                  onChanged: (v) => setState(() => reusable = v!),
                ),
                const SizedBox(height: 18),
                buildDropdown(
                  label: 'Sustainable Certification / Organic',
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
                const SizedBox(height: 18),
                buildDropdown(
                  label: 'Packaging',
                  icon: Icons.inventory_outlined,
                  value: packaging,
                  options: const ['Low', 'Medium', 'High', 'Unknown'],
                  onChanged: (v) => setState(() => packaging = v!),
                ),
                const SizedBox(height: 20),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: saveState.isSaving ? null : handleSave,
                    child: saveState.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Save product', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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