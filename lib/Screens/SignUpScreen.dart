import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_task/Screens/ChatRooms.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: const Color(0xFF005544),
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _signInAnonymously,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF005544)),
                  ),
                )
              : const Text("sign In Anonymously"),
        ),
      ),
    );
  }

  void _signInAnonymously() {
    setState(() {
      _isLoading = true;
    });

    FirebaseAuth.instance
        .signInAnonymously()
        .then((UserCredential userCredential) {
      String userId = userCredential.user!.uid;
      FirebaseFirestore.instance.collection('anonymous').doc(userId).set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      }).then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatRooms()),
        );
      }).catchError((e) {
        print("Error saving user data: $e");
      }).whenComplete(() {
        setState(() {
          _isLoading = false;
        });
      });
    }).catchError((e) {
      print("Error during sign-in: $e");
      setState(() {
        _isLoading = false;
      });
    });
  }
}
