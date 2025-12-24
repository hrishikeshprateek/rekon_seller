import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class CreateMpinScreen extends StatefulWidget {
  final String mobile;
  final String licenseNumber;
  final String countryCode;

  const CreateMpinScreen({
    super.key,
    required this.mobile,
    required this.licenseNumber,
    this.countryCode = '91',
  });

  @override
  State<CreateMpinScreen> createState() => _CreateMpinScreenState();
}

class _CreateMpinScreenState extends State<CreateMpinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mpinController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureMpin = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _mpinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final res = await auth.createMPin(
        mobile: widget.mobile,
        mpin: _mpinController.text.trim(),
        licenseNumber: widget.licenseNumber,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final success = res['success'] == true;
      final message = res['message'] ?? (success ? 'MPIN set successfully' : 'Failed to set MPIN');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green[800] : Colors.red[800], // Darker, serious colors
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );

      if (success) {
        // After first-time MPIN creation do NOT auto-login; send user back to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("An unexpected error occurred"),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Professional, sharper border style
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6), // Tighter radius = more professional
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
    );

    final focusedBorder = inputBorder.copyWith(
      borderSide: BorderSide(color: cs.primary, width: 2),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
            'Security Setup',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header ---
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 28, color: cs.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Set MPIN",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create a 6-digit PIN to secure your account linked to +${widget.countryCode} ${widget.mobile}.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- Input 1 ---
                    _buildLabel(theme, "New MPIN"),
                    TextFormField(
                      controller: _mpinController,
                      keyboardType: TextInputType.number,
                      obscureText: _obscureMpin,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        letterSpacing: 8, // Wider spacing for numeric codes
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: "",
                        isDense: true, // More compact
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureMpin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscureMpin = !_obscureMpin),
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'MPIN is required';
                        if (v.length != 6) return 'Must be 6 digits';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // --- Input 2 ---
                    _buildLabel(theme, "Confirm MPIN"),
                    TextFormField(
                      controller: _confirmController,
                      keyboardType: TextInputType.number,
                      obscureText: _obscureConfirm,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        letterSpacing: 8,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        counterText: "",
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirm MPIN is required';
                        if (v != _mpinController.text) return 'MPINs do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // --- Action ---
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6), // Matches input radius
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                            : const Text(
                          "Set MPIN",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
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

  Widget _buildLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}