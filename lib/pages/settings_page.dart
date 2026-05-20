import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
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
        title: const Text('Settings'),
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
                    subtitle: const Text('Change your 4-6 digit MPIN'),
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
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          void validateAndSubmit() async {
            final cur = currentCtrl.text.trim();
            final nw = newCtrl.text.trim();
            final cf = confirmCtrl.text.trim();

            if (cur.isEmpty || nw.isEmpty || cf.isEmpty) {
              setStateDialog(() => error = 'Please fill all fields');
              return;
            }
            if (nw != cf) {
              setStateDialog(() => error = 'New MPIN and confirm do not match');
              return;
            }
            if (nw.length < 4 || nw.length > 6) {
              setStateDialog(() => error = 'MPIN must be 4 to 6 digits');
              return;
            }

            setStateDialog(() => error = null); // Clear error before API call

            try {
              final resp = await auth.changeMpin(oldMpin: cur, newMpin: nw);
              if (resp['success'] == true) {
                Navigator.of(ctx).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? 'MPIN changed successfully')));
              } else {
                setStateDialog(() => error = resp['message'] ?? 'Failed to change MPIN');
              }
            } catch (e) {
              setStateDialog(() => error = 'Unexpected error: ${e.toString()}');
            }
          }

          return AlertDialog(
            title: const Text('Change MPIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current MPIN'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New MPIN (4-6 digits)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm MPIN'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: validateAndSubmit, child: const Text('Change')),
            ],
          );
        });
      },
    );

    if (ok == true) {
      // Success handled in dialog
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Reckon BIZ360',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: const [Text('A sample settings page implemented with Material 3.')],
    );
  }

}
