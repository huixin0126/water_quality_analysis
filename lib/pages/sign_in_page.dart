import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Make sure scopes include email at minimum
    scopes: ['email'],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Sign in with email and password
  Future<void> _signInWithEmailAndPassword() async {
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
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update last login timestamp
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        }).catchError((error) {
          // Handle case where document might not exist yet
          print("User document does not exist yet: $error");
          // Create the document if it doesn't exist
          return _firestore.collection('users').doc(userCredential.user!.uid).set({
            'email': userCredential.user!.email,
            'lastLogin': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        // Navigate to home page
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
      print("Sign-in error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sign in with Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First sign out of any previous Google sign-in to avoid caching issues
      await _googleSignIn.signOut();
      
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If the user canceled the sign-in flow, return
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("Google Sign In successful: ${googleUser.email}");

      // Obtain the auth details from the Google Sign In request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Check if we got the tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception("Google authentication failed: Missing tokens");
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user (first time sign-in)
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      // Get user data
      User? user = userCredential.user;
      
      if (user != null) {
        print("Firebase auth successful: ${user.uid}");
        
        // Reference to the user document
        DocumentReference userRef = _firestore.collection('users').doc(user.uid);
        
        if (isNewUser) {
          // Create a new user document if this is the first sign-in
          await userRef.set({
            'email': user.email,
            'displayName': user.displayName ?? '',
            'photoURL': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'provider': 'google',
          });
          print("New user document created in Firestore");
        } else {
          // Update existing user information
          await userRef.update({
            'lastLogin': FieldValue.serverTimestamp(),
          }).catchError((error) {
            // Handle case where document might not exist yet despite user not being new
            print("Updating user document failed: $error");
            return userRef.set({
              'email': user.email,
              'displayName': user.displayName ?? '',
              'photoURL': user.photoURL ?? '',
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'provider': 'google',
            });
          });
          print("Existing user document updated in Firestore");
        }
        
        // Navigate to home page
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print("Google sign in error: $e");
      setState(() {
        _errorMessage = 'Failed to sign in with Google: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle forgot password
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email to reset password';
      });
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Failed to send reset email: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sign In Title
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Welcome Back Text
                const Text(
                  'Welcome back',
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
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Sign In Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign In'),
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
                
                // Google Sign In Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Continue with Google'),
                ),
                
                const SizedBox(height: 16),
                
                // Facebook Sign In Button
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle Facebook sign in
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3b5998),
                  ),
                  icon: const Icon(Icons.facebook, size: 24),
                  label: const Text('Continue with Facebook'),
                ),
                
                const SizedBox(height: 24),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/sign_up');
                      },
                      child: const Text(
                        'Sign up',
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