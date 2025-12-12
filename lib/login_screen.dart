import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _idController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // --- MAIN CONTENT (Scrollable) ---
            Center(
              child: SingleChildScrollView(
                // Add bottom padding so content doesn't get hidden behind the pinned footer
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Ensures inputs fill width
                      children: [

                        // --- 1. CENTERED HEADER ---
                        Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.storefront,
                                size: 26,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Reckon Seller",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Sign in to access your dashboard",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // --- 2. INPUT FIELDS (Compact Typography) ---

                        // Seller ID
                        TextFormField(
                          controller: _idController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 14),
                          decoration: _materialDecoration(
                              context,
                              label: 'Seller ID',
                              hint: 'e.g. VEN-1023',
                              icon: Icons.badge_outlined
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Seller ID is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Mobile
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 14),
                          decoration: _materialDecoration(
                              context,
                              label: 'Mobile Number',
                              hint: '10-digit number',
                              icon: Icons.phone_android_outlined
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Mobile number is required';
                            if (v.length < 10) return 'Enter a valid 10-digit number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscure,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 14),
                          onFieldSubmitted: (_) => _login(),
                          decoration: _materialDecoration(
                              context,
                              label: 'Password',
                              hint: 'Enter your password',
                              icon: Icons.lock_outline
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isObscure = !_isObscure),
                            ),
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Password is required' : null,
                        ),

                        // --- 3. OPTIONS ---
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 20, width: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(() => _rememberMe = v!),
                                    activeColor: colorScheme.primary,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text("Remember me", style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: const Text("Forgot Password?", style: TextStyle(fontSize: 13)),
                            )
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- 4. LOGIN BUTTON ---
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _login,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                                : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- 5. PINNED FOOTER ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Powered by Reckon Software",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "v2.0.1 (Build 104)",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _materialDecoration(
      BuildContext context, {
        required String label,
        required String hint,
        required IconData icon,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),

      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      floatingLabelBehavior: FloatingLabelBehavior.auto,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }
}