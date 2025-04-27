import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Water Drop Icon
              const Icon(
                Icons.water_drop_outlined,
                size: 80,
                color: Colors.black,
              ),
              const SizedBox(height: 24),
              
              // Welcome Text
              const Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // App Name
              const Text(
                'AI Water Quality',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Tagline
              const Text(
                'Smart Monitoring,\nSafer Water',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Get Started Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/sign_in');
                },
                child: const Text('Get Start !'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}