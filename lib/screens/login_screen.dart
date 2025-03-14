import 'package:flutter/material.dart';
import 'package:hospy_nav/services/auth.dart';
import 'package:hospy_nav/screens/forgot_password_screen.dart';
import 'package:hospy_nav/screens/register_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final Connectivity _connectivity = Connectivity();
  late TabController _tabController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _phonePasswordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePhonePassword = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneController = TextEditingController();
    _phonePasswordController = TextEditingController();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _phonePasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
  var connectivityResults = await _connectivity.checkConnectivity();
  setState(() {
    _isOnline = connectivityResults.isNotEmpty && 
                connectivityResults.any((result) => result != ConnectivityResult.none);
  });
}

  Future<void> _login(String identifier, String password) async {
    if (identifier.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter your ${identifier == _emailController.text ? "email" : "phone number"} and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithEmailOrPhone(
        identifier: identifier.trim(),
        password: password,
      );
      if (result != null || await _authService.isLoggedIn()) {
        _handleLoginSuccess();
      }
    } catch (e) {
      debugPrint('Raw login error: $e');
      String errorMessage = e.toString().contains('You are offline')
          ? 'You are offline. Cached login used if available.'
          : 'Login failed: ${e.toString()}';
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null || await _authService.isLoggedIn()) {
        _handleLoginSuccess();
      }
    } catch (e) {
      debugPrint('Raw Google login error: $e');
      String errorMessage = e.toString().contains('You are offline')
          ? 'You are offline. Cached login used if available.'
          : 'Google login failed: ${e.toString()}';
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLoginSuccess() {
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _togglePasswordVisibility(bool isPhonePassword) {
    setState(() {
      if (isPhonePassword) {
        _obscurePhonePassword = !_obscurePhonePassword;
      } else {
        _obscurePassword = !_obscurePassword;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/doctor-and-patient.jpg', fit: BoxFit.cover, alignment: Alignment.center),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'HospyNav',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (!_isOnline)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'You are offline',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [Tab(text: 'Email'), Tab(text: 'Phone')],
                    indicatorColor: Colors.black,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.black54,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEmailLoginForm(),
                        _buildPhoneLoginForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Colors.black)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(_emailController, 'Email', Icons.email),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true, isPhonePassword: false),
          const SizedBox(height: 16),
          _buildTextButton('Forgot Password?', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
          }),
          const SizedBox(height: 24),
          _buildLoginButton('Login with Email', () => _login(_emailController.text, _passwordController.text)),
          const SizedBox(height: 24),
          const Text('Or login with', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _buildSocialLoginButtons(),
          const SizedBox(height: 16),
          _buildTextButton('Don\'t have an account? Register', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildPhoneLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(_phoneController, 'Phone Number', Icons.phone, isPhone: true),
          const SizedBox(height: 16),
          _buildTextField(_phonePasswordController, 'Password', Icons.lock, isPassword: true, isPhonePassword: true),
          const SizedBox(height: 24),
          _buildLoginButton('Login with Phone', () => _login(_phoneController.text, _phonePasswordController.text)),
          const SizedBox(height: 24),
          const Text('Or login with', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _buildSocialLoginButtons(),
          const SizedBox(height: 16),
          _buildTextButton('Don\'t have an account? Register', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, bool isPhone = false, bool isPhonePassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? (isPhonePassword ? _obscurePhonePassword : _obscurePassword) : false,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPhonePassword
                      ? (_obscurePhonePassword ? Icons.visibility_off : Icons.visibility)
                      : (_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  color: Colors.black,
                ),
                onPressed: () => _togglePasswordVisibility(isPhonePassword),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
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

  Widget _buildLoginButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon('assets/icons/google.png', _loginWithGoogle),
      ],
    );
  }

  Widget _buildSocialIcon(String assetPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: _isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black54),
          color: Colors.white,
        ),
        child: Image.asset(assetPath, width: 40, height: 40),
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: _isLoading ? null : onPressed,
      child: Text(text, style: const TextStyle(color: Colors.black)),
    );
  }
}