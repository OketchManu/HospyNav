import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileUploadHandler {
  final FirebaseFirestore _firestore;

  ProfileUploadHandler({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, String?>> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      await _firestore.collection('users').doc(userId).update({
        'photoBase64': base64Image,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return {
        'photoBase64': base64Image,
      };
    } catch (e) {
      throw 'Failed to upload profile picture: $e';
    }
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  File? _imageFile;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _photoBase64;
  Map<String, dynamic> _userData = {};
  bool _hasLocalChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    if (_hasLocalChanges) {
      _saveLocalChanges();
    }
    super.dispose();
  }

  void _onUsernameChanged() {
    setState(() => _hasLocalChanges = true);
    _saveToLocalCache({
      'username': _usernameController.text,
      'lastModified': DateTime.now().toIso8601String(),
    });
    _saveLocalChanges();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    await _loadFromLocalCache();

    try {
      final userData = await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        setState(() {
          _userData = data;
          _usernameController.text = data['username'] ?? 'User Name';
          _photoBase64 = data['photoBase64'] as String?;
        });
        _saveToLocalCache(data);
      } else {
        final initialData = {
          'username': user.displayName ?? 'User Name',
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('users').doc(user.uid).set(initialData);
        setState(() {
          _userData = initialData;
          _usernameController.text = initialData['username'] as String;
        });
        _saveToLocalCache(initialData);
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      if (user == null) return;

      final cachedUsername = prefs.getString('${user.uid}_username');
      final cachedPhotoBase64 = prefs.getString('${user.uid}_photoBase64');
      final cachedImagePath = prefs.getString('${user.uid}_imagePath');
      final hasPendingChanges = prefs.getBool('${user.uid}_hasPendingChanges') ?? false;

      if (cachedUsername != null) {
        setState(() {
          _usernameController.text = cachedUsername;
          _photoBase64 = cachedPhotoBase64;
          _hasLocalChanges = hasPendingChanges;
          _userData['username'] = cachedUsername;
          if (cachedPhotoBase64 != null) _userData['photoBase64'] = cachedPhotoBase64;
          if (cachedImagePath != null && File(cachedImagePath).existsSync()) {
            _imageFile = File(cachedImagePath);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error loading from cache: $e');
    }
  }

  Future<void> _saveToLocalCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      if (user == null) return;

      await prefs.setString('${user.uid}_username', data['username'] ?? '');
      if (data['photoBase64'] != null) {
        await prefs.setString('${user.uid}_photoBase64', data['photoBase64']);
      }
      if (data['imagePath'] != null) {
        await prefs.setString('${user.uid}_imagePath', data['imagePath']);
      }
      await prefs.setBool('${user.uid}_hasPendingChanges', true);
    } catch (e) {
      _showSnackBar('Error saving to cache: $e');
    }
  }

  Future<void> _saveLocalChanges() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String? photoBase64 = _photoBase64;

      if (_imageFile != null && (_photoBase64 == null || _imageFile!.path != _photoBase64)) {
        final bytes = await _imageFile!.readAsBytes();
        photoBase64 = base64Encode(bytes);
      }

      final updates = {
        'username': _usernameController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
        if (photoBase64 != null) 'photoBase64': photoBase64,
      };

      await _firestore.collection('users').doc(user.uid).update(updates);
      setState(() {
        _photoBase64 = photoBase64;
        _userData = {..._userData, ...updates};
        _hasLocalChanges = false;
      });
      _saveToLocalCache(updates);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${user.uid}_hasPendingChanges', false);
    } catch (e) {
      _showSnackBar('Error saving changes: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${user.uid}_hasPendingChanges', true);
      setState(() => _hasLocalChanges = true);
    }
  }

  Future<void> _saveUserProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await _saveLocalChanges();
    setState(() => _isLoading = false);
    _showSnackBar('Profile saved successfully');
  }

  Future<void> _pickMedia(ImageSource source) async {
  final status = await _requestPermission(source);
  if (!status.isGranted) {
    _showSnackBar('Permission denied');
    return;
  }

  try {
    setState(() => _isLoading = true);

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final user = _auth.currentUser;

      if (user == null) {
        _showSnackBar('User not authenticated');
        return;
      }


      final uploadHandler = ProfileUploadHandler(firestore: _firestore);
      final result = await uploadHandler.uploadProfilePicture(
        userId: user.uid,
        imageFile: imageFile,
      );

      setState(() {
        _imageFile = imageFile;
        _photoBase64 = result['photoBase64'];
        _hasLocalChanges = true;
      });

      await _saveToLocalCache({
        'photoBase64': result['photoBase64'],
        'imagePath': pickedFile.path,
      });

      _showSnackBar('Profile picture updated successfully');
    }
  } catch (e) {
    _showSnackBar('Error: $e');
    if (kDebugMode) {
      print('Upload error details: $e');
    }
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<PermissionStatus> _requestPermission(ImageSource source) async {
    return source == ImageSource.camera
        ? await Permission.camera.request()
        : await Permission.photos.request();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMediaSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildBottomSheetOption(
              icon: Icons.camera_alt,
              title: 'Take a photo',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _pickMedia(ImageSource.camera);
              },
            ),
            _buildBottomSheetOption(
              icon: Icons.photo_library,
              title: 'Choose from gallery',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _pickMedia(ImageSource.gallery);
              },
            ),
            if (_photoBase64 != null || _imageFile != null)
              _buildBottomSheetOption(
                icon: Icons.delete,
                title: 'Remove profile picture',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _removeProfilePicture();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.alphaBlend((color ?? Colors.blue).withValues(alpha:0.1), Colors.white),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color ?? Colors.blue),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeProfilePicture() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'photoBase64': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${user.uid}_photoBase64');
      await prefs.remove('${user.uid}_imagePath');
      await prefs.setBool('${user.uid}_hasPendingChanges', false);

      setState(() {
        _imageFile = null;
        _photoBase64 = null;
        _userData.remove('photoBase64');
        _hasLocalChanges = false;
      });

      _showSnackBar('Profile picture removed');
    } catch (e) {
      _showSnackBar('Error removing profile picture: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(user.uid).delete();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await user.delete();

      _showSnackBar('Account permanently deleted');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnackBar(
          'Please log out and log back in to delete your account due to security requirements.',
        );
      } else {
        _showSnackBar('Error deleting account: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('Error deleting account: $e');
    } finally {
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      if (_hasLocalChanges) {
        await _saveLocalChanges();
      }
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      _showSnackBar('Error logging out: $e');
    }
  }

  void _showLogoutDialog() {
    _showCustomDialog(
      title: 'Log Out',
      content: 'Are you sure you want to log out? Any unsaved changes will be preserved.',
      confirmText: 'Log Out',
      onConfirm: _logout,
    );
  }

  void _showDeleteAccountDialog() {
    _showCustomDialog(
      title: 'Delete Account',
      content: 'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be removed.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      onConfirm: () async {
        await _deleteUserProfile();
      },
    );
  }

  void _showCustomDialog({
    required String title,
    required String content,
    required String confirmText,
    Color? confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor ?? Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget buildProfilePhoto() {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _imageFile != null
            ? Image.file(
                _imageFile!,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
                key: ValueKey(_imageFile!.path),
              )
            : _photoBase64 != null
                ? Image.memory(
                    base64Decode(_photoBase64!),
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                    key: ValueKey(_photoBase64),
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 60),
                  )
                : const Icon(Icons.person, size: 60, color: Colors.white70),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blue),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.purple[300]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                child: ClipOval(child: buildProfilePhoto()),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showMediaSourceDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha:0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                            ),
                          ],
                          border: Border.all(
                            color: _isEditing ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your username',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          readOnly: !_isEditing,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Username cannot be empty' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_isEditing) {
                              _saveUserProfile();
                            }
                            setState(() => _isEditing = !_isEditing);
                          },
                          icon: Icon(_isEditing ? Icons.save : Icons.edit),
                          label: Text(_isEditing ? 'Save' : 'Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha:0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildProfileOption(
                              icon: Icons.notifications,
                              title: 'Notifications',
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/notifications'),
                            ),
                            Divider(height: 1, color: Colors.grey[200]),
                            _buildProfileOption(
                              icon: Icons.help,
                              title: 'Help & Support',
                              onTap: () => Navigator.of(context).pushNamed('/help'),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout),
                        label: const Text('Log Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showDeleteAccountDialog,
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isLast ? 16 : 0),
        bottomRight: Radius.circular(isLast ? 16 : 0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}