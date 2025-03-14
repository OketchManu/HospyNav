import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hospy_nav/screens/home_screen.dart';
import 'package:hospy_nav/screens/login_screen.dart';
import 'package:hospy_nav/services/auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math' as math;

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  AuthenticationWrapperState createState() => AuthenticationWrapperState();
}

class AuthenticationWrapperState extends State<AuthenticationWrapper> with SingleTickerProviderStateMixin {
  late AuthService _authService;
  final Connectivity _connectivity = Connectivity();
  bool _isChecking = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _crossAnimation;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _crossAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkConnectivityAndLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivityAndLoginStatus() async {
  setState(() {
    _isChecking = true;
    _errorMessage = null;
  });

  try {
    var connectivityResults = await _connectivity.checkConnectivity();
    setState(() => _isOnline = connectivityResults.isNotEmpty && 
                              connectivityResults.any((result) => result != ConnectivityResult.none));

    if (kDebugMode) print('Starting login status check');
    await _authService.initialize();
    await _authService.tryAutoLogin();
    if (kDebugMode) print('Login status check completed');
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to check login status: $e';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? 'Unknown error occurred')),
      );
    }
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black87,
                Colors.deepPurple.shade900,
                Colors.indigo.shade900,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: StarFieldPainter(),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _crossAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _crossAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.cyanAccent.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Welcome to HospyNav',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent,
                            blurRadius: 10,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Find care, anywhere',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (!_isOnline)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          'Offline Mode',
                          style: TextStyle(fontSize: 16, color: Colors.yellowAccent),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'PLEASE WAIT...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black87,
                Colors.deepPurple.shade900,
                Colors.indigo.shade900,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checkConnectivityAndLoginStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black87,
                    Colors.deepPurple.shade900,
                    Colors.indigo.shade900,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }
        if (snapshot.hasData && _authService.currentUser != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random();
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}