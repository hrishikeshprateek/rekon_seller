import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../constants/branding.dart';
import '../widgets/change_password_dialog.dart';

/// A Material 3 styled Settings page with sample settings options.
/// Drop this page into your app and navigate to it to see a polished
/// settings UI demo.
class SettingsPage extends StatefulWidget {

  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          children: [
            // Account section
            _sectionHeader('Account'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  // Profile info from AuthService (login-time data)
                  Consumer<AuthService>(builder: (ctx, auth, _) {
                    final user = auth.currentUser;
                    final license = user?.licenseNumber ?? '—';
                    final name = user?.fullName.isNotEmpty == true ? user!.fullName : (user?.mobileNumber ?? '—');
                    final stores = user?.stores ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(name, style: theme.textTheme.titleMedium),
                          subtitle: Text('LicNo: $license'),
                        ),

                        // Stores header + list
                        if (stores.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text('Stores', style: theme.textTheme.labelSmall),
                          ),
                          // show each store
                          for (final s in stores)
                            ListTile(
                              leading: const Icon(Icons.store),
                              title: Text(s.name.isNotEmpty ? s.name : s.firmCode),
                              subtitle: Text('${s.add1}${s.add2.isNotEmpty ? ', ${s.add2}' : ''}'),
                              trailing: s.primary ? const Chip(label: Text('Primary')) : null,
                            ),
                        ],
                      ],
                    );
                  }),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.password_outlined),
                    title: const Text('Change password'),
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => ChangePasswordDialog(authService: Provider.of<AuthService>(context, listen: false)),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('Change MPIN'),
                    subtitle: const Text('Change your 6-digit MPIN'),
                    onTap: _changeMpin,
                  ),
                  const Divider(height: 0),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // About
            _sectionHeader('General'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text('Version 1.0.0'),
                onTap: _showAbout,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
    );
  }


  Future<void> _changeMpin() async {
    final auth = Provider.of<AuthService>(context, listen: false);

    // Resolve and normalise the account mobile (last 10 digits).
    String mobile = auth.currentUser?.mobileNumber ?? '';
    mobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (mobile.length > 10) mobile = mobile.substring(mobile.length - 10);
    if (mobile.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number not available')),
      );
      return;
    }

    // 1) Send an OTP to the account mobile before allowing the change.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final send = await auth.generateOTPForMobile(mobile: mobile);
    if (!mounted) return;
    Navigator.of(context).pop(); // close the spinner
    if (send['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(send['message']?.toString() ?? 'Failed to send OTP. Please try again.')),
      );
      return;
    }

    final otpCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;
    bool submitting = false;
    bool resending = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          Future<void> validateAndSubmit() async {
            final otp = otpCtrl.text.trim();
            final nw = newCtrl.text.trim();
            final cf = confirmCtrl.text.trim();

            if (otp.isEmpty || nw.isEmpty || cf.isEmpty) {
              setStateDialog(() => error = 'Please fill all fields');
              return;
            }
            if (nw != cf) {
              setStateDialog(() => error = 'New MPIN and confirm do not match');
              return;
            }
            if (nw.length != 6) {
              setStateDialog(() => error = 'MPIN must be 6 digits');
              return;
            }

            setStateDialog(() {
              error = null;
              submitting = true;
            });

            try {
              // 2) Verify the OTP (does not touch the active session).
              final verify = await auth.verifyMobileOtp(mobile: mobile, otp: otp);
              if (verify['success'] != true) {
                setStateDialog(() {
                  submitting = false;
                  error = verify['message']?.toString() ?? 'Invalid OTP. Please try again.';
                });
                return;
              }

              // 3) OTP verified → set the new MPIN (no current MPIN required).
              final resp = await auth.changeMpin(mobile: mobile, newMpin: nw);
              if (resp['success'] == true) {
                Navigator.of(ctx).pop(true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(resp['message']?.toString() ?? 'MPIN changed successfully')),
                  );
                }
              } else {
                setStateDialog(() {
                  submitting = false;
                  error = resp['message']?.toString() ?? 'Failed to change MPIN';
                });
              }
            } catch (e) {
              setStateDialog(() {
                submitting = false;
                error = 'Unexpected error: ${e.toString()}';
              });
            }
          }

          Future<void> resendOtp() async {
            setStateDialog(() {
              resending = true;
              error = null;
            });
            final r = await auth.generateOTPForMobile(mobile: mobile);
            setStateDialog(() {
              resending = false;
              error = r['success'] == true ? null : (r['message']?.toString() ?? 'Failed to resend OTP');
            });
          }

          return AlertDialog(
            title: const Text('Change MPIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the OTP sent to +91 $mobile and set your new MPIN.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'OTP', counterText: ''),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'New MPIN (6 digits)', counterText: ''),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Confirm MPIN', counterText: ''),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: resending ? null : resendOtp,
                    child: Text(resending ? 'Sending...' : 'Resend OTP'),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : validateAndSubmit,
                child: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Change'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: Branding.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: const [Text('A sample settings page implemented with Material 3.')],
    );
  }

}
