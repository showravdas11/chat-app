import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:my_task/Screens/ChatRooms.dart'; // Import ChatRooms screen
import 'package:my_task/Screens/SignUpScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: FutureBuilder<User?>(
        future: _getUser(),
        builder: (context, snapshot) {
          // Show a loading indicator while checking user status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If the user is logged in, navigate to ChatRooms, otherwise to SignUpScreen
          if (snapshot.hasData && snapshot.data != null) {
            return const ChatRooms();
          } else {
            return const SignUpScreen();
          }
        },
      ),
    );
  }

  // Method to get the current user
  Future<User?> _getUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return currentUser;
  }
}
