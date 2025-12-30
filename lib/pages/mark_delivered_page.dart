import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/delivery_task_model.dart';
import '../receipt_entry.dart';

class MarkDeliveredPage extends StatefulWidget {
  final DeliveryTask task;

  const MarkDeliveredPage({super.key, required this.task});

  @override
  State<MarkDeliveredPage> createState() => _MarkDeliveredPageState();
}

class _MarkDeliveredPageState extends State<MarkDeliveredPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _personNameController = TextEditingController();

  bool _isDelivered = true; // true = Delivered, false = Return
  bool _otpVerified = false;
  // Store picked image files. Accepts File, XFile or String paths for robustness.
  List<dynamic> _uploadedPhotos = [];
  String _paymentMode = 'Credit'; // Cash or Credit
  // Delivery status when in Delivered mode
  String _deliveryStatus = 'Delivered'; // options: Delivered, Part delivered, Not delivered

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _paymentMode = widget.task.paymentType == PaymentType.cash ? 'Cash' : 'Credit';
  }

  @override
  void dispose() {
    _otpController.dispose();
    _remarkController.dispose();
    _personNameController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall() async {
    // Use party's phone from task or mock number
    final phoneUrl = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    }
  }

  Future<void> _requestOTP() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP sent to registered mobile number'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _verifyOTP() {
    if (_otpController.text.length == 6) {
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(ctx, 'camera')),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(ctx, 'gallery')),
            ListTile(leading: const Icon(Icons.close), title: const Text('Cancel'), onTap: () => Navigator.pop(ctx, null)),
          ],
        ),
      ),
    );

    if (choice == null) return;

    // Request permissions according to choice and handle denied/permanentlyDenied cases
    try {
      if (choice == 'camera') {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          await _showPermissionDialog('Camera permission is permanently denied. Please enable it from app settings.');
          return;
        }
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission is required')));
          return;
        }
      } else {
        // Gallery: request photos (iOS) or storage (Android)
        if (Platform.isAndroid) {
          var status = await Permission.storage.request();
          if (status.isPermanentlyDenied) {
            await _showPermissionDialog('Storage permission is permanently denied. Please enable it from app settings.');
            return;
          }
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission is required to pick images')));
            return;
          }
        } else {
          final status = await Permission.photos.request();
          if (status.isPermanentlyDenied) {
            await _showPermissionDialog('Photos permission is permanently denied. Please enable it from app settings.');
            return;
          }
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos permission is required')));
            return;
          }
        }
      }
    } catch (e) {
      // If permission_handler throws on some platforms, show a helpful message
      debugPrint('Permission request failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission check failed: $e')));
      return;
    }

    try {
      XFile? picked;
      if (choice == 'camera') {
        picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600);
      } else {
        picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
      }

      if (picked != null) {
        final file = File(picked.path);
        setState(() {
          if (_uploadedPhotos.length < 2) _uploadedPhotos.add(file);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo ${_uploadedPhotos.length} added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _uploadedPhotos.removeAt(index);
    });
  }

  /// Normalize a dynamic list (List<String> | List<File> | List<XFile>) into internal List<File>
  void setUploadedPhotosFromDynamicList(dynamic list) {
    if (list is! List) return;
    final normalized = <File>[];
    for (final item in list) {
      if (item is File) normalized.add(item);
      else if (item is XFile) normalized.add(File(item.path));
      else if (item is String) normalized.add(File(item));
    }
    setState(() {
      _uploadedPhotos = normalized;
    });
  }

  /// Convenience: accept List<String> paths and convert to File objects
  void setUploadedPhotoPaths(List<String> paths) {
    final files = paths.where((p) => p.isNotEmpty).map((p) => File(p)).toList();
    setState(() => _uploadedPhotos = files);
  }

  /// Show a dialog explaining a permanently denied permission and allow opening app settings
  Future<void> _showPermissionDialog(String message) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission required'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Open Settings')),
        ],
      ),
    );

    if (open == true) {
      await openAppSettings();
    }
  }

  void _submitDelivery() {
    if (_formKey.currentState!.validate()) {
      if (_isDelivered) {
        // If outcome is Not delivered, treat as a return/undelivered flow
        if (_deliveryStatus == 'Not delivered') {
          if (_remarkController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter reason for non-delivery'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _completeReturn();
          return;
        }

        // Delivered or Part delivered flow
        if (!_otpVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify OTP first'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_personNameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter person name who received goods'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // For Part delivered we may allow 1 photo minimum; keep existing requirement of 2 for full delivered
        final minPhotos = _deliveryStatus == 'Part delivered' ? 1 : 2;
        if (_uploadedPhotos.length < minPhotos) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please upload $minPhotos photo(s) (Bill and Goods)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Check if COD (Cash on Delivery)
        if (_paymentMode == 'Cash') {
          // Open Receipt Entry
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateReceiptScreen(),
            ),
          ).then((_) {
            // After receipt entry, mark as delivered
            _completeDelivery();
          });
        } else {
          _completeDelivery();
        }
      } else {
        // Return flow (explicit Return selected)
        if (_remarkController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter reason for return'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _completeReturn();
      }
    }
  }

  void _completeDelivery() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery marked as completed for ${widget.task.partyName}'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true); // Return true to indicate success
  }

  void _completeReturn() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery marked as returned for ${widget.task.partyName}'),
        backgroundColor: Colors.orange,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Delivery', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Party Details Card
            _buildSectionCard(
              'Party Details',
              Icons.people_rounded,
              colorScheme,
              [
                _buildInfoRow('Party Name', widget.task.partyName, isBold: true),
                const SizedBox(height: 8),
                _buildInfoRow('Address', '${widget.task.station}, ${widget.task.area}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow('Contact Person', 'Shop Manager'),
                    ),
                    IconButton(
                      icon: Icon(Icons.call, color: colorScheme.primary),
                      onPressed: _makePhoneCall,
                      tooltip: 'Call',
                    ),
                  ],
                ),
                _buildInfoRow('Mobile', '+91 98765 43210'),
              ],
            ),

            const SizedBox(height: 16),

            // Bill Details Card
            _buildSectionCard(
              'Bill Details',
              Icons.receipt_long,
              colorScheme,
              [
                Row(
                  children: [
                    Expanded(child: _buildInfoRow('Bill No', widget.task.billNo ?? 'N/A')),
                    Expanded(
                      child: _buildInfoRow(
                        'Bill Date & Time',
                        widget.task.billDate != null
                            ? DateFormat('dd MMM yy, hh:mm a').format(widget.task.billDate!)
                            : 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'Bill Amount',
                        '₹${widget.task.billAmount?.toStringAsFixed(2) ?? '0.00'}',
                        valueColor: colorScheme.primary,
                        isBold: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow('No of Items', '${widget.task.itemCount ?? 0}'),
                    ),
                    Expanded(
                      child: _buildInfoRow('Total Quantity', '90'), // Mock quantity
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Delivered / Return Toggle
            _buildSectionCard(
              'Status',
              Icons.check_circle_outline,
              colorScheme,
              [
                // Single dropdown controls the status; choosing 'Not delivered' will switch to the Return UI
                DropdownButtonFormField<String>(
                  initialValue: _deliveryStatus,
                  decoration: InputDecoration(
                    labelText: 'Delivery Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                    DropdownMenuItem(value: 'Part delivered', child: Text('Part delivered')),
                    DropdownMenuItem(value: 'Not delivered', child: Text('Not delivered')),
                  ],
                  onChanged: (v) => setState(() {
                    _deliveryStatus = v ?? 'Delivered';
                    // if status is Not delivered, treat as Return (same UI as previous Return capsule)
                    _isDelivered = _deliveryStatus != 'Not delivered';
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select delivery outcome. Choosing "Not delivered" will open the Return form.',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Conditional Forms
            if (_isDelivered) ...[
              // Delivered Flow
              _buildSectionCard(
                'Payment Mode',
                Icons.payment,
                colorScheme,
                [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Cash'),
                          value: 'Cash',
                          groupValue: _paymentMode,
                          onChanged: (value) {
                            setState(() => _paymentMode = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Credit'),
                          value: 'Credit',
                          groupValue: _paymentMode,
                          onChanged: (value) {
                            setState(() => _paymentMode = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // OTP Section
              _buildSectionCard(
                'OTP Verification',
                Icons.security,
                colorScheme,
                [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: 'Enter OTP',
                            counterText: '',
                            suffixIcon: _otpVerified
                                ? Icon(Icons.check_circle, color: Colors.green)
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          enabled: !_otpVerified,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _otpVerified ? null : _requestOTP,
                          child: const Text('Request'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_otpVerified)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: const Text('Verify OTP'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'OTP sent to registered mobile number',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Person Name
              _buildSectionCard(
                'Handover Details',
                Icons.person_pin,
                colorScheme,
                [
                  TextFormField(
                    controller: _personNameController,
                    decoration: InputDecoration(
                      labelText: 'Goods handed over to',
                      hintText: 'Enter person name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Photo Upload
              _buildSectionCard(
                'Photo Upload (Bill and Goods)',
                Icons.photo_camera,
                colorScheme,
                [
                  if (_uploadedPhotos.isEmpty)
                    Text(
                      'Upload 2 photos required',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._uploadedPhotos.asMap().entries.map((entry) {
                        final raw = entry.value;
                        File? file;
                        if (raw is File) file = raw;
                        else if (raw is XFile) file = File(raw.path);
                        else if (raw is String) file = File(raw);

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 100,
                                height: 100,
                                color: colorScheme.surfaceContainerHighest,
                                child: (file != null && file.existsSync())
                                    ? Image.file(file, fit: BoxFit.cover, width: 100, height: 100)
                                    : Center(child: Icon(Icons.image, color: colorScheme.primary, size: 32)),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (_uploadedPhotos.length < 2)
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.primary,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: colorScheme.primary, size: 32),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(fontSize: 10, color: colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Remark
              _buildSectionCard(
                'Remark',
                Icons.note,
                colorScheme,
                [
                  TextFormField(
                    controller: _remarkController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter any remarks (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Return Flow
              _buildSectionCard(
                'Return Reason',
                Icons.undo,
                colorScheme,
                [
                  TextFormField(
                    controller: _remarkController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Reason for Return',
                      hintText: 'Enter reason why goods are being returned',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (!_isDelivered && (value == null || value.isEmpty)) {
                        return 'Please enter return reason';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDelivered ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    ColorScheme colorScheme,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
