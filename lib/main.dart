

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:movie_aidea/screens/auth.dart';
import 'package:movie_aidea/screens/splash.dart';
import 'package:movie_aidea/screens/user_dashboard.dart';
import 'firebase_options.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //_initializeAndSignIn();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
                seedColor: Color.fromARGB(255, 11, 99, 205),
                brightness: Brightness.dark)
            .copyWith(
                secondary: Color.fromARGB(255, 15, 46, 108),
                brightness: Brightness.dark),
        useMaterial3: true,
        // Default text theme for the entire app
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.poppins(), // Default body text
          bodyMedium: GoogleFonts.poppins(), // Alternative body text
          bodySmall: GoogleFonts.poppins(), // Small body text
          headlineLarge: GoogleFonts.poppins(), // Large headlines
          headlineMedium: GoogleFonts.poppins(), // Medium headlines
          headlineSmall: GoogleFonts.poppins(), // Small headlines
          titleLarge: GoogleFonts.poppins(), // Large titles
          titleMedium: GoogleFonts.poppins(), // Medium titles
          titleSmall: GoogleFonts.poppins(), // Small titles
          labelLarge: GoogleFonts.poppins(), // Large labels (buttons)
          labelMedium: GoogleFonts.poppins(), // Medium labels (buttons)
          labelSmall: GoogleFonts.poppins(), // Small labels (buttons)
        ),
      ),

      // ThemeData(

      // ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }

          if (snapshot.hasData) {
            // User user = snapshot.data!;

            return UserDashboard(
              userCredentials: snapshot.data!,
            );
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
