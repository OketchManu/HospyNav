import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hospy_nav/main.dart'; // Adjust import based on your structure

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = false;
  bool _isDarkMode = false;
  double _textSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _locationTrackingEnabled = prefs.getBool('locationTracking') ?? false;
      _textSize = prefs.getDouble('textSize') ?? 16.0;
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notifications', _notificationsEnabled);
    prefs.setBool('locationTracking', _locationTrackingEnabled);
    prefs.setDouble('textSize', _textSize);
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  void _toggleNotifications(bool? value) {
    setState(() {
      _notificationsEnabled = value ?? true;
      _saveSettings();
    });
  }

  void _toggleLocationTracking(bool? value) {
    setState(() {
      _locationTrackingEnabled = value ?? false;
      _saveSettings();
    });
  }

  void _toggleDarkMode(bool? value) {
    setState(() {
      _isDarkMode = value ?? false;
      _saveSettings();
      HospyNavApp.setThemeMode(context, _isDarkMode);
    });
  }

  void _adjustTextSize(double value) {
    setState(() {
      _textSize = value;
      _saveSettings();
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('About HospyNav', style: TextStyle(color: Colors.tealAccent)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HospyNav v1.0', style: TextStyle(color: Colors.white)),
              SizedBox(height: 10),
              Text('A hospital finder app to help you locate healthcare services in Kenya.',
                  style: TextStyle(color: Colors.white)),
              SizedBox(height: 10),
              Text('Developed by HospyNav Team', style: TextStyle(color: Colors.white)),
              Text('© 2025 All Rights Reserved', style: TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close', style: TextStyle(color: Colors.tealAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Privacy Policy', style: TextStyle(color: Colors.tealAccent)),
          content: const SingleChildScrollView(
            child: Text(
              'At HospyNav, we are committed to protecting your privacy. '
              'We collect minimal personal information necessary to provide our services. '
              'Your location data is used only for finding nearby hospitals and can be disabled at any time.',
              style: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close', style: TextStyle(color: Colors.tealAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Logout', style: TextStyle(color: Colors.tealAccent)),
          content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.tealAccent)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D47A1), // Deep cosmic blue
                Color(0xFF311B92), // Dark purple nebula
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8.0, // Adds a futuristic shadow
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [
                    Colors.black, // Deep space black
                    Color(0xFF1A237E), // Indigo night sky
                    Color(0xFF4A148C), // Galactic purple
                  ]
                : [
                    Color(0xFF0D1B2A), // Dark starry blue
                    Color(0xFF1B263B), // Midnight blue
                    Color(0xFF415A77), // Lighter cosmic shade
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Appearance Section
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent, // Neon accent for futuristic feel
              ),
            ),
            SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              activeColor: Colors.tealAccent,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey[700],
            ),

            // Notifications Section
            const SizedBox(height: 20),
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            SwitchListTile(
              title: const Text('Enable Notifications', style: TextStyle(color: Colors.white)),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: Colors.tealAccent,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey[700],
            ),

            // Location Tracking Section
            const SizedBox(height: 20),
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            SwitchListTile(
              title: const Text('Enable Location Tracking', style: TextStyle(color: Colors.white)),
              value: _locationTrackingEnabled,
              onChanged: _toggleLocationTracking,
              activeColor: Colors.tealAccent,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey[700],
            ),

            // Text Size Section
            const SizedBox(height: 20),
            const Text(
              'Text Size',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            Slider(
              value: _textSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              label: _textSize.round().toString(),
              onChanged: _adjustTextSize,
              activeColor: Colors.tealAccent,
              inactiveColor: Colors.grey[700],
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.tealAccent),

            // Additional Options
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.tealAccent),
              title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
              onTap: _showPrivacyPolicy,
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.tealAccent),
              title: const Text('About', style: TextStyle(color: Colors.white)),
              onTap: _showAboutDialog,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.tealAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}