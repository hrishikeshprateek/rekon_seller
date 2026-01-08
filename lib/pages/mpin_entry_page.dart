import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../login_screen.dart';

class MpinEntryPage extends StatefulWidget {
  final String mobile;
  final bool allowCancel;
  const MpinEntryPage({Key? key, required this.mobile, this.allowCancel = true}) : super(key: key);

  @override
  State<MpinEntryPage> createState() => _MpinEntryPageState();
}

class _MpinEntryPageState extends State<MpinEntryPage> {
  final TextEditingController _hiddenController = TextEditingController();
  int _attemptsLeft = 3;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _hiddenController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _hiddenController.removeListener(_onInputChanged);
    _hiddenController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
    final text = _hiddenController.text;
    if (text.length == 6 && !_isSubmitting) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final mpin = _hiddenController.text.trim();
    if (mpin.length < 1) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      var result = await auth.validateMpin(mobile: widget.mobile, mpin: mpin);

      // If we get 401 (token expired), try to refresh token and retry once
      if (result['statusCode'] == 401) {
        debugPrint('[MpinEntryPage] Got 401, attempting token refresh');

        final refreshResult = await auth.refreshAccessToken();

        if (refreshResult['success'] == true) {
          debugPrint('[MpinEntryPage] Token refreshed successfully, retrying MPIN validation');
          // Retry MPIN validation with new token
          result = await auth.validateMpin(mobile: widget.mobile, mpin: mpin);
        } else {
          // Refresh failed, logout
          debugPrint('[MpinEntryPage] Token refresh failed: ${refreshResult['message']}');
          await auth.logout();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Session expired: ${refreshResult['message']}')),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }
      }

      if (result['success'] == true) {
        // Return both success and the validated MPIN so caller can use it to generate fresh tokens if needed
        if (mounted) Navigator.of(context).pop({'success': true, 'mpin': mpin});
        return;
      }

      // MPIN validation failed (wrong MPIN)
      _attemptsLeft -= 1;
      if (_attemptsLeft <= 0) {
        await auth.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      setState(() {
        _hiddenController.clear();
        _errorMessage = (result['message'] ?? 'Invalid MPIN');
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid MPIN. Attempts left: $_attemptsLeft')));
    } catch (e) {
      debugPrint('[MpinEntryPage] Error during MPIN validation: $e');
      setState(() {
        _errorMessage = 'An error occurred';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _appendDigit(String d) {
    if (_hiddenController.text.length >= 6 || _isSubmitting) return;
    HapticFeedback.lightImpact();
    _hiddenController.text = '${_hiddenController.text}$d';
  }

  void _backspace() {
    final t = _hiddenController.text;
    if (t.isEmpty || _isSubmitting) return;
    HapticFeedback.lightImpact();
    _hiddenController.text = t.substring(0, t.length - 1);
  }

  // --- UI WIDGETS ---

  Widget _buildPinDisplay(ThemeData theme) {
    final text = _hiddenController.text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < text.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            border: filled
                ? null
                : Border.all(color: theme.colorScheme.outline.withOpacity(0.5), width: 1.5),
            boxShadow: filled
                ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 6, spreadRadius: 1)]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildKey(BuildContext ctx, String label, {VoidCallback? onTap}) {
    final theme = Theme.of(ctx);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            height: 64, // Slightly shorter for compactness
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Text(
              label,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final canSubmit = _hiddenController.text.length == 6 && !_isSubmitting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          _buildKey(ctx, '1', onTap: () => _appendDigit('1')),
          _buildKey(ctx, '2', onTap: () => _appendDigit('2')),
          _buildKey(ctx, '3', onTap: () => _appendDigit('3')),
        ]),
        Row(children: [
          _buildKey(ctx, '4', onTap: () => _appendDigit('4')),
          _buildKey(ctx, '5', onTap: () => _appendDigit('5')),
          _buildKey(ctx, '6', onTap: () => _appendDigit('6')),
        ]),
        Row(children: [
          _buildKey(ctx, '7', onTap: () => _appendDigit('7')),
          _buildKey(ctx, '8', onTap: () => _appendDigit('8')),
          _buildKey(ctx, '9', onTap: () => _appendDigit('9')),
        ]),
        Row(children: [
          // Backspace Button
          Expanded(
            child: InkWell(
              onTap: _backspace,
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(
                height: 64,
                child: Icon(Icons.backspace_outlined, size: 24, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),

          // Zero Button
          _buildKey(ctx, '0', onTap: () => _appendDigit('0')),

          // Submit Button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: _isSubmitting
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)))
                  : IconButton.filled(
                onPressed: canSubmit ? _submit : null,
                style: IconButton.styleFrom(
                  backgroundColor: canSubmit ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: canSubmit ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.check_rounded),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.allowCancel ? IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ) : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // --- HEADER ---
            Icon(Icons.lock_open_rounded, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Enter MPIN',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter your 6-digit code',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),

            const Spacer(flex: 1),

            // --- PIN DOTS ---
            _buildPinDisplay(theme),

            // --- INFO & ERROR ---
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                    ),
                  if (_attemptsLeft < 3 && _errorMessage == null)
                    Text(
                      'Attempts left: $_attemptsLeft',
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                ],
              ),
            ),

            // --- CLEAR CODE BUTTON (MOVED HERE) ---
            if (_hiddenController.text.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _hiddenController.clear();
                    _errorMessage = null;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Clear Code'),
              )
            else
              const SizedBox(height: 36), // Maintain height so layout doesn't jump

            const Spacer(flex: 2),

            // --- KEYBOARD ---
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildKeyboard(context),
            ),

            const SizedBox(height: 16),

            // --- HIDDEN INPUT ---
            SizedBox.shrink(
              child: TextField(
                controller: _hiddenController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}