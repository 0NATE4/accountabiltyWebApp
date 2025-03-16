import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCLxYLOz2XuEJm8tgpAZAfx3fvfU_nC4SI',
        appId: '1:941733393242:web:5223cf7ef1cb69e5757963',
        messagingSenderId: '941733393242',
        projectId: 'accountabilitywebapp',
        authDomain: 'accountabilitywebapp.firebaseapp.com',
        storageBucket: 'accountabilitywebapp.firebasestorage.app',
        measurementId: 'G-X515E1X61C',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accountability App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
} 