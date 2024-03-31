import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrewDetailsPage extends StatefulWidget {
  final String crewId;

  const CrewDetailsPage({Key? key, required this.crewId}) : super(key: key);

  @override
  _CrewDetailsPageState createState() => _CrewDetailsPageState();
}

class _CrewDetailsPageState extends State<CrewDetailsPage> {
  late bool _isMember = false;
  late String _crewName = '';
  late bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    // Check if the current user is a member of the crew
    _checkMembership();
    // Fetch the name of the crew
    _fetchCrewName();
    // Check if the current user is the creator of the crew
    _checkCreator();
  }

  Future<void> _checkMembership() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('crews')
        .doc(widget.crewId)
        .collection('members')
        .doc(userId)
        .get();
    setState(() {
      _isMember = snapshot.exists;
    });
  }

  Future<void> _fetchCrewName() async {
    final crewDoc = await FirebaseFirestore.instance
        .collection('crews')
        .doc(widget.crewId)
        .get();
    if (crewDoc.exists) {
      setState(() {
        _crewName = crewDoc['name'];
      });
    }
  }

  Future<void> _checkCreator() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final crewDoc = await FirebaseFirestore.instance
        .collection('crews')
        .doc(widget.crewId)
        .get();
    if (crewDoc.exists) {
      print('Creator ID: ${crewDoc['creatorId']}');
      print('Current User ID: $userId');
      setState(() {
        _isCreator = crewDoc['creatorId'] == userId;
      });
    }
  }

  Future<void> _joinOrLeaveCrew() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final memberRef = FirebaseFirestore.instance
        .collection('crews')
        .doc(widget.crewId)
        .collection('members')
        .doc(userId);

    if (_isMember) {
      // User is already a member, leave the crew
      await memberRef.delete();
    } else {
      // User is not a member, join the crew
      await memberRef.set({
        'userId': userId,
        'email': FirebaseAuth.instance.currentUser!.email,
      });
    }
    // Update membership status
    _checkMembership();
  }

  Future<void> _deleteCrew() async {
    await FirebaseFirestore.instance
        .collection('crews')
        .doc(widget.crewId)
        .delete();
    Navigator.pop(
        context); // Navigate back to the home page after deleting the crew
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_crewName), // Display the crew name in the app bar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: MemberList(crewId: widget.crewId, isCreator: _isCreator),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _joinOrLeaveCrew,
                  child: Text(_isMember ? 'Leave Crew' : 'Join Crew'),
                ),
                SizedBox(width: 16),
                if (_isCreator)
                  ElevatedButton(
                    onPressed: _deleteCrew,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    child: Text('Delete Crew'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MemberList extends StatelessWidget {
  final String crewId;
  final bool isCreator;

  const MemberList({Key? key, required this.crewId, required this.isCreator})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('crews')
          .doc(crewId)
          .collection('members')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No members in this crew.'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var memberDoc = snapshot.data!.docs[index];
            var memberEmail = memberDoc['email'] ?? 'Unknown';
            return ListTile(
              title: Text(memberEmail),
              onTap: () {
                // Only show kick dialog if the current user is the creator
                if (isCreator) {
                  _showKickMemberDialog(context, memberDoc.id);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<String> _fetchCreatorId() async {
    final crewDoc =
        await FirebaseFirestore.instance.collection('crews').doc(crewId).get();
    return crewDoc['creatorId'];
  }

  Future<void> _showKickMemberDialog(
      BuildContext context, String memberId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final creatorId = await _fetchCreatorId(); // Fetch the creator ID

    // Check if the current user is the creator and the member being kicked is not the creator
    if (currentUser != null &&
        currentUser.uid == creatorId &&
        memberId != creatorId) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Kick Member?'),
            content: Text(
                'Are you sure you want to kick this member from the crew?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _kickMemberFromCrew(memberId);
                  Navigator.of(context).pop();
                },
                child: Text('Kick'),
              ),
            ],
          );
        },
      );
    }
  }

  void _kickMemberFromCrew(String memberId) async {
    await FirebaseFirestore.instance
        .collection('crews')
        .doc(crewId)
        .collection('members')
        .doc(memberId)
        .delete();
  }
}
