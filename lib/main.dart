// filepath: /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0/lib/main.dart
import 'login_screen.dart';
import 'home_screen.dart';
import 'app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'auth_service.dart';
import 'dashboard_service.dart';
import 'services/account_selection_service.dart';
import 'services/salesman_flags_service.dart';

// Platform channel for screenshot prevention (mobile only)
const platform = MethodChannel('com.reckon.reckonbiz/screenshot');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AccountSelectionService()),
        ChangeNotifierProvider(create: (_) => SalesmanFlagsService()),
        ProxyProvider<AuthService, DashboardService>(
          update: (_, authService, __) => DashboardService(authService),
        ),
      ],
      child: Consumer<SalesmanFlagsService>(
        builder: (context, flagsService, _) {
          final enableScreenshot = flagsService.flags?.enableScreenshot ?? true;

          debugPrint('[MyApp] enable_screenshot flag: $enableScreenshot');

          // Apply screenshot protection immediately (skip on web)
          if (!enableScreenshot) {
            debugPrint('[MyApp] Disabling screenshots...');
            _disableScreenshot();
          } else {
            debugPrint('[MyApp] Enabling screenshots...');
            _enableScreenshot();
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: appNavigatorKey,
            title: 'Reckon BIZ360',
            theme: ThemeData(
              useMaterial3: true,
              // Modern Blue-Orange theme with Material Design 3
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E88E5), // Modern vibrant blue
                brightness: Brightness.light,
                secondary: const Color(0xFFFF6F00), // Vibrant orange
                surface: const Color(0xFFFAFBFC),
                surfaceContainerHighest: const Color(0xFFF0F2F5),
              ),
              // Enhanced AppBar styling
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.black,
                elevation: 2,
                scrolledUnderElevation: 4,
                shadowColor: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                centerTitle: false,
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
                iconTheme: const IconThemeData(
                  color: Colors.black,
                  size: 24,
                ),
                actionsIconTheme: const IconThemeData(
                  color: Colors.black,
                  size: 24,
                ),
              ),
              // Enhanced input decoration theme globally for consistency
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey.withAlpha(13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              // Enhanced button styling
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF1E88E5).withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Enhanced text button styling
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Enhanced outlined button styling
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E88E5),
                  side: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Enhanced typography
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF212121),
                  letterSpacing: -0.5,
                ),
                displayMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF212121),
                  letterSpacing: -0.25,
                ),
                displaySmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
                headlineLarge: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF212121),
                  letterSpacing: 0.25,
                ),
                headlineMedium: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
                headlineSmall: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
                titleLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                  letterSpacing: 0.15,
                ),
                titleMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                  letterSpacing: 0.1,
                ),
                titleSmall: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                  letterSpacing: 0.1,
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                  height: 1.5,
                  letterSpacing: 0.15,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF616161),
                  height: 1.43,
                  letterSpacing: 0.25,
                ),
                bodySmall: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF757575),
                  height: 1.33,
                  letterSpacing: 0.4,
                ),
                labelLarge: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E88E5),
                  letterSpacing: 0.1,
                ),
                labelMedium: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E88E5),
                  letterSpacing: 0.5,
                ),
                labelSmall: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E88E5),
                  letterSpacing: 0.5,
                ),
              ),
              // Enhanced card styling
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 2,
                shadowColor: const Color(0xFF000000).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.zero,
              ),
              // Enhanced dialog styling
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: const Color(0xFF000000).withValues(alpha: 0.15),
                backgroundColor: Colors.white,
              ),
              // Enhanced floating action button styling
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Enhanced snackbar styling
              snackBarTheme: SnackBarThemeData(
                backgroundColor: const Color(0xFF212121),
                contentTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              // Enhanced checkbox styling
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF1E88E5);
                  }
                  return Colors.grey.shade300;
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(color: Colors.grey.shade400, width: 1.5),
              ),
              // Enhanced radio button styling
              radioTheme: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF1E88E5);
                  }
                  return Colors.grey.shade400;
                }),
              ),
            ),
        home: const AuthWrapper(),
      );
        },
      ),
    );
  }

  Future<void> _disableScreenshot() async {
    // Skip on web platform
    if (!_isNativePlatform()) {
      debugPrint('[MyApp] Skipping screenshot disable on web platform');
      return;
    }

    try {
      debugPrint('[MyApp] Invoking platform method: disableScreenshot');
      await platform.invokeMethod('disableScreenshot');
      debugPrint('[MyApp] ✅ Screenshot disabled successfully');
    } catch (e) {
      debugPrint('[MyApp] ❌ Error disabling screenshot: $e');
    }
  }

  Future<void> _enableScreenshot() async {
    // Skip on web platform
    if (!_isNativePlatform()) {
      debugPrint('[MyApp] Skipping screenshot enable on web platform');
      return;
    }

    try {
      debugPrint('[MyApp] Invoking platform method: enableScreenshot');
      await platform.invokeMethod('enableScreenshot');
      debugPrint('[MyApp] ✅ Screenshot enabled successfully');
    } catch (e) {
      debugPrint('[MyApp] ❌ Error enabling screenshot: $e');
    }
  }

  /// Check if running on native platform (not web)
  bool _isNativePlatform() {
    try {
      return !(identical(0, 0.0)) && (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    } catch (e) {
      // If any error, assume web
      return false;
    }
  }
}

// AuthWrapper to handle auto-login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _isPromptingMpin = false; // debounce to avoid multiple prompts
  DateTime? _appPausedAt; // Track when app was paused
  static const int _mpinPromptDelaySeconds = 30; // Minimum 30 seconds before showing MPIN

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // App is being minimized/paused
      _appPausedAt = DateTime.now();
      debugPrint('[AppLifecycle] App paused at: $_appPausedAt');
    } else if (state == AppLifecycleState.resumed) {
      // App is being resumed
      debugPrint('[AppLifecycle] App resumed at: ${DateTime.now()}');
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    try {
      if (!mounted) return;
      if (_isChecking) return;
      if (_isPromptingMpin) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated) return;

      // Check if app was paused for at least 30 seconds
      if (_appPausedAt != null) {
        final pausedDuration = DateTime.now().difference(_appPausedAt!);
        debugPrint('[AppLifecycle] App was paused for: ${pausedDuration.inSeconds} seconds');

        if (pausedDuration.inSeconds < _mpinPromptDelaySeconds) {
          debugPrint('[AppLifecycle] App paused for less than $_mpinPromptDelaySeconds seconds, skipping MPIN prompt');
          _appPausedAt = null; // Reset the pause time
          return;
        }
      } else {
        debugPrint('[AppLifecycle] No pause timestamp recorded, skipping MPIN prompt');
        return;
      }

      _isPromptingMpin = true;
      // Try to get mobile from currentUser or stored token payload
      String mobile = authService.currentUser?.mobileNumber ?? '';
      mobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      if (mobile.length > 10) mobile = mobile.substring(mobile.length - 10);

      debugPrint('[AppLifecycle] Prompting MPIN after ${ _mpinPromptDelaySeconds}s+ pause');
      // Only validate MPIN on resume/start. Refresh should happen only when token is actually expired (handled by interceptors).
      final ok = await authService.promptForMpinAndRefresh(mobile: mobile, refreshOnSuccess: false);
      if (!ok) {
        // Logout and show login screen
        await authService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      }
    } catch (e) {
      debugPrint('Error during resume MPIN check: $e');
    } finally {
      _appPausedAt = null; // Reset the pause time
      _isPromptingMpin = false;
    }
  }

  Future<void> _checkAuth() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.tryAutoLogin();

      // If we have stored credentials, require MPIN validation on app start.
      if (authService.isAuthenticated) {
        // Try to get mobile from currentUser or stored token payload
        String mobile = authService.currentUser?.mobileNumber ?? '';
        // Normalize mobile: keep digits only and last 10
        mobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
        if (mobile.length > 10) mobile = mobile.substring(mobile.length - 10);

        // On app start, only validate MPIN; do not attempt refresh here.
        final ok = await authService.promptForMpinAndRefresh(mobile: mobile, refreshOnSuccess: false);
        if (!ok) {
          await authService.logout();
        } else {
          // MPIN validated successfully, load cached salesman flags
          final flagsService = Provider.of<SalesmanFlagsService>(context, listen: false);
          await flagsService.loadCachedFlags();
          debugPrint('[AuthWrapper] Cached salesman flags loaded');
        }
      }
    } catch (e) {
      debugPrint('Auto-login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Reckon BIZ360',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// Add a route for OrderBookPage (if using named routes, otherwise just use Navigator.push)
// Example usage: Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderBookPage()));
