import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Sign up with email and password
  Future<void> _signUp() async {
    // Validate name and phone are not empty
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Name and phone number cannot be empty';
      });
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    // Validate email and password are not empty
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save user data to Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Navigate to home page
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/sign_in');
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sign Up Title
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Create Account Text
                const Text(
                  'Create an account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
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
                
                // Name Field
                TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Enter your full name',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Phone Field
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'Enter phone number',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'Enter email',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Enter password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Enter password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Terms and Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                        });
                      },
                    ),
                    const Text('I agree with '),
                    TextButton(
                      onPressed: () {
                        // Show terms and conditions
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Sign Up Button
                ElevatedButton(
                  onPressed: _agreeTerms && !_isLoading
                      ? _signUp
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign Up'),
                ),
                
                const SizedBox(height: 16),
                
                // OR Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Google Sign Up Button
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle Google sign up
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Sign up with Google'),
                ),
                
                const SizedBox(height: 16),
                
                // Facebook Sign Up Button
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle Facebook sign up
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3b5998),
                  ),
                  icon: const Icon(Icons.facebook, size: 24),
                  label: const Text('Sign up with Facebook'),
                ),
                
                const SizedBox(height: 24),
                
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/sign_in');
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}