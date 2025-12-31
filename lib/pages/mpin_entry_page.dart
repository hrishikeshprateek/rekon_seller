import 'package:flutter/material.dart';
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
  final FocusNode _hiddenFocus = FocusNode();
  int _attemptsLeft = 3;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the hidden field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hiddenFocus.requestFocus();
    });
    // listen for input changes
    _hiddenController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _hiddenController.removeListener(_onInputChanged);
    _hiddenController.dispose();
    _hiddenFocus.dispose();
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
      final result = await auth.validateMpin(mobile: widget.mobile, mpin: mpin);
      if (result['success'] == true) {
        // success: pop true
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      // failed
      _attemptsLeft -= 1;
      if (_attemptsLeft <= 0) {
        // lock out: logout and navigate to login screen
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid MPIN. Attempts left: $_attemptsLeft')));
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
      // refocus
      _hiddenFocus.requestFocus();
    }
  }

  Widget _buildPinBoxes() {
    final text = _hiddenController.text;
    final boxes = List<Widget>.generate(6, (i) {
      final display = i < text.length ? '•' : '';
      return Container(
        width: 42,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.2),
          color: Theme.of(context).colorScheme.surface,
        ),
        alignment: Alignment.center,
        child: Text(
          display,
          style: const TextStyle(fontSize: 28, letterSpacing: 6),
        ),
      );
    });

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: boxes);
  }

  @override
  Widget build(BuildContext context) {
    // controller listener is attached in initState

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter MPIN'),
        centerTitle: true,
        automaticallyImplyLeading: widget.allowCancel,
      ),
      body: GestureDetector(
        onTap: () => _hiddenFocus.requestFocus(),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Please enter your 6-digit MPIN to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              _buildPinBoxes(),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
              ],
              Text('Attempts left: $_attemptsLeft', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),

              // Hidden TextField
              SizedBox(
                height: 0,
                width: 0,
                child: TextField(
                  controller: _hiddenController,
                  focusNode: _hiddenFocus,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                ),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.allowCancel)
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
