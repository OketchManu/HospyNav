import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isOnline;
  final List<String> fcmTokens;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoURL,
    required this.createdAt,
    required this.lastLogin,
    required this.isOnline,
    required this.fcmTokens,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isOnline': isOnline,
      'fcmTokens': fcmTokens,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    DateTime? lastLogin,
    bool? isOnline,
    List<String>? fcmTokens,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isOnline: isOnline ?? this.isOnline,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}