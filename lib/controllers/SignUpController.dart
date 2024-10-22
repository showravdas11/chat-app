import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_task/Screens/ChatRooms.dart';

class SignUpController {
  void createAccount({
    required BuildContext context,
    required String email,
    required String password,
    required String country,
    required String name,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      var userId = FirebaseAuth.instance.currentUser!.uid;

      var db = FirebaseFirestore.instance;

      Map<String, dynamic> data = {
        "name": name,
        "email": email,
        "country": country,
        "id": userId.toString()
      };
      try {
        await db.collection("users").doc(userId.toString()).set(data);
      } catch (e) {
        print(e);
      }
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ChatRooms()),
          (route) => false);

      print("Account created successfully");
    } catch (e) {
      SnackBar messageSnackbar =
          SnackBar(backgroundColor: Colors.red, content: Text(e.toString()));
      ScaffoldMessenger.of(context).showSnackBar(messageSnackbar);
    }
  }
}
