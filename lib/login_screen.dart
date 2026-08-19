import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'constants/branding.dart';
import 'create_password_screen.dart';
import 'create_mpin_screen.dart';
import 'forgot_password_otp_screen.dart';
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/salesman_flags_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _licenseController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  // Secure storage to persist last used license and mobile
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _licenseController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedLicense = await _secureStorage.read(key: 'license');
      final savedMobile = await _secureStorage.read(key: 'mobile');
      if (savedLicense != null && savedLicense.isNotEmpty) {
        _licenseController.text = savedLicense.toUpperCase();
      }
      if (savedMobile != null && savedMobile.isNotEmpty) {
        // If savedMobile contains country code, strip it (we expect 10 digits)
        var mobile = savedMobile;
        if (mobile.startsWith('+')) {
          // remove + and country code if present
          mobile = mobile.replaceAll(RegExp(r'^\+\d+'), '');
        }
        if (mobile.length > 10) mobile = mobile.substring(mobile.length - 10);
        _mobileController.text = mobile;
      }
    } catch (e) {
      debugPrint('[LoginScreen] Failed to load saved credentials: $e');
    }
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      // Always call ValidateLicense API (password is optional - can be empty)
      final password = _passwordController.text.trim();
      debugPrint('[LoginScreen] Calling ValidateLicense with password: ${password.isEmpty ? "(empty)" : "(provided)"}');

      final result = await authService.validateLicense(
        licenseNumber: _licenseController.text.trim(),
        mobile: _mobileController.text.trim(),
        password: password, // Can be empty string
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      debugPrint('[LoginScreen] ValidateLicense result success: ${result['success']}');
      debugPrint('[LoginScreen] ValidateLicense result: $result');

      await _processLoginResult(result);
    }
  }

  bool _isTrue(dynamic v) => v == true || v?.toString().toLowerCase() == 'true';

  /// Pulls the other device's name out of the backend message, e.g.
  /// "User allready registered with other device realme RMX3388 want to change!".
  String _extractOtherDeviceName(String msg) {
    final m = RegExp(r'other device\s+(.*?)\s+want to change', caseSensitive: false).firstMatch(msg);
    return (m?.group(1) ?? '').trim();
  }

  /// Routes a ValidateLicense result: success → navigate; device-conflict
  /// (AllReadyLogin) → prompt to switch device; anything else → inline error.
  /// [allowDeviceChangePrompt] is false on the post-switch retry so a repeated
  /// conflict can't loop the dialog forever.
  Future<void> _processLoginResult(Map<String, dynamic> result, {bool allowDeviceChangePrompt = true}) async {
    if (result['success'] == true) {
      await _onLoginSuccess(result);
      return;
    }

    final data = result['data'];
    if (allowDeviceChangePrompt && data is Map && _isTrue(data['AllReadyLogin'])) {
      await _promptDeviceChange(data);
      return;
    }

    // Generic failure - show a clean inline error
    debugPrint('[LoginScreen] ValidateLicense FAILED: $result');
    String message = '';
    if (result['message'] != null && result['message'].toString().trim().isNotEmpty) {
      message = result['message'].toString();
    } else if (data is Map && data['Message'] != null) {
      message = data['Message'].toString();
    } else if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    }
    if (mounted) {
      setState(() => _errorMessage = _humanizeLoginError(message));
    }
  }

  /// Shows the "already signed in on another device" confirmation. On confirm,
  /// an OTP is sent to the account mobile and the user must enter it. Verifying
  /// the OTP with updatedevice_id:true (mirroring the old native app) unbinds the
  /// old device, binds this one, and logs the user in — all inside the single
  /// ValidateMobileOTP call. No separate ChangeDevice request is made.
  Future<void> _promptDeviceChange(Map data) async {
    final otherDevice = _extractOtherDeviceName(data['Message']?.toString() ?? '');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Already signed in elsewhere'),
        content: Text(
          otherDevice.isNotEmpty
              ? 'This account is currently active on "$otherDevice". Sign out from that device and continue on this one?'
              : 'This account is active on another device. Sign out from that device and continue on this one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue here'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final mobile = _mobileController.text.trim();
    final authService = Provider.of<AuthService>(context, listen: false);

    // CUID from the AllReadyLogin response — the old native app passes this back
    // as cu_id when verifying the device-change OTP.
    String cuid = '';
    final profile = data['Profile'];
    if (profile is Map && profile['CUID'] != null) {
      cuid = profile['CUID'].toString();
    }

    // 1) Send the OTP to the account's mobile before allowing the switch.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final otpSend = await authService.generateOTPForMobile(mobile: mobile);
    if (!mounted) return;
    setState(() => _isLoading = false);
    debugPrint('[LoginScreen] Device-change OTP send result: $otpSend');
    if (otpSend['success'] != true) {
      setState(() => _errorMessage =
          otpSend['message']?.toString() ?? 'Failed to send OTP. Please try again.');
      return;
    }

    // 2) Ask the user to enter the OTP that was just sent.
    final otp = await _promptOtpEntry(mobile);
    if (otp == null || !mounted) return; // user cancelled

    // 3) Verify the OTP with updatedevice_id:true. On success this unbinds the
    //    old device, binds this one, and returns the login profile/token.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final otpResult = await authService.validateMobileOTP(
      mobile: mobile,
      otp: otp,
      licenseNumber: _licenseController.text.trim(),
      cuId: cuid,
      updateDeviceId: true,
    );
    if (!mounted) return;
    debugPrint('[LoginScreen] Device-change OTP verify result: $otpResult');
    if (otpResult['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage = otpResult['message']?.toString() ?? 'Invalid OTP. Please try again.';
      });
      return;
    }

    // 4) OTP verified → re-run ValidateLicense with the credentials entered on
    //    the login screen. The ValidateMobileOTP response doesn't carry the full
    //    Profile/LicNo/Store data, so logging in off it leaves a blank license.
    //    Re-validating yields a clean, fully-populated session; changeDevice:true
    //    ensures the binding moves to this device.
    final retry = await authService.validateLicense(
      licenseNumber: _licenseController.text.trim(),
      mobile: mobile,
      password: _passwordController.text.trim(),
      changeDevice: true,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    debugPrint('[LoginScreen] Post-OTP ValidateLicense result: $retry');
    if (retry['success'] == true) {
      // Already-registered account → straight to Home, skip the setup screens.
      await _onLoginSuccess(retry, skipSetupGates: true);
    } else {
      setState(() => _errorMessage = _humanizeLoginError(
          retry['message']?.toString() ??
              'Could not complete sign-in after device change. Please try again.'));
    }
  }

  /// Dialog to enter the OTP sent for the device-change verification. Returns
  /// the entered OTP, or null if the user cancelled. Includes a "Resend OTP"
  /// action that re-triggers GenerateOTPForMobile.
  Future<String?> _promptOtpEntry(String mobile) async {
    final otpController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool resending = false;
        String? dialogError;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Verify it\'s you'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Enter the OTP sent to +91 $mobile to switch to this device.'),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    counterText: '',
                    errorText: dialogError,
                    prefixIcon: const Icon(Icons.sms_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: resending
                        ? null
                        : () async {
                            setDialogState(() => resending = true);
                            final auth = Provider.of<AuthService>(ctx, listen: false);
                            final r = await auth.generateOTPForMobile(mobile: mobile);
                            setDialogState(() {
                              resending = false;
                              dialogError = r['success'] == true ? null : 'Failed to resend OTP';
                            });
                          },
                    child: Text(resending ? 'Sending...' : 'Resend OTP'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final v = otpController.text.trim();
                  if (v.length < 4) {
                    setDialogState(() => dialogError = 'Enter a valid OTP');
                    return;
                  }
                  Navigator.pop(ctx, v);
                },
                child: const Text('Verify'),
              ),
            ],
          ),
        );
      },
    );
    otpController.dispose();
    return result;
  }

  /// Handles a successful ValidateLicense: persists creds, honours the
  /// create-password / create-mpin flags, fetches salesman flags, navigates home.
  ///
  /// [skipSetupGates] bypasses the create-password / create-mpin redirects and
  /// goes straight home. Used by the device-change flow: that account is already
  /// registered (it was logged in on another device), so it must not be sent to
  /// the first-time password/MPIN setup screens after switching devices.
  Future<void> _onLoginSuccess(Map<String, dynamic> result, {bool skipSetupGates = false}) async {
    // Persist license and mobile for autofill next time
    try {
      await _secureStorage.write(key: 'license', value: _licenseController.text.trim());
      await _secureStorage.write(key: 'mobile', value: _mobileController.text.trim());
    } catch (e) {
      debugPrint('[LoginScreen] Failed to save credentials: $e');
    }

    final data = result['data'];
    debugPrint('[LoginScreen] ValidateLicense success, data: $data');

    bool createPass = false;
    bool createMPin = false;
    if (data is Map) {
      final cpValue = data['CreatePasswd'];
      if (cpValue == true || (cpValue is String && cpValue.toLowerCase() == 'true')) {
        createPass = true;
      }
      final cmValue = data['CreateMPin'];
      if (cmValue == true || (cmValue is String && cmValue.toLowerCase() == 'true')) {
        createMPin = true;
      }
    }

    debugPrint('[LoginScreen] CreatePasswd=$createPass, CreateMPin=$createMPin, skipSetupGates=$skipSetupGates');
    if (!mounted) return;

    // Device-change logins are for already-registered accounts → go straight home.
    if (!skipSetupGates) {
      if (createPass) {
        debugPrint('[LoginScreen] Navigating to CreatePasswordScreen');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CreatePasswordScreen(
          mobile: _mobileController.text.trim(),
          licenseNumber: _licenseController.text.trim(),
        )));
        return;
      }
      if (createMPin) {
        debugPrint('[LoginScreen] Navigating to CreateMpinScreen');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CreateMpinScreen(
          mobile: _mobileController.text.trim(),
          licenseNumber: _licenseController.text.trim(),
        )));
        return;
      }
    }

    // Fetch salesman flags before navigating to home
    debugPrint('[LoginScreen] Fetching salesman flags...');
    final authService = Provider.of<AuthService>(context, listen: false);
    final flagsService = Provider.of<SalesmanFlagsService>(context, listen: false);
    final flagsSuccess = await flagsService.fetchAndCacheSalesmanFlags(
      authService: authService,
      packageName: authService.packageNameHeader,
    );
    debugPrint('[LoginScreen] Salesman flags fetched: $flagsSuccess');

    if (!mounted) return;
    debugPrint('[LoginScreen] Navigating to HomeScreen');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  /// Strips noise (license code, role prefix) the API tacks onto error
  /// messages like "ONS97131SalesManInvalid Password, try again!".
  String _humanizeLoginError(String raw) {
    var msg = raw.trim();
    final lic = _licenseController.text.trim();
    if (lic.isNotEmpty && msg.toUpperCase().startsWith(lic.toUpperCase())) {
      msg = msg.substring(lic.length).trim();
    }
    msg = msg.replaceFirst(RegExp(r'^\s*sales\s*man\s*', caseSensitive: false), '').trim();
    return msg.isEmpty ? 'Login failed. Please try again.' : msg;
  }

  Future<void> _openResetPassword() async {
    FocusScope.of(context).unfocus();
    final mob = _mobileController.text.trim();
    if (mob.length != 10) {
      setState(() => _errorMessage = 'Enter your 10-digit mobile number to reset password.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.generateOTPForMobile(mobile: mob);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordOtpScreen(mobile: mob),
          ),
        );
      } else {
        setState(() => _errorMessage = result['message']?.toString() ?? 'Failed to send OTP. Try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Hide the "Powered by" footer while the keyboard is open so it doesn't
    // ride up above the keyboard — it should only sit at the bottom.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Ensures inputs fill width
                      children: [

                        // --- 1. CENTERED HEADER ---
                        Column(
                          children: [
                            Image.asset(
                              Branding.logo,
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              Branding.appName,
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

                        // License Number
                        TextFormField(
                          controller: _licenseController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.toUpperCase(),
                              ),
                            ),
                          ],
                          style: const TextStyle(fontSize: 14),
                          decoration: _materialDecoration(
                              context,
                              label: 'License Number',
                              hint: 'e.g. ONS07726',
                              icon: Icons.badge_outlined
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'License number is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Mobile
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: const TextStyle(fontSize: 14),
                          onFieldSubmitted: (_) => _sendOTP(),
                          decoration: _materialDecoration(
                              context,
                              label: 'Mobile Number',
                              hint: '10-digit number',
                              icon: Icons.phone_android_outlined
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Mobile number is required';
                            if (v.length != 10) return 'Enter a valid 10-digit number';
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),
                        // Optional Password - if filled, app will attempt direct login with ValidateLicense
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 14),
                          decoration: _materialDecoration(
                              context,
                              label: 'Password',
                              hint: 'Enter password to login directly',
                              icon: Icons.lock_outline
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        // --- ERROR BANNER ---
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline_rounded, size: 20, color: colorScheme.error),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // --- 3. LOGIN BUTTON ---
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _sendOTP,
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

                        // --- FORGOT PASSWORD LINK ---
                        Center(
                          child: TextButton(
                            onPressed: _isLoading ? null : _openResetPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: colorScheme.primary,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- 5. PINNED FOOTER (hidden while the keyboard is open) ---
            if (!keyboardOpen)
              Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Powered by",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Image.asset(
                      'assets/images/reckon_powered.jpg',
                      height: 56,
                      fit: BoxFit.contain,
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
