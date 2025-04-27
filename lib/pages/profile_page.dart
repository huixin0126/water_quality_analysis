import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController(text: 'James Harrid');
  final TextEditingController _phoneController = TextEditingController(text: '123-456-7890');
  final TextEditingController _emailController = TextEditingController(text: 'example@email.com');
  final TextEditingController _passwordController = TextEditingController(text: '***********');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      ),
      body: SingleChildScrollView(
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1),
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
            
            // Form Fields
            _buildFormField(label: 'Name', controller: _nameController),
            const SizedBox(height: 16),
            
            _buildFormField(label: 'Phone', controller: _phoneController),
            const SizedBox(height: 16),
            
            _buildFormField(label: 'Email', controller: _emailController),
            const SizedBox(height: 16),
            
            _buildFormField(
              label: 'Password', 
              controller: _passwordController, 
              obscureText: true,
              suffixIcon: const Icon(Icons.visibility_off),
            ),
            const SizedBox(height: 32),
            
            // Save button
            ElevatedButton(
              onPressed: () {
                // Save profile logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              },
              child: const Text('Save changes'),
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
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}