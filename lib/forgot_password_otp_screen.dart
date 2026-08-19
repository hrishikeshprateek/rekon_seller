import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'login_screen.dart';

/// Forgot-password: enter the OTP (sent via /GenerateOTPForMobile) together
/// with the new password. The OTP is verified server-side inside the single
/// /forgotpassword call — no separate OTP-validation endpoint is used.
class ForgotPasswordOtpScreen extends StatefulWidget {
  final String mobile;
  final String countryCode;

  const ForgotPasswordOtpScreen({
    super.key,
    required this.mobile,
    this.countryCode = '91',
  });

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final result = await auth.resetPassword(
        mobile: widget.mobile,
        password: _passwordController.text.trim(),
        countryCode: widget.countryCode,
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      final success = result['success'] == true;
      _showSnackBar(
        result['message']?.toString() ?? (success ? 'Password reset successfully' : 'Failed to reset password'),
        isError: !success,
      );
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('An unexpected error occurred', isError: true);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final result = await auth.generateOTPForMobile(
        mobile: widget.mobile,
        countryCode: widget.countryCode,
      );
      if (!mounted) return;
      setState(() => _isResending = false);
      _showSnackBar(
        result['message']?.toString() ?? 'OTP sent',
        isError: result['success'] != true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      _showSnackBar('Failed to send OTP', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    OutlineInputBorder border([Color? c]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c ?? scheme.outline.withValues(alpha: 0.3)),
        );

    InputDecoration deco(String label, IconData icon, {Widget? suffix}) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          suffixIcon: suffix,
          border: border(),
          enabledBorder: border(),
          focusedBorder: border(scheme.primary).copyWith(
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock_reset_rounded, size: 24, color: scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reset Password',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the OTP sent to +${widget.countryCode} ${widget.mobile} and set a new password',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.w600),
                      decoration: deco('OTP', Icons.sms_outlined).copyWith(counterText: ''),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Enter the OTP';
                        if (t.length < 4) return 'Enter a valid OTP';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 14),
                      decoration: deco(
                        'New Password',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Enter a new password';
                        if (t.length < 4) return 'Password is too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(fontSize: 14),
                      decoration: deco(
                        'Confirm Password',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if ((v?.trim() ?? '').isEmpty) return 'Confirm your password';
                        if (v?.trim() != _passwordController.text.trim()) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                              )
                            : const Text(
                                'RESET PASSWORD',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isResending ? null : _resend,
                      child: Text(_isResending ? 'Sending...' : 'Resend OTP'),
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
