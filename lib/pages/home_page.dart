import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:runner_app/pages/crew_details_page.dart';
import 'package:runner_app/pages/crew_page.dart';
import 'package:runner_app/pages/user_page.dart';
import 'package:runner_app/services/firestore.dart';
import 'package:sign_in_button/sign_in_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService firestoreService = FirestoreService();
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

  final TextEditingController textController = TextEditingController();
  void openCrewBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          content: TextField(
            controller: textController,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                firestoreService.addCrew(textController.text);
                textController.clear();
                Navigator.pop(context);
              },
              child: Text("Create"),
            )
          ]),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _user != null ? const Text("Crews") : const Text("Login"),
        actions: [
          if (_user != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserPage()),
                ),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(_user!.photoURL!),
                  radius: 25,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _user != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CrewPage()),
                );
              },
              child: const Icon(Icons.add))
          : const Text(""),
      body: _user != null ? _crewList() : _googleSignInButton(),
    );
  }

  Widget _googleSignInButton() {
    return Center(
        child: SizedBox(
            height: 50,
            child: SignInButton(Buttons.google,
                text: "Sign in with Google", onPressed: _handleGoogleSignIn)));
  }

  Widget _crewList() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Expanded(
            child: CrewList(),
          ),
        ],
      ),
    );
  }

  void _handleGoogleSignIn() {
    try {
      GoogleAuthProvider _googleAuthProvider = GoogleAuthProvider();
      _auth.signInWithProvider(_googleAuthProvider);
    } catch (error) {
      print(error);
    }
  }
}

class CrewList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('crews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No crews available.'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var crewDoc = snapshot.data!.docs[index];
            var crewId = crewDoc.id;
            var crewName = crewDoc['name'] ?? 'No Name';
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CrewDetailsPage(crewId: crewId),
                  ),
                );
              },
              child: ListTile(
                title: Text(crewName),
              ),
            );
          },
        );
      },
    );
  }
}
