import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DatabaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  // Create new user document
  Future<void> createUserDocument({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      await users.doc(uid).set({
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'phoneNumber': phoneNumber,
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isOnline': true,
        'fcmTokens': [],
      });
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      
      await users.doc(uid).update(updateData);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(String uid, File imageFile) async {
    try {
      final String fileName = 'profile_pictures/$uid.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      await users.doc(uid).update({'photoURL': downloadURL});
      
      return downloadURL;
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }

  // Get user data
  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await users.doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        throw Exception('User document not found');
      }
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    try {
      await users.doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }

  // Update FCM token
  Future<void> updateFCMToken(String uid, String token) async {
    try {
      await users.doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }

  // Remove FCM token
  Future<void> removeFCMToken(String uid, String token) async {
    try {
      await users.doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }

  // Delete user data
  Future<void> deleteUserData(String uid) async {
    try {
      try {
        await _storage.ref().child('profile_pictures/$uid.jpg').delete();
      } catch (e) {
        // Ignore if file doesn't exist
      }
      
      await users.doc(uid).delete();
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }

  // Handle Database Exceptions
  String _handleDatabaseException(dynamic e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'You don\'t have permission to access this resource.';
        case 'not-found':
          return 'The requested resource was not found.';
        case 'already-exists':
          return 'A document already exists with the specified ID.';
        case 'failed-precondition':
          return 'Operation was rejected due to the current system state.';
        case 'aborted':
          return 'The operation was aborted.';
        case 'out-of-range':
          return 'Operation was attempted past the valid range.';
        case 'unauthenticated':
          return 'User is not authenticated.';
        case 'unavailable':
          return 'Service is currently unavailable. Please try again later.';
        default:
          return 'An error occurred while accessing the database: ${e.message ?? "Unknown error"}';
      }
    }
    return 'An unexpected error occurred: $e';
  }
}