import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'home_screen.dart';
import 'create_password_screen.dart';
import 'create_mpin_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobile;
  final String licenseNumber;
  final String countryCode;

  const OTPVerificationScreen({
    super.key,
    required this.mobile,
    required this.licenseNumber,
    this.countryCode = '91',
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final result = await authService.verifyOTP(
          mobile: widget.mobile,
          licenseNumber: widget.licenseNumber,
          otp: _otpController.text.trim(),
          countryCode: widget.countryCode,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result['success']) {
          // If backend requests CreatePasswd or CreateMPin, navigate accordingly
          final data = result['data'];
          final createPass = (data is Map && (data['CreatePasswd'] == true || data['CreatePasswd']?.toString() == 'true'));
          final createMPin = (data is Map && (data['CreateMPin'] == true || data['CreateMPin']?.toString() == 'true'));
          if (createPass) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CreatePasswordScreen(mobile: widget.mobile, licenseNumber: widget.licenseNumber, countryCode: widget.countryCode)));
            return;
          }
          if (createMPin) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CreateMpinScreen(mobile: widget.mobile, licenseNumber: widget.licenseNumber, countryCode: widget.countryCode)));
            return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          _showSnackBar(result['message'] ?? 'Verification failed', isError: true);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackBar('An unexpected error occurred', isError: true);
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.sendOTP(
        mobile: widget.mobile,
        licenseNumber: widget.licenseNumber,
        countryCode: widget.countryCode,
      );

      if (!mounted) return;
      setState(() => _isResending = false);

      _showSnackBar(
        result['message'] ?? 'OTP sent successfully',
        isError: !result['success'],
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      _showSnackBar('Failed to send OTP', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Professional, subtle border style
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
    );

    final focusedBorder = inputBorder.copyWith(
      borderSide: BorderSide(color: scheme.primary, width: 1.5),
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20, color: scheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360), // Narrower for compactness
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Compact Header ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 24, // Smaller icon
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "Verification",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(text: "Enter the code sent to "),
                          TextSpan(
                            text: "+${widget.countryCode} ${widget.mobile}",
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- Compact Input ---
                    TextFormField(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12, // Tighter letter spacing
                        color: scheme.onSurface,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        isDense: true, // Reduces internal height
                        hintText: '------',
                        hintStyle: TextStyle(
                          letterSpacing: 12,
                          color: scheme.outline.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: scheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        errorBorder: inputBorder.copyWith(
                          borderSide: BorderSide(color: scheme.error),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) < 6 ? 'Invalid code' : null,
                      onChanged: (value) {
                        if (value.length == 6) _verifyOTP();
                      },
                    ),

                    const SizedBox(height: 24),

                    // --- Compact Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 48, // Standard height
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                            : const Text(
                          "Verify Identity",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Compact Resend Text ---
                    AnimatedOpacity(
                      opacity: _isLoading ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive code? ",
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          InkWell(
                            onTap: _isResending ? null : _resendOTP,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: _isResending
                                  ? SizedBox(
                                  height: 10, width: 10,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: scheme.primary)
                              )
                                  : Text(
                                "Resend",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}