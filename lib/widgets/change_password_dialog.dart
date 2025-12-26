import 'package:flutter/material.dart';
import '../auth_service.dart';

class ChangePasswordDialog extends StatefulWidget {
  final AuthService authService;

  const ChangePasswordDialog({Key? key, required this.authService}) : super(key: key);

  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  String? error;
  bool loading = false;

  // UI State for password visibility toggles
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final cur = currentCtrl.text.trim();
    final nw = newCtrl.text.trim();
    final cf = confirmCtrl.text.trim();

    if (cur.isEmpty || nw.isEmpty || cf.isEmpty) {
      setState(() => error = 'Please fill all fields');
      return;
    }
    if (nw != cf) {
      setState(() => error = 'New password and confirm do not match');
      return;
    }
    if (nw.length < 6) {
      setState(() => error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      error = null;
      loading = true;
    });

    try {
      final resp = await widget.authService.updatePassword(oldPassword: cur, newPassword: nw);
      if (resp['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resp['message'] ?? 'Password changed successfully'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            )
        );
      } else {
        setState(() => error = resp['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      setState(() => error = 'Unexpected error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Standard border style for inputs
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
    );

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(24),

      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.key_rounded, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Change Password',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 20, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            _buildTextField(
              controller: currentCtrl,
              label: 'Current password',
              isObscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              border: inputBorder,
              icon: Icons.lock_outline,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: newCtrl,
              label: 'New password',
              isObscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              border: inputBorder,
              icon: Icons.lock_reset,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: confirmCtrl,
              label: 'Confirm new password',
              isObscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              border: inputBorder,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading ? null : submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: loading
              ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.onPrimary)
          )
              : const Text('Update'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggle,
    required InputBorder border,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}