import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:runner_app/pages/user_page.dart';
import 'package:sign_in_button/sign_in_button.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((event) {
      if (this.mounted) {
        setState(() {
          _user = event;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _user != null ? Text(_user!.email!) : const Text("Login"),
      ),
      body: Center(
        child: MaterialButton(
            color: Colors.deepPurple,
            child: const Text("Sign Out"),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
              _auth.signOut();
            }),
      ),
    );
  }
}
