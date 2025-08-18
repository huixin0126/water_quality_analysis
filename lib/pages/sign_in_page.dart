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
      print("Starting Google Sign-In process...");
      
      // First sign out of any previous Google sign-in to avoid caching issues
      await _googleSignIn.signOut();
      print("Signed out of previous Google session");
      
      // Trigger the Google Sign-In flow
      print("Triggering Google Sign-In...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If the user canceled the sign-in flow, return
      if (googleUser == null) {
        print("Google Sign-In was canceled by user");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("Google Sign In successful: ${googleUser.email}");
      print("Google user ID: ${googleUser.id}");

      // Obtain the auth details from the Google Sign In request
      print("Getting Google authentication tokens...");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Check if we got the tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print("Google authentication failed: accessToken=${googleAuth.accessToken != null}, idToken=${googleAuth.idToken != null}");
        throw Exception("Google authentication failed: Missing tokens");
      }

      print("Google tokens obtained successfully");

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Created Firebase credential, signing in to Firebase...");

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user (first time sign-in)
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      // Get user data
      User? user = userCredential.user;
      
      if (user != null) {
        print("Firebase auth successful: ${user.uid}");
        print("User email: ${user.email}");
        print("Is new user: $isNewUser");
        
        // Reference to the user document
        DocumentReference userRef = _firestore.collection('users').doc(user.uid);
        
        if (isNewUser) {
          // Create a new user document if this is the first sign-in
          print("Creating new user document in Firestore...");
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
          print("Updating existing user document in Firestore...");
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
          print("Navigating to home page...");
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception("Firebase user is null after successful authentication");
      }
    } catch (e) {
      print("Google sign in error: $e");
      print("Error type: ${e.runtimeType}");
      if (e is FirebaseAuthException) {
        print("Firebase Auth Error Code: ${e.code}");
        print("Firebase Auth Error Message: ${e.message}");
      }
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
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    bool isLoading = false;
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email address to receive a password reset link.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'Enter your email',
                    ),
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final email = resetEmailController.text.trim();
                              
                              // Validate email
                              if (email.isEmpty) {
                                setState(() {
                                  errorMessage = 'Please enter your email';
                                });
                                return;
                              }

                              // Basic email format validation
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(email)) {
                                setState(() {
                                  errorMessage = 'Please enter a valid email address';
                                });
                                return;
                              }

                              setState(() {
                                isLoading = true;
                                errorMessage = '';
                              });

                              try {
                                await _auth.sendPasswordResetEmail(email: email);
                                
                                if (context.mounted) {
                                  Navigator.of(context).pop(); // Close the dialog
                                  // Show success dialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Password Reset Email Sent'),
                                        content: const Text(
                                          'We have sent a password reset link to your email address. '
                                          'Please check your inbox and follow the instructions to reset your password.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                String message;
                                switch (e.code) {
                                  case 'user-not-found':
                                    message = 'No account found with this email address.';
                                    break;
                                  case 'invalid-email':
                                    message = 'The email address is not valid.';
                                    break;
                                  case 'too-many-requests':
                                    message = 'Too many attempts. Please try again later.';
                                    break;
                                  default:
                                    message = 'Failed to send reset email: ${e.message}';
                                }
                                setState(() {
                                  errorMessage = message;
                                });
                              } catch (e) {
                                setState(() {
                                  errorMessage = 'An unexpected error occurred. Please try again.';
                                });
                              } finally {
                                if (context.mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Reset Password'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
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
                    onPressed: _showForgotPasswordDialog,
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