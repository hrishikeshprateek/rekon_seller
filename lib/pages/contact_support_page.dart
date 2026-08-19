import 'package:flutter/material.dart';
import '../constants/branding.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contact-support options shown as a bottom sheet (Call / WhatsApp / Email).
/// Call [ContactSupportSheet.show] to present it — there is no separate page.
class ContactSupportSheet {
  // Contact details
  static const String _phone = '05224972500';
  static const String _phoneDisplay = '0522-4972500';
  static const String _whatsapp = '916389590800'; // country code + number, no '+'
  static const String _whatsappDisplay = '+91 6389590800';
  static const String _email = 'care@reckonsales.com';

  static Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${uri.toString()}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app available to handle this action')),
        );
      }
    }
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 4),
                Text('We are here to help', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ContactIcon(
                      icon: Icons.call_rounded,
                      color: Branding.primary,
                      label: 'Call',
                      value: _phoneDisplay,
                      onTap: () {
                        Navigator.pop(ctx);
                        _launch(context, Uri(scheme: 'tel', path: _phone));
                      },
                    ),
                    _ContactIcon(
                      icon: Icons.chat,
                      color: const Color(0xFF25D366),
                      label: 'WhatsApp',
                      value: _whatsappDisplay,
                      onTap: () {
                        Navigator.pop(ctx);
                        _launch(context, Uri.parse('https://wa.me/$_whatsapp'));
                      },
                    ),
                    _ContactIcon(
                      icon: Icons.email_rounded,
                      color: Branding.secondary,
                      label: 'Email',
                      value: _email,
                      onTap: () {
                        Navigator.pop(ctx);
                        _launch(context, Uri(scheme: 'mailto', path: _email));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A single tappable contact option: a coloured circular icon with a label
/// and the contact value beneath it.
class _ContactIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
