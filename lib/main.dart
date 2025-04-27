import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

// Import all screen files
import 'pages/welcome_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/analysis_page.dart';
import 'pages/filter_prediction_page.dart';
import 'pages/water_analysis_page.dart';
import 'pages/water_analysis_result_page.dart';
import 'pages/water_turbidity_page.dart';
import 'pages/filter_search_page.dart';
import 'pages/reminder_page.dart';
import 'pages/set_reminder_page.dart';
import 'pages/water_intake_reminder_page.dart';

void main() {
  runApp(const WaterQualityApp());
}

class WaterQualityApp extends StatelessWidget {
  const WaterQualityApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Water Quality',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      home: const WelcomePage(),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/sign_in': (context) => const SignInPage(),
        '/sign_up': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/analysis': (context) => const AnalysisPage(),
        '/filter_prediction': (context) => const FilterPredictionPage(),
        '/water_analysis': (context) => const WaterAnalysisPage(),
        '/water_analysis_result': (context) => const WaterAnalysisResultPage(),
        '/water_turbidity': (context) => const WaterTurbidityPage(),
        '/filter_search': (context) => const FilterSearchPage(),
        '/reminder': (context) => const ReminderPage(),
        '/set_reminder': (context) => const SetReminderPage(),
        '/water_intake_reminder': (context) => const WaterIntakeReminderPage(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
    );
  }
}

// Bottom Navigation Widget that will be used across screens
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({Key? key, required this.currentIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF6366F1),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/analysis');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/filter_search');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/filter_prediction');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/water_intake_reminder');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.science_outlined),
          label: 'Analysis',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.filter_alt_outlined),
          label: 'Check Filter',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time_outlined),
          label: 'Reminder',
        ),
      ],
    );
  }
}