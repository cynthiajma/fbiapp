import 'package:flutter/material.dart';
// NOTE: Ensure your import path for SamanthaPage is correct. 
// Assuming it's in the 'pages' directory with the filename 'sweat.dart'.
import 'package:fbi_app/pages/sweat.dart'; 
import 'package:fbi_app/pages/rock.dart';
// import 'package:fbi_app/pages/login_screen.dart'; // Commented out
// import 'package:fbi_app/pages/character_library_page.dart'; // Commented out

// If you need constants for the theme, keep them here or import them:
class CharacterConstants {
  static const String samanthaSweat = 'Samantha Sweat';
  static const String rickyTheRock = 'Ricky the Rock';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FBI App',
      theme: ThemeData(
        // Use your actual theme data here
        primarySwatch: Colors.blue,
      ),
      // -----------------------------------------------------------------
      // FIX APPLIED HERE: Sets the home page directly to SamanthaPage.
      // This bypasses any login or navigation logic.
      // -----------------------------------------------------------------
      home: const RickyPage(), // <--- NEW line for testing the sweat page
    );
  }
}