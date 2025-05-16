import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: '***********');
  
  // Password change controllers
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isLoading = true;
  String _errorMessage = '';
  String? _profileImageUrl;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Load user data from Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Determine if logged in with Google
          bool isGoogleSignIn = false;
          for (var info in currentUser.providerData) {
            if (info.providerId == 'google.com') {
              isGoogleSignIn = true;
              break;
            }
          }

          setState(() {
            _nameController.text = isGoogleSignIn 
                ? (currentUser.displayName ?? '') 
                : (userData['name'] ?? '');

            _phoneController.text = userData['phone'] ?? ''; // May be empty for Google

            _emailController.text = userData['email'] ?? currentUser.email ?? '';
            
            // Get profile image URL
            _profileImageUrl = userData['profileImageUrl'] ?? currentUser.photoURL;
          });
        }
      } else {
        // User not logged in, redirect to login
        Navigator.pushReplacementNamed(context, '/sign_in');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile data';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        // Upload image immediately
        await _uploadProfileImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  // Upload image to Firebase Storage
  Future<void> _uploadProfileImage() async {
    if (_imageFile == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Create storage reference
      final storageRef = _storage.ref().child('profile_images/${currentUser.uid}');
      
      // Upload file
      final uploadTask = await storageRef.putFile(_imageFile!);
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Update user profile
      await currentUser.updatePhotoURL(downloadUrl);
      
      // Update Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': downloadUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _profileImageUrl = downloadUrl;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading image: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Save profile changes to Firestore
  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Show password change dialog
  void _showChangePasswordDialog() {
    // Reset controllers
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _changePassword();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
  
  // Change password functionality
  Future<void> _changePassword() async {
    // Validate passwords
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }
    
    // Check if new password is strong enough
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Create credential with current email and password
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _oldPasswordController.text,
      );
      
      // Re-authenticate user
      await currentUser.reauthenticateWithCredential(credential);
      
      // Update password
      await currentUser.updatePassword(_newPasswordController.text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Password change failed';
      
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'The new password is too weak';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Logout user
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/sign_in');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Logout button in app bar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Image with Edit button
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade100,
                            image: _profileImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImageUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 64,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _showImagePickerOptions,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF6366F1),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.red.shade100,
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  
                  if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
                  
                  // Form Fields
                  _buildFormField(label: 'Name', controller: _nameController),
                  const SizedBox(height: 16),
                  
                  _buildFormField(label: 'Phone', controller: _phoneController),
                  const SizedBox(height: 16),
                  
                  _buildFormField(
                    label: 'Email', 
                    controller: _emailController,
                    readOnly: true, // Email is usually not changed
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFormField(
                    label: 'Password', 
                    controller: _passwordController, 
                    obscureText: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _showChangePasswordDialog,
                    ),
                    readOnly: true, // Handle password change separately
                  ),
                  const SizedBox(height: 32),
                  
                  // Save button
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: _isLoading 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logout button
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}