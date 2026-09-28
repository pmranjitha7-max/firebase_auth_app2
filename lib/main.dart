import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'home_page.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Auth App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.deepPurple,
              width: 2,
            ),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
            borderSide: BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
        ),
      ),

      // IMPORTANT:
      // Do NOT use LoginPage directly here.
      // AuthGate decides whether to show LoginPage or HomePage.
      home: const AuthGate(),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================
//
// This checks Firebase every time the application starts.
//
// If a user is already logged in:
//     -> HomePage
//
// If nobody is logged in:
//     -> LoginPage
//
// If an email/password user is not verified:
//     -> LoginPage
//
// Google users are treated as verified.
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _isEmailVerified(User user) {
    // Google accounts do not need our email-verification
    // screen because Google has already authenticated the account.
    final isGoogleUser = user.providerData.any(
          (provider) => provider.providerId == 'google.com',
    );

    if (isGoogleUser) {
      return true;
    }

    return user.emailVerified;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase is still checking the authentication state.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // No Firebase user is signed in.
        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        // User exists but email is not verified.
        if (!_isEmailVerified(user)) {
          return const LoginPage();
        }

        // User is already authenticated and verified.
        return const HomePage();
      },
    );
  }
}