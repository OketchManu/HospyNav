import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
             onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            }, // Navigates to settings
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to Use This App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '1. Profile Setup:\n'
                '   - To set up your profile, navigate to the profile section by tapping on your profile icon. Here, you can edit your personal information, including your username and profile picture.\n\n'
                '2. Finding Hospitals:\n'
                '   - Use the search function located at the top of the hospital list screen to find hospitals by name, specialty, or location. You can also browse the list of hospitals based on your current location.\n\n'
                '3. Emergency Contacts:\n'
                '   - Access emergency contacts by navigating to the settings menu. This feature allows you to save important phone numbers for quick reference in case of emergencies.\n\n'
                '4. Feedback:\n'
                '   - Provide feedback through the feedback option in the profile section. Your insights help us improve the app and serve you better.\n',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                'Frequently Asked Questions (FAQ)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Q: How do I change my username?\n'
                'A: Go to your profile, tap on the edit button, and update your username. Make sure to save your changes before leaving the page.\n\n'
                'Q: How do I upload a profile picture?\n'
                'A: Tap the camera icon on your profile picture. You can then choose to either take a new photo or select one from your gallery. Ensure your image meets the recommended size for optimal display.\n',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'If you need further assistance, please reach out to our support team:\n'
                '📧 Email: support@example.com\n'
                '📞 Phone: +254 700 000 000\n'
                'Our team is available from Monday to Friday, 9 AM to 5 PM (EAT).\n',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                'Follow Us',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Stay connected with us on social media for updates and tips:\n'
                '🔗 Facebook: [Facebook Page]\n'
                '🔗 Twitter: [Twitter Handle]\n'
                '🔗 Instagram: [Instagram Profile]\n',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
