// filepath: /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0/lib/main.dart
import 'login_screen.dart';
import 'home_screen.dart';
import 'app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'dashboard_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ProxyProvider<AuthService, DashboardService>(
          update: (_, authService, __) => DashboardService(authService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        title: 'Reckon BIZ360',
        theme: ThemeData(
          useMaterial3: true,
          // Using a sophisticated Teal/Blue seed
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006C70),
            brightness: Brightness.light,
          ),
          // Customizing the input decoration theme globally for consistency
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.withAlpha(13), // Very subtle fill
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none, // No border by default (cleaner look)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF006C70), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// AuthWrapper to handle auto-login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.tryAutoLogin();
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
