import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logging/logging.dart';
import 'package:hospy_nav/services/auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger('RegisterScreen');
  final Connectivity _connectivity = Connectivity();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late AnimationController _animationController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });

    _animationController = AnimationController(vsync: this);
    _logger.info('RegisterScreen initialized');
    _checkConnectivity();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    _logger.info('RegisterScreen disposed');
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
  var connectivityResults = await _connectivity.checkConnectivity();
  setState(() {
    _isOnline = connectivityResults.isNotEmpty && 
                connectivityResults.any((result) => result != ConnectivityResult.none);
  });
}

  void _showCustomDialog({
    required String title,
    required String message,
    required Color titleColor,
    required IconData icon,
    VoidCallback? onDismiss,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: titleColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: Colors.black87, fontSize: 14)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (onDismiss != null) onDismiss();
                  },
                  child: Text('Okay', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter an email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(value)) {
      return 'Password must include letters, numbers, and special characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a phone number';
    if (!RegExp(r'^(?:\+254|0)[1-9]\d{8}$').hasMatch(value)) {
      return 'Enter a valid phone number (e.g., +2547XXXXXXXX or 07XXXXXXXX)';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showCustomDialog(
        title: 'Password Mismatch',
        message: 'The passwords you entered do not match.',
        titleColor: Colors.orange,
        icon: Icons.warning_rounded,
      );
      return;
    }
    if (!_isOnline) {
      _showCustomDialog(
        title: 'Offline',
        message: 'You need an internet connection to register.',
        titleColor: Colors.red,
        icon: Icons.wifi_off,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
      );
      _handleSuccess();
    } catch (e) {
      _logger.severe('Raw registration error: $e');
      _showCustomDialog(
        title: 'Registration Failed',
        message: e.toString(),
        titleColor: Colors.red,
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    if (!_isOnline) {
      _showCustomDialog(
        title: 'Offline',
        message: 'You need an internet connection to register with Google.',
        titleColor: Colors.red,
        icon: Icons.wifi_off,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      _handleSuccess();
    } catch (e) {
      _logger.severe('Raw Google registration error: $e');
      _showCustomDialog(
        title: 'Google Registration Failed',
        message: e.toString(),
        titleColor: Colors.red,
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSuccess() {
    _showCustomDialog(
      title: 'Success',
      message: 'Account created successfully!',
      titleColor: Colors.green,
      icon: Icons.check_circle_rounded,
      onDismiss: () => Navigator.of(context).pushReplacementNamed('/home'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isOnline)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'You are offline - Registration requires internet',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Center(
                        child: Lottie.asset(
                          'assets/animations/signup.json',
                          controller: _animationController,
                          width: 200,
                          height: 200,
                          onLoaded: (composition) {
                            _animationController
                              ..duration = composition.duration
                              ..forward();
                          },
                        ),
                      ).animate().fade(duration: 500.ms).slideY(begin: 0.5, end: 0),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 10.0, color: Colors.black26, offset: const Offset(2.0, 2.0)),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fade(duration: 500.ms).slideY(begin: 0.5, end: 0),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: FontAwesomeIcons.envelope,
                        validator: _validateEmail,
                      ).animate().fade(duration: 500.ms).slideX(begin: -0.5, end: 0),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: FontAwesomeIcons.phone,
                        validator: _validatePhone,
                        keyboardType: TextInputType.phone,
                      ).animate().fade(duration: 500.ms).slideX(begin: 0.5, end: 0),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: FontAwesomeIcons.lock,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                      ).animate().fade(duration: 500.ms).slideX(begin: 0.5, end: 0),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: FontAwesomeIcons.lock,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        validator: _validatePassword,
                        onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ).animate().fade(duration: 500.ms).slideX(begin: -0.5, end: 0),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.deepPurple.shade900,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.deepPurple)
                            : const Text(
                                'Register',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ).animate().fade(duration: 500.ms),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Text(
                            'Or register with',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _socialButton(
                                onTap: _isLoading ? null : _registerWithGoogle,
                                icon: FontAwesomeIcons.google,
                                backgroundColor: Colors.white,
                                iconColor: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ).animate().fade(duration: 500.ms).slideY(begin: 0.5, end: 0),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: Text(
                          'Already have an account? Log In',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ).animate().fade(duration: 500.ms).slideY(begin: 0.5, end: 0),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.deepPurple),
                onPressed: onToggleVisibility,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _socialButton({
    required VoidCallback? onTap,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), spreadRadius: 2, blurRadius: 5)],
        ),
        child: Icon(icon, color: iconColor, size: 36),
      ),
    );
  }
}