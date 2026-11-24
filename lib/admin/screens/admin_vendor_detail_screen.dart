import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../vendor/models/vendor_application_model.dart';
import '../providers/admin_vendor_providers.dart';
import '../providers/dashboard_providers.dart';

class AdminVendorDetailScreen extends ConsumerStatefulWidget {
  final VendorApplication application;

  const AdminVendorDetailScreen({Key? key, required this.application}) : super(key: key);

  @override
  ConsumerState<AdminVendorDetailScreen> createState() => AdminVendorDetailScreenState();
}

class AdminVendorDetailScreenState extends ConsumerState<AdminVendorDetailScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  bool isActionLoading = false;

  String formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('MMM d, yyyy · h:mm a').format(dt);
  }

  Future<void> handleApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve Vendor?', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Text(
          'Approving will activate ${widget.application.ownerName}\'s vendor account and enable their store "${widget.application.storeName}".',
          style: const TextStyle(color: textGray, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isActionLoading = true);
    try {
      await ref.read(adminVendorControllerProvider).approveVendor(widget.application);
      ref.invalidate(allVendorApplicationsProvider);
      ref.invalidate(pendingVendorCountProvider);
      ref.invalidate(dashboardStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.application.storeName} has been approved!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving vendor: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> handleReject() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Application', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please specify why this application is rejected. The vendor will see this explanation upon signing in.',
                style: TextStyle(color: textGray, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: textDark),
                decoration: InputDecoration(
                  hintText: 'e.g. Products do not meet organic criteria, invalid business address...',
                  hintStyle: TextStyle(color: textGray.withOpacity(0.6), fontSize: 12),
                  filled: true,
                  fillColor: sectionFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderGray)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderGray)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Rejection reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (reason == null) return;

    setState(() => isActionLoading = true);
    try {
      await ref.read(adminVendorControllerProvider).rejectVendor(widget.application, reason);
      ref.invalidate(allVendorApplicationsProvider);
      ref.invalidate(pendingVendorCountProvider);
      ref.invalidate(dashboardStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application for ${widget.application.storeName} rejected.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting vendor: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: textGray, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    Color statusColor;
    Color statusBg;
    switch (app.status) {
      case 'approved':
        statusColor = primaryGreen;
        statusBg = lightGreenBg;
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusBg = const Color(0xFFFFEBEE);
        break;
      default:
        statusColor = const Color(0xFFE67E22);
        statusBg = const Color(0xFFFFF4E5);
    }

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('Vendor Application', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header
              if (app.storeImageUrl != null && app.storeImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    app.storeImageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: sectionFill,
                      child: const Center(child: Icon(Icons.storefront_rounded, size: 48, color: textGray)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Title & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.storeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                        const SizedBox(height: 4),
                        Text(app.storeCategory ?? 'General', style: const TextStyle(fontSize: 14, color: primaryGreen, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      app.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section: Owner Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sectionFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vendor Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 14),
                    buildInfoRow('Owner Name', app.ownerName, Icons.person_outline),
                    buildInfoRow('Email Address', app.email, Icons.email_outlined),
                    buildInfoRow('Contact Number', app.contactNumber, Icons.phone_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section: Store Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sectionFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Store Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 14),
                    buildInfoRow('Store Type', app.storeType.toUpperCase(), Icons.storefront_outlined),
                    buildInfoRow('Address / URL', app.storeAddress, Icons.location_on_outlined),
                    if (app.storeDescription != null && app.storeDescription!.isNotEmpty)
                      buildInfoRow('Description', app.storeDescription!, Icons.notes_outlined),
                    buildInfoRow('Applied On', formatDate(app.createdAt), Icons.calendar_today_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // If Rejected: show rejection box
              if (app.status == 'rejected' && app.rejectionReason != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.feedback_outlined, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Text('Rejection Reason Provided:', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(app.rejectionReason!, style: const TextStyle(color: textDark, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // Action Buttons
              if (app.status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isActionLoading ? null : handleReject,
                          child: const Text('Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isActionLoading ? null : handleApprove,
                          child: isActionLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                )
                              : const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // If already approved or rejected, allow admin to re-review if needed
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      side: const BorderSide(color: borderGray, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      if (app.status == 'approved') {
                        handleReject();
                      } else {
                        handleApprove();
                      }
                    },
                    child: Text(
                      app.status == 'approved' ? 'Revoke / Reject Vendor' : 'Re-Approve Vendor',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
