# HospyNav - Hospital Navigation and Healthcare services finder App

## Overview
HospyNav is a mobile application designed to provide accessible and reliable information about hospital locations, services, and navigation assistance. The app integrates real-time mapping, hospital details, emergency contact information, and first aid videos to enhance the healthcare-seeking experience for users.

DOWNLOAD APK: https://www.mediafire.com/file/zq6a18dyu1hm08p/HospyNav.apk/file

## Features
- **User Authentication**: Sign up and log in using Facebook, Google, email, or phone number (with password for phone login).
- **Hospital Search & Details**: View hospital information, including name, location, available services, and contact details.
- **Navigation Assistance**: Get directions to the nearest or selected hospital using OpenRoute API and RapidAPI Google Maps.
- **Emergency Contacts**: Quick access to emergency numbers and contacts.
- **First Aid Videos**: Educational videos on basic first aid practices.
- **User Feedback**: Submit reviews and feedback about hospitals.

## Tech Stack
- **Frontend**: Flutter (Dart)
- **Database/backend**: Firestore
- **Authentication**: Firebase Authentication (Google, Facebook, Email, Phone Number)
- **Maps & Navigation**: OpenRoute API & RapidAPI Google Maps

## Installation Guide
### Prerequisites
Ensure you have the following installed on your system:
- Flutter SDK (`C:/dev/flutter`)
- Dart
- Firebase CLI
- Android Studio / Visual Studio Code (for development)

### Steps to Run the Project
1. **Clone the Repository**:
   ```sh
   git clone https://github.com/yourusername/hospynav.git
   cd hospynav
   ```

2. **Install Dependencies**:
   ```sh
   flutter pub get
   ```

3. **Set Up Firebase**:
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in respective directories.
   - Enable authentication methods in Firebase Console.

4. **Configure API Keys**:
   - Set up OpenRoute API key in `maps_service.dart`.
   - Register and obtain a Google Maps API key via RapidAPI, then configure it in `maps_service.dart`.

5. **Run the Application**:
   ```sh
   flutter run
   ```

## Folder Structure
```
lib/
│── auth/
│   ├── screens/            # Login and Register pages
│   ├── auth_service.dart   # Authentication logic
│── screens/
│   ├── home_screen.dart    # Home page UI
│   ├── hospital_finder_screen.dart  # List of hospitals
│   ├── navigation.dart     # Maps & navigation page
│   ├── first_aid_videos.dart      # First aid videos section
│   ├── feedback_screen.dart
│   ├── settings_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── emergency_contacts_screen.dart
│   ├── notifications_screen.dart
│   ├── help_screen.dart
│── services/
│   ├── authentication_wrapper.dart
│   ├── auth.dart 
│── main.dart                 # App entry point
```

## API Integration
- **Hospital Data**: Fetches hospital details from the Kenya Ministry of Health Facility Registry.
- **OpenRoute API**: Provides route calculation and navigation assistance.
- **RapidAPI Google Maps**: Enables real-time mapping and hospital location services.

## Troubleshooting
- If you encounter issues with OpenRoute API, verify the API key in `maps_service.dart`.
- For Google Maps errors, ensure your API key is correctly configured in RapidAPI and Firebase Console.
- Authentication issues? Double-check Firebase configurations and credentials.

## Contribution
1. Fork the repository.
2. Create a new branch: `git checkout -b feature-branch`
3. Commit changes: `git commit -m "Add new feature"`
4. Push to the branch: `git push origin feature-branch`
5. Submit a pull request.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact
For any inquiries or support, please reach out via email: `oemmanuelodiwuor@example.com`

