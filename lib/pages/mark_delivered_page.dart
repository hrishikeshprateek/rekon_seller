import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/delivery_task_model.dart';
import '../auth_service.dart';

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
  final FocusNode _otpFocusNode = FocusNode();

  bool _isDelivered = true; // true = Delivered, false = Return
  bool _otpVerified = false;
  bool _otpSent = false; // Track if OTP has been sent
  bool _isRequestingOTP = false; // Loading state for OTP request
  bool _isVerifyingOTP = false; // Loading state for OTP verification
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
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall() async {
    try {
      String? raw = widget.task.mobile;
      if (raw == null || raw.trim().isEmpty || raw.trim().toLowerCase() == 'na') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number available')));
        return;
      }

      // Extract digits
      String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 10) {
        digits = '91$digits';
      }
      if (digits.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid phone number')));
        return;
      }

      final phoneUrl = Uri.parse('tel:+$digits');
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not place call')));
      }
    } catch (e) {
      debugPrint('Call failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call failed: $e')));
    }
  }

  Future<void> _requestOTP() async {
    if (_isRequestingOTP) return;

    setState(() => _isRequestingOTP = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Use auth.getDioClient() for automatic 401 handling
      final dio = auth.getDioClient();

      // Get customer mobile number from task
      String? customerMobile = widget.task.mobile;
      if (customerMobile == null || customerMobile.trim().isEmpty || customerMobile.toLowerCase() == 'na') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer mobile number not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Normalize mobile (extract digits only, get last 10)
      String mobile = customerMobile.replaceAll(RegExp(r'[^0-9]'), '');
      if (mobile.length > 10) {
        mobile = mobile.substring(mobile.length - 10);
      }

      debugPrint('[MarkDeliveredPage] Sending OTP to: $mobile');
      debugPrint('[MarkDeliveredPage] BaseURL: ${AuthService.baseUrl}');
      debugPrint('[MarkDeliveredPage] Full URL will be: ${AuthService.baseUrl}/GenerateOTPForMobile');

      final response = await dio.post(
        '/GenerateOTPForMobile',
        options: Options(
          validateStatus: (status) => true, // Accept all status codes to see error response
          headers: {
            'package_name': 'com.reckon.reckonbiz',
            'MobileNo': mobile,
            'CountryCode': '91',
            'lApkName': 'com.reckon.reckonbiz',
            'GenerateOtp': '0',
          },
        ),
      );

      debugPrint('[MarkDeliveredPage] OTP Response status: ${response.statusCode}');
      debugPrint('[MarkDeliveredPage] OTP Response: ${response.data}');

      if (response.statusCode != 200) {
        // Non-200 response, show error
        final errorMsg = response.data is String ? response.data : (response.data.toString());
        debugPrint('[MarkDeliveredPage] Server returned error: $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error (${response.statusCode}): $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['Status'] == true) {
        if (mounted) {
          setState(() {
            _otpSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['Message'] ?? 'OTP sent to customer mobile number'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['Message'] ?? 'Failed to send OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[MarkDeliveredPage] OTP request error: $e');

      // Try to extract error response body
      if (e is DioException && e.response != null) {
        debugPrint('[MarkDeliveredPage] Error response status: ${e.response?.statusCode}');
        debugPrint('[MarkDeliveredPage] Error response data: ${e.response?.data}');
        debugPrint('[MarkDeliveredPage] Error response headers: ${e.response?.headers}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingOTP = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_isVerifyingOTP) return;

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifyingOTP = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Use auth.getDioClient() for automatic 401 handling
      final dio = auth.getDioClient();

      // Get customer mobile number from task
      String? customerMobile = widget.task.mobile;
      if (customerMobile == null || customerMobile.trim().isEmpty || customerMobile.toLowerCase() == 'na') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer mobile number not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Normalize mobile (extract digits only, get last 10)
      String mobile = customerMobile.replaceAll(RegExp(r'[^0-9]'), '');
      if (mobile.length > 10) {
        mobile = mobile.substring(mobile.length - 10);
      }

      debugPrint('[MarkDeliveredPage] Verifying OTP for mobile: $mobile');

      final payload = jsonEncode({
        'MobileNo': mobile,
        'OTP': otp,
        'CountryCode': '91',
      });

      final response = await dio.post(
        '/ValidateMobileOTP',
        data: payload,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': auth.getAuthHeader() ?? '',
          'package_name': 'com.reckon.reckonbiz',
        }),
      );

      debugPrint('[MarkDeliveredPage] OTP Verification Response status: ${response.statusCode}');
      debugPrint('[MarkDeliveredPage] OTP Verification Response: ${response.data}');

      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['Status'] == true) {
        if (mounted) {
          setState(() => _otpVerified = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['Message'] ?? 'OTP verified successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['Message'] ?? 'Invalid OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[MarkDeliveredPage] OTP verification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOTP = false);
      }
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
        // Gallery: request photos permission
        // For Android 13+ (API 33+), photos permission is used
        // For Android 12 and below, storage permission is used
        PermissionStatus status;

        if (Platform.isAndroid) {
          // Try photos permission first (Android 13+)
          status = await Permission.photos.request();

          // If photos permission is not available (Android < 13), fall back to storage
          if (status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied) {
            status = await Permission.storage.request();
          }
        } else {
          // iOS - use photos permission
          status = await Permission.photos.request();
        }

        if (status.isPermanentlyDenied) {
          await _showPermissionDialog('Gallery access permission is permanently denied. Please enable it from app settings.');
          return;
        }
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery access permission is required to pick images'))
          );
          return;
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
        // OTP is now optional - removed mandatory verification check

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

        // Complete delivery for both Cash and Credit
        _completeDelivery();
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

  Future<void> _completeDelivery() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    // Use auth.getDioClient() for automatic 401 handling with longer timeout
    final dio = auth.getDioClient();
    dio.options.connectTimeout = const Duration(seconds: 60);

    // Delivery status code: "1"=Delivered, "2"=Part delivered, "3"=Not delivered
    String statusCode = "1";
    if (_deliveryStatus == 'Part delivered') statusCode = "2";
    else if (_deliveryStatus == 'Not delivered') statusCode = "3";

    try {
      // Build the request JSON object
      final requestJson = {
        'keyno': widget.task.id ?? '', // Use task.id as keyno (bill key)
        'deliveryStatus': statusCode,
        'remark': _remarkController.text.trim().isEmpty ? 'Delivered successfully' : _remarkController.text.trim(),
        'deliveryDateTime': DateTime.now().toUtc().toIso8601String(),
        'paymentMode': _paymentMode,
        'handoverDetail': _personNameController.text.trim(),
        'otp': _otpController.text.trim(),
      };

      debugPrint('[MarkDeliveredPage] Request JSON: ${jsonEncode(requestJson)}');

      // Create FormData with request as JSON string
      final formData = FormData.fromMap({
        'request': jsonEncode(requestJson),
      });

      // Add photos as multipart files
      for (int i = 0; i < _uploadedPhotos.length; i++) {
        final photo = _uploadedPhotos[i];
        File? file;
        if (photo is File) file = photo;
        else if (photo is XFile) file = File(photo.path);
        else if (photo is String) file = File(photo);

        if (file != null && file.existsSync()) {
          formData.files.add(MapEntry(
            'photo${i + 1}',
            await MultipartFile.fromFile(
              file.path,
              filename: 'delivery_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg'
            ),
          ));
        }
      }

      debugPrint('[MarkDeliveredPage] Submitting delivery with ${_uploadedPhotos.length} photos to /markDelivery');

      final response = await dio.post('/markDelivery', data: formData,
          options: Options(headers: {
            'Authorization': auth.getAuthHeader() ?? '',
            'package_name': 'com.reckon.reckonbiz',
          }));

      debugPrint('[MarkDeliveredPage] Response: ${response.data}');

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (mounted) {
        if (data['Status'] == true) {
          // Show success dialog with all details
          _showSuccessDialog(data);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['Message'] ?? 'Failed to mark delivery'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[MarkDeliveredPage] Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _completeReturn() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    // Use auth.getDioClient() for automatic 401 handling
    final dio = auth.getDioClient();
    dio.options.connectTimeout = const Duration(seconds: 30);

    try {
      // Build the request JSON object for return/not delivered
      final requestJson = {
        'keyno': widget.task.id ?? '', // Use task.id as keyno (bill key)
        'deliveryStatus': "3", // 3 = Return/Not delivered
        'remark': _remarkController.text.trim(),
        'deliveryDateTime': DateTime.now().toUtc().toIso8601String(),
      };

      debugPrint('[MarkDeliveredPage] Return Request JSON: ${jsonEncode(requestJson)}');

      final formData = FormData.fromMap({
        'request': jsonEncode(requestJson),
      });

      final response = await dio.post('/markDelivery', data: formData,
          options: Options(headers: {
            'Authorization': auth.getAuthHeader() ?? '',
            'package_name': 'com.reckon.reckonbiz',
          }));

      debugPrint('[MarkDeliveredPage] Return Response: ${response.data}');

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (mounted) {
        if (data['Status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['Message'] ?? 'Return recorded successfully'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['Message'] ?? 'Failed to record return'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[MarkDeliveredPage] Return error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> responseData) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 64),
                    SizedBox(height: 12),
                    Text(
                      'Success!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Delivery marked successfully',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Party Name', widget.task.partyName, colorScheme),
                      const SizedBox(height: 12),
                      _buildInfoRow('Bill Number', widget.task.billNo ?? 'N/A', colorScheme),
                      const SizedBox(height: 12),
                      _buildInfoRow('Amount', '₹${widget.task.billAmount?.toStringAsFixed(2) ?? '0.00'}', colorScheme, isBold: true),
                      const SizedBox(height: 12),
                      _buildInfoRow('Status', _deliveryStatus, colorScheme),
                      const SizedBox(height: 12),
                      _buildInfoRow('Payment', _paymentMode, colorScheme),

                      if (_personNameController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow('Handed To', _personNameController.text.trim(), colorScheme),
                      ],

                      if (_remarkController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Remarks',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _remarkController.text.trim(),
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],

                      if (responseData['photo1Url'] != null || responseData['photo2Url'] != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${(responseData['photo1Url'] != null ? 1 : 0) + (responseData['photo2Url'] != null ? 1 : 0)} photo(s) uploaded',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A237E), // Deep Blue
                      Color(0xFFFF6F00), // Orange
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 80, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isDelivered ? 'Mark Delivery' : 'Return Entry',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.task.billNo ?? 'N/A',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: const Text(
              'Delivery Details',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
            ),
            centerTitle: true,
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
            // Party Details Card
            _buildSectionCard(
              'Party Details',
              Icons.people_rounded,
              colorScheme,
              [
                _buildDetailRow('Party Name', widget.task.partyName, isBold: true),
                const SizedBox(height: 8),
                _buildDetailRow('Address', '${widget.task.station}, ${widget.task.area}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow('Contact Person', 'Shop Manager'),
                    ),
                    IconButton(
                      icon: Icon(Icons.call, color: colorScheme.primary),
                      onPressed: _makePhoneCall,
                      tooltip: 'Call',
                    ),
                  ],
                ),
                _buildDetailRow('Mobile', widget.task.mobile ?? 'N/A'),
              ],
            ),

            const SizedBox(height: 10),

            // Bill Details Card
            _buildSectionCard(
              'Bill Details',
              Icons.receipt_long,
              colorScheme,
              [
                Row(
                  children: [
                    Expanded(child: _buildDetailRow('Bill No', widget.task.billNo ?? 'N/A')),
                    Expanded(
                      child: _buildDetailRow(
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
                      child: _buildDetailRow(
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
                      child: _buildDetailRow('No of Items', '${widget.task.itemCount ?? 0}'),
                    ),
                    Expanded(
                      child: _buildDetailRow('Total Quantity', '90'), // Mock quantity
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

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

            const SizedBox(height: 10),

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

              const SizedBox(height: 10),

              // OTP Section - Modern PIN Style (Optional)
              _buildSectionCard(
                'OTP Verification (Optional)',
                Icons.security,
                colorScheme,
                [
                  // Info text about optional OTP
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'OTP verification is optional. You can proceed without it.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // OTP Status Header
                  if (_otpVerified)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'OTP Verified Successfully',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Send OTP Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_otpSent || _isRequestingOTP) ? null : _requestOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _otpSent ? Colors.green : colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isRequestingOTP
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_otpSent ? Icons.check : Icons.send),
                        label: Text(_isRequestingOTP ? 'Sending...' : _otpSent ? 'OTP Sent' : 'Send OTP to Customer'),
                      ),
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 16),
                      // Info text
                      Text(
                        'Enter 6-digit OTP received by customer',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // PIN Style OTP Input
                      GestureDetector(
                        onTap: () {
                          // Focus the hidden text field when user taps on PIN boxes
                          FocusScope.of(context).requestFocus(FocusNode());
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              FocusScope.of(context).requestFocus(_otpFocusNode);
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            final currentLength = _otpController.text.length;
                            final isFilled = index < currentLength;
                            final isCurrent = index == currentLength;

                            return Container(
                              width: 45,
                              height: 55,
                              decoration: BoxDecoration(
                                color: isFilled
                                    ? colorScheme.primaryContainer.withOpacity(0.3)
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent
                                      ? colorScheme.primary
                                      : isFilled
                                          ? colorScheme.primary.withOpacity(0.5)
                                          : colorScheme.outlineVariant,
                                  width: isCurrent ? 2 : 1,
                                ),
                                boxShadow: isCurrent ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: Center(
                                child: Text(
                                  isFilled ? _otpController.text[index] : '',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Hidden text field for OTP input
                      SizedBox(
                        height: 0,
                        width: 0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isVerifyingOTP ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isVerifyingOTP
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Resend OTP option
                      Center(
                        child: TextButton(
                          onPressed: _isRequestingOTP ? null : _requestOTP,
                          child: Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 10),

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

              const SizedBox(height: 10),

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

              const SizedBox(height: 10),

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
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Space for bottom button
              ]),
            ),
          ),
        ],
      ),
      // Modern floating submit button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _submitDelivery,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 22),
                const SizedBox(width: 8),
                Text(
                  _isDelivered ? 'Complete Delivery' : 'Submit Return',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: const Color(0xFF1A237E).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: const Color(0xFF1A237E).withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
