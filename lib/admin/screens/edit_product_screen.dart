import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_store_management_providers.dart';
import '../providers/add_product_providers.dart';
import '../providers/dashboard_providers.dart';
import '../../core/utils/eco_score.dart';
import '../../core/constants/categories.dart';
import '../../core/services/ai_api_service.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const EditProductScreen({Key? key, required this.productId}) : super(key: key);

  @override
  ConsumerState<EditProductScreen> createState() => EditProductScreenState();
}

class EditProductScreenState extends ConsumerState<EditProductScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? storeId;
  String? existingImageUrl;
  File? newImageFile;
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
  void initState() {
    super.initState();
    loadProduct();
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> loadProduct() async {
    try {
      final row = await Supabase.instance.client
          .from('products')
          .select()
          .eq('id', widget.productId)
          .maybeSingle();
      if (!mounted || row == null) return;
      setState(() {
        nameController.text = row['name'] as String? ?? '';
        brandController.text = row['brand'] as String? ?? '';
        descriptionController.text = row['description'] as String? ?? '';
        priceController.text = ((row['price'] as num?) ?? 0).toString();
        selectedCategory = row['category'] as String?;
        material = row['material'] as String? ?? material;
        recyclable = row['recyclable'] as String? ?? recyclable;
        reusable = row['reusable'] as String? ?? reusable;
        certification = row['certification'] as String? ?? certification;
        packaging = row['packaging'] as String? ?? packaging;
        existingImageUrl = row['image_url'] as String?;
        storeId = row['store_id'] as String?;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load product: $error')),
      );
    }
  }

  InputDecoration buildInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGray),
      prefixIcon: Icon(icon, color: primaryGreen),
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
      setState(() => newImageFile = File(picked.path));
    }
  }

  Future<void> handleSave() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
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
        await supabase.storage.from('product-images').upload(fileName, newImageFile!);
        imageUrl = supabase.storage.from('product-images').getPublicUrl(fileName);
      }

      await supabase.from('products').update({
        'name': nameController.text.trim(),
        'brand': brandController.text.trim().isEmpty ? null : brandController.text.trim(),
        'category': selectedCategory,
        'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'image_url': imageUrl,
        'material': material,
        'recyclable': recyclable,
        'reusable': reusable,
        'certification': certification,
        'packaging': packaging,
        'eco_score': liveEcoScore,
      }).eq('id', widget.productId);

      // AI: name/category/description may have changed, so refresh this
      // product's MiniLM embedding in the background (never blocks the save).
      unawaited(AiApiService.embedProduct(widget.productId));

      if (storeId != null) {
        ref.invalidate(adminStoreProductsProvider(storeId!));
      }
      ref.invalidate(dashboardStatsProvider);
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

  @override
  Widget build(BuildContext context) {
    final existingBrandsAsync = ref.watch(existingBrandsProvider);

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('Edit product', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
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
                              borderRadius: BorderRadius.circular(16),
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
                        decoration: buildInputDecoration(label: 'Product name', icon: Icons.inventory_2_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: buildInputDecoration(label: 'Category', icon: Icons.category_outlined),
                        dropdownColor: pureWhite,
                        style: const TextStyle(color: textDark),
                        items: productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                        error: (error, stack) => TextFormField(
                          controller: brandController,
                          style: const TextStyle(color: textDark),
                          decoration: buildInputDecoration(label: 'Brand (optional)', icon: Icons.label_outline),
                        ),
                        data: (existingBrands) => Autocomplete<String>(
                          initialValue: TextEditingValue(text: brandController.text),
                          optionsBuilder: (value) {
                            if (value.text.isEmpty) return existingBrands;
                            return existingBrands.where((b) => b.toLowerCase().contains(value.text.toLowerCase()));
                          },
                          onSelected: (selection) => brandController.text = selection,
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            controller.addListener(() => brandController.text = controller.text);
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
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
                      const SizedBox(height: 16),
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
                        decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Eco Score (auto-calculated)', style: TextStyle(color: textGray, fontWeight: FontWeight.w600)),
                            Text(
                              '$liveEcoScore',
                              style: const TextStyle(color: primaryGreen, fontSize: 20, fontWeight: FontWeight.bold),
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}