import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/store_detail_providers.dart';
Future<bool> showStoreRatingDialog(BuildContext context, {required String storeId, required String storeName}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _StoreRatingDialog(storeId: storeId, storeName: storeName),
      ) ??
      false;
}

class _StoreRatingDialog extends StatefulWidget {
  final String storeId;
  final String storeName;

  const _StoreRatingDialog({required this.storeId, required this.storeName});

  @override
  State<_StoreRatingDialog> createState() => _StoreRatingDialogState();
}

class _StoreRatingDialogState extends State<_StoreRatingDialog> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color star = Color(0xFFF2B705);

  int selectedStars = 0;
  final commentController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (selectedStars == 0) return;
    setState(() => isSubmitting = true);
    await submitStoreRating(storeId: widget.storeId, rating: selectedStars, comment: commentController.text);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: pureWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, color: lightGreenBg),
              child: const Icon(Icons.storefront_rounded, color: primaryGreen, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Rate ${widget.storeName}', textAlign: TextAlign.center,
                style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('How was your visit?', style: TextStyle(color: textGray.withOpacity(0.8), fontSize: 13)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => selectedStars = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      starIndex <= selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: star,
                      size: 34,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: commentController,
              maxLines: 3,
              style: const TextStyle(color: textDark, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share a quick comment (optional)',
                hintStyle: TextStyle(color: textGray.withOpacity(0.7), fontSize: 12.5),
                filled: true,
                fillColor: lightGreenBg.withOpacity(0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: (selectedStars == 0 || isSubmitting) ? null : submit,
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Rating', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context, false),
              child: Text('Skip for now', style: TextStyle(color: textGray.withOpacity(0.8), fontSize: 13)),
            ),
          ],
        ),
      ),
    ),
    );
  }
}