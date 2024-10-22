import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_task/controllers/SignUpController.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  var userForm = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      //------------------------body start------------------------//

      body: SingleChildScrollView(
        child: Form(
          key: userForm,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset('assets/images/logo.png'),
                ),
                TextFormField(
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Name is requird";
                    }
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      label: Text("Name"),
                      border: OutlineInputBorder()),
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Eamil is requird";
                    }
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      label: Text("Email"),
                      border: OutlineInputBorder()),
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: countryController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Country is requird";
                    }
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      label: Text("Country"),
                      border: OutlineInputBorder()),
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is requird";
                    }
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.password,
                      ),
                      label: Text("Password"),
                      border: OutlineInputBorder()),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (userForm.currentState!.validate()) {
                      // create account //
                      isLoading = true;
                      setState(() {});
                      SignUpController().createAccount(
                          context: context,
                          email: emailController.text,
                          password: passwordController.text,
                          country: countryController.text,
                          name: nameController.text);
                    }
                  },
                  child: isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text("Create Account"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
