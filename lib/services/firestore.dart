import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  //CRUD
  final CollectionReference crews =
      FirebaseFirestore.instance.collection('crews');

  Future<void> addCrew(String crew) {
    return crews.add({
      'crew': crew,
      'timestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getCrewsStream() {
    final crewsStream =
        crews.orderBy('timestamp', descending: true).snapshots();
    return crewsStream;
  }
}
