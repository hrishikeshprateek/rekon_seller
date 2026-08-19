import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../auth_service.dart';
import '../constants/branding.dart';

/// "Share and Rate" — presented as a bottom sheet (no separate page).
/// Call [ShareAndRateSheet.show] to open the two options (Share / Rate).
class ShareAndRateSheet {
  static String get _appName => Branding.appName;

  static String _packageName(BuildContext context) =>
      Provider.of<AuthService>(context, listen: false).packageNameHeader;

  static String _playUrl(BuildContext context) =>
      'https://play.google.com/store/apps/details?id=${_packageName(context)}';

  static String _shareMessage(BuildContext context) =>
      'Check out $_appName!\nDownload it here: ${_playUrl(context)}';

  static Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app available to handle this action')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    }
  }

  /// Entry point: bottom sheet with the two options.
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share and Rate',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 16),
                _OptionTile(
                  icon: Icons.share_rounded,
                  color: Branding.primary,
                  title: 'Share',
                  subtitle: 'Invite friends to $_appName',
                  onTap: () {
                    Navigator.pop(ctx);
                    _openShareSheet(context);
                  },
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.star_rounded,
                  color: Branding.secondary,
                  title: 'Rate Seller 2.0',
                  subtitle: 'Tell us how we are doing',
                  onTap: () {
                    Navigator.pop(ctx);
                    _openRateDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- SHARE ----------------

  static void _openShareSheet(BuildContext context) {
    final playUrl = _playUrl(context);
    final msg = _shareMessage(context);
    final encodedMsg = Uri.encodeComponent(msg);
    final encodedUrl = Uri.encodeComponent(playUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 18),
                Text(
                  'Scan to download $_appName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: QrImageView(
                    data: playUrl,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _launch(context, Uri.parse(playUrl)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Branding.primary,
                    side: BorderSide(color: Branding.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  icon: const Icon(Icons.shop_rounded, size: 18),
                  label: const Text('Available on Google Play Store', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'SHARE WITH FRIENDS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 18,
                  alignment: WrapAlignment.center,
                  children: [
                    _ShareTarget(
                      icon: Icons.chat,
                      color: const Color(0xFF25D366),
                      label: 'Whatsapp',
                      onTap: () => _launch(context, Uri.parse('https://wa.me/?text=$encodedMsg')),
                    ),
                    _ShareTarget(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      label: 'Facebook',
                      onTap: () => _launch(context, Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$encodedUrl')),
                    ),
                    _ShareTarget(
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFFE1306C),
                      label: 'Instagram',
                      onTap: () => Share.share(msg),
                    ),
                    _ShareTarget(
                      icon: Icons.push_pin_rounded,
                      color: const Color(0xFFE60023),
                      label: 'Pinterest',
                      onTap: () => _launch(context, Uri.parse('https://pinterest.com/pin/create/button/?url=$encodedUrl&description=$encodedMsg')),
                    ),
                    _ShareTarget(
                      icon: Icons.sms_rounded,
                      color: const Color(0xFF43A047),
                      label: 'SMS',
                      onTap: () => _launch(context, Uri.parse('sms:?body=$encodedMsg')),
                    ),
                    _ShareTarget(
                      icon: Icons.more_horiz_rounded,
                      color: Colors.grey.shade700,
                      label: 'More',
                      onTap: () => Share.share(msg),
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

  // ---------------- RATE ----------------

  static void _openRateDialog(BuildContext context) {
    int rating = 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  Text(
                    'Love $_appName ?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us make it even better by rating the app!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.3),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < rating;
                      return IconButton(
                        onPressed: () => setStateDialog(() => rating = i + 1),
                        icon: Icon(
                          Icons.star_rounded,
                          size: 42,
                          color: filled ? const Color(0xFFFFC107) : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bad', style: TextStyle(color: Colors.grey.shade800, fontSize: 15)),
                        Text('Good', style: TextStyle(color: Colors.grey.shade800, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openRatingStore(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D0E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('PROCEED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Opens the Play Store listing to rate. Tries the market:// scheme first,
  /// then falls back to the https Play Store URL.
  static Future<void> _openRatingStore(BuildContext context) async {
    final pkg = _packageName(context);
    final market = Uri.parse('market://details?id=$pkg');
    try {
      if (await canLaunchUrl(market)) {
        await launchUrl(market, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      await _launch(context, Uri.parse(_playUrl(context)));
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _ShareTarget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ShareTarget({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }
}
