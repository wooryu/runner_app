import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrewPage extends StatefulWidget {
  const CrewPage({Key? key}) : super(key: key);

  @override
  State<CrewPage> createState() => _CrewPageState();
}

class _CrewPageState extends State<CrewPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _crewNameController = TextEditingController();

  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Crew'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _crewNameController,
              decoration: InputDecoration(labelText: 'Crew Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createCrew,
              child: Text('Create Crew'),
            ),
          ],
        ),
      ),
    );
  }

  void _createCrew() async {
    if (_user != null && _crewNameController.text.isNotEmpty) {
      try {
        // Create the crew with timestamp
        DocumentReference crewRef = await _firestore.collection('crews').add({
          'name': _crewNameController.text.trim(),
          'creatorId': _user!.uid,
          'createdAt': FieldValue.serverTimestamp(), // Add timestamp
        });

        // Join the user to the crew
        await crewRef.collection('members').doc(_user!.uid).set({
          'email': _user!.email,
        });

        _crewNameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Crew created and joined successfully')),
        );
        // Navigate back to the home page
        Navigator.pop(context);
      } catch (e) {
        print('Error creating crew: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create crew')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid crew name')),
      );
    }
  }
}
