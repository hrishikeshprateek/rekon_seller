import 'package:flutter/material.dart';
import 'api_constants.dart';

/// Per-flavor branding. Flutter assets/colors are NOT flavor-aware (both
/// flavors bundle the same code), so we pick brand images, names and colors at
/// runtime from the real package name resolved at startup (see main.dart).
///
/// IMPORTANT: every getter returns the ORIGINAL Reckon value for the reckon
/// flavor, so the Reckon app is visually unchanged.
class Branding {
  static bool get isAmar =>
      ApiConstants.packageName == 'com.reckon.amareorder';

  /// Main brand logo shown on the login screen / splash / home.
  static String get logo =>
      isAmar ? 'assets/images/amar.jpeg' : 'assets/images/reckon.png';

  /// Display name shown in-app (login header, splash, title, about).
  static String get appName => isAmar ? 'Amar eOrder' : 'Reckon Seller 2.0';

  /// Primary brand colour used for app bars, buttons and accents throughout
  /// the app. Reckon keeps its exact original blue (0xFF1E88E5); Amar uses the
  /// teal from the Amar eRetail logo.
  static Color get primary =>
      isAmar ? const Color(0xFF0B8FAC) : const Color(0xFF1E88E5);

  /// Secondary / accent colour. Reckon keeps its original orange (0xFFFF6F00);
  /// Amar uses the bright cyan from its logo to match the teal primary.
  static Color get secondary =>
      isAmar ? const Color(0xFF15C3DE) : const Color(0xFFFF6F00);
}
