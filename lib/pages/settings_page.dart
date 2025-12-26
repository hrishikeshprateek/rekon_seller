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
  // Sample state for typical settings
  bool _isDarkMode = false;
  bool _useDynamicColor = true;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  double _textScale = 1.0;
  String _language = 'English';
  String _accountName = 'John Doe';

  final List<String> _languages = ['English', 'Hindi', 'Spanish', 'French'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Reset settings',
            onPressed: _confirmReset,
            icon: const Icon(Icons.restore),
          ),
        ],
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
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(_accountName, style: theme.textTheme.titleMedium),
                    subtitle: const Text('Personal account'),
                    trailing: TextButton(
                      child: const Text('Edit'),
                      onPressed: _editAccount,
                    ),
                  ),
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

            // Appearance section
            _sectionHeader('Appearance'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Dark mode'),
                    subtitle: const Text('Use a dark color scheme'),
                    value: _isDarkMode,
                    onChanged: (v) => setState(() => _isDarkMode = v),
                    secondary: const Icon(Icons.dark_mode),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Dynamic colors'),
                    subtitle: const Text('Use colors from your wallpaper (Android 12+)'),
                    value: _useDynamicColor,
                    onChanged: (v) => setState(() => _useDynamicColor = v),
                    secondary: const Icon(Icons.palette_outlined),
                  ),
                  ListTile(
                    leading: const Icon(Icons.format_size),
                    title: const Text('Text scaling'),
                    subtitle: Text('${(_textScale * 100).round()}%'),
                    trailing: SizedBox(
                      width: 150,
                      child: Slider.adaptive(
                        value: _textScale,
                        min: 0.8,
                        max: 1.4,
                        divisions: 6,
                        onChanged: (v) => setState(() => _textScale = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Notifications section
            _sectionHeader('Notifications'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Enable notifications'),
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                    secondary: const Icon(Icons.notifications_active_outlined),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      children: [
                        const Divider(height: 0),
                        CheckboxListTile(
                          title: const Text('Email notifications'),
                          value: _emailNotifications,
                          onChanged: _notificationsEnabled ? (v) => setState(() => _emailNotifications = v ?? false) : null,
                          secondary: const Icon(Icons.email_outlined),
                        ),
                        CheckboxListTile(
                          title: const Text('SMS notifications'),
                          value: _smsNotifications,
                          onChanged: _notificationsEnabled ? (v) => setState(() => _smsNotifications = v ?? false) : null,
                          secondary: const Icon(Icons.sms_outlined),
                        ),
                      ],
                    ),
                    crossFadeState: _notificationsEnabled ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Privacy & Security
            _sectionHeader('Privacy & Security'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fingerprint_outlined),
                    title: const Text('Use biometric authentication'),
                    trailing: Switch.adaptive(
                      value: true,
                      onChanged: (v) => _showInfo('Biometrics', 'This is a demo switch.'),
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('App lock timeout'),
                    subtitle: const Text('1 minute'),
                    onTap: () => _showInfo('App lock timeout', 'Change the lock timeout.'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // General / About
            _sectionHeader('General'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Language'),
                    subtitle: Text(_language),
                    trailing: DropdownButton<String>(
                      value: _language,
                      underline: const SizedBox.shrink(),
                      items: _languages
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setState(() => _language = v ?? _language),
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: const Text('Version 1.0.0'),
                    onTap: _showAbout,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save settings'),
                onPressed: _saveSettings,
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () => _showInfo('Help & support', 'Contact support at support@example.com'),
                child: const Text('Help & support'),
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

  void _editAccount() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String tmp = _accountName;
        return AlertDialog(
          title: const Text('Edit account name'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Name'),
            controller: TextEditingController(text: tmp),
            onChanged: (v) => tmp = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, tmp), child: const Text('Save')),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      setState(() => _accountName = name);
    }
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

  void _saveSettings() {
    // In a real app you'd persist settings to storage or a backend.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  void _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reset settings'),
          content: const Text('Reset settings to defaults?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
          ],
        );
      },
    );

    if (ok == true) {
      setState(() {
        _isDarkMode = false;
        _useDynamicColor = true;
        _notificationsEnabled = true;
        _emailNotifications = true;
        _smsNotifications = false;
        _textScale = 1.0;
        _language = 'English';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings reset')));
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

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
}
