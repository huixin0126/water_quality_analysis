import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _errorMessage = '';

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
          .collection('user')
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
          
          // If you want, you can also store/display the photoURL
          // _photoUrl = currentUser.photoURL ?? '';
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
  
  // Save profile changes to Firestore
  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        await _firestore.collection('user').doc(currentUser.uid).update({
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
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
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
                      icon: const Icon(Icons.visibility_off),
                      onPressed: () {
                        // Change password logic would go here
                        // Usually opens a separate dialog or screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password change feature coming soon')),
                        );
                      },
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