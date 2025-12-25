import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'otp_verification_screen.dart';
import 'auth_service.dart';
import 'create_password_screen.dart';
import 'create_mpin_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _licenseController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _licenseController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);

      // Always call ValidateLicense API (password is optional - can be empty)
      final password = _passwordController.text.trim();
      debugPrint('[LoginScreen] Calling ValidateLicense with password: ${password.isEmpty ? "(empty)" : "(provided)"}');

      final result = await authService.validateLicense(
        licenseNumber: _licenseController.text.trim(),
        mobile: _mobileController.text.trim(),
        password: password, // Can be empty string
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      debugPrint('[LoginScreen] ValidateLicense result success: ${result['success']}');
      debugPrint('[LoginScreen] ValidateLicense result: $result');

      if (result['success']) {
        // ValidateLicense succeeded, check flags to decide next screen
        final data = result['data'];
        debugPrint('[LoginScreen] ValidateLicense success, data: $data');
        debugPrint('[LoginScreen] data type: ${data.runtimeType}');
        debugPrint('[LoginScreen] CreatePasswd raw value: ${data is Map ? data['CreatePasswd'] : 'data is not a Map'}');
        debugPrint('[LoginScreen] CreatePasswd type: ${data is Map ? data['CreatePasswd']?.runtimeType : 'N/A'}');

        // More robust flag detection - check multiple variations
        bool createPass = false;
        bool createMPin = false;

        if (data is Map) {
          // Check CreatePasswd
          final cpValue = data['CreatePasswd'];
          if (cpValue == true) {
            createPass = true;
          } else if (cpValue is String && cpValue.toLowerCase() == 'true') {
            createPass = true;
          } else if (cpValue is bool && cpValue) {
            createPass = true;
          }

          // Check CreateMPin
          final cmValue = data['CreateMPin'];
          if (cmValue == true) {
            createMPin = true;
          } else if (cmValue is String && cmValue.toLowerCase() == 'true') {
            createMPin = true;
          } else if (cmValue is bool && cmValue) {
            createMPin = true;
          }
        }

        debugPrint('[LoginScreen] CreatePasswd=$createPass, CreateMPin=$createMPin');

        if (createPass) {
          debugPrint('[LoginScreen] Navigating to CreatePasswordScreen');
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CreatePasswordScreen(
            mobile: _mobileController.text.trim(),
            licenseNumber: _licenseController.text.trim(),
          )));
          return;
        }
        if (createMPin) {
          debugPrint('[LoginScreen] Navigating to CreateMpinScreen');
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CreateMpinScreen(
            mobile: _mobileController.text.trim(),
            licenseNumber: _licenseController.text.trim(),
          )));
          return;
        }
        // Otherwise navigate to home
        debugPrint('[LoginScreen] Navigating to HomeScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
       } else {
         // Login failed - show error
         debugPrint('[LoginScreen] ValidateLicense FAILED');
         debugPrint('[LoginScreen] Full result: $result');
         debugPrint('[LoginScreen] Message: ${result['message']}');
         debugPrint('[LoginScreen] Data: ${result['data']}');
         debugPrint('[LoginScreen] Raw: ${result['raw']}');

         // Extract message with fallback
         String message = 'Failed to login';
         if (result['message'] != null && result['message'].toString().isNotEmpty) {
           message = result['message'].toString();
         } else if (result['data'] is Map && result['data']['Message'] != null) {
           message = result['data']['Message'].toString();
         } else if (result['data'] is Map && result['data']['message'] != null) {
           message = result['data']['message'].toString();
         }

         debugPrint('[LoginScreen] Final error message: $message');

         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(message),
             backgroundColor: Colors.red,
             duration: const Duration(seconds: 4),
           ),
         );

         // Also show a dialog with full debug JSON so the developer can copy it
         if (result['raw'] != null || result['data'] != null) {
           showDialog<void>(
             context: context,
             builder: (ctx) {
               return AlertDialog(
                 title: const Text('Login debug info'),
                 content: SingleChildScrollView(
                   child: SelectableText(
                     const JsonEncoder.withIndent('  ').convert(result),
                     style: const TextStyle(fontSize: 12),
                   ),
                 ),
                 actions: [
                   TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                 ],
               );
             },
           );
         }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // --- MAIN CONTENT (Scrollable) ---
            Center(
              child: SingleChildScrollView(
                // Add bottom padding so content doesn't get hidden behind the pinned footer
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Ensures inputs fill width
                      children: [

                        // --- 1. CENTERED HEADER ---
                        Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.storefront,
                                size: 26,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Reckon Seller",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Sign in to access your dashboard",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // --- 2. INPUT FIELDS (Compact Typography) ---

                        // License Number
                        TextFormField(
                          controller: _licenseController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 14),
                          decoration: _materialDecoration(
                              context,
                              label: 'License Number',
                              hint: 'e.g. ONS07726',
                              icon: Icons.badge_outlined
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'License number is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Mobile
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: const TextStyle(fontSize: 14),
                          onFieldSubmitted: (_) => _sendOTP(),
                          decoration: _materialDecoration(
                              context,
                              label: 'Mobile Number',
                              hint: '10-digit number',
                              icon: Icons.phone_android_outlined
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Mobile number is required';
                            if (v.length != 10) return 'Enter a valid 10-digit number';
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),
                        // Optional Password - if filled, app will attempt direct login with ValidateLicense
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 14),
                          decoration: _materialDecoration(
                              context,
                              label: 'Password',
                              hint: 'Enter password to login directly',
                              icon: Icons.lock_outline
                          ),
                        ),

                        const SizedBox(height: 32),

                        // --- 3. LOGIN BUTTON ---
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _sendOTP,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                                : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info text
                        Text(
                          "Password is optional. If not set, you'll be asked to create one.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- 5. PINNED FOOTER ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Powered by Reckon Software",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "v2.0.1 (Build 104)",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _materialDecoration(
      BuildContext context, {
        required String label,
        required String hint,
        required IconData icon,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),

      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      floatingLabelBehavior: FloatingLabelBehavior.auto,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }
}
