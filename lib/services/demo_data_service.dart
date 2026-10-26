import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

/// Seeds / clears demo data for a user. Filled in at B11.
abstract interface class DemoDataService {}

class FirestoreDemoDataService implements DemoDataService {
  // ignore: unused_field
  final FirestorePaths _paths;

  FirestoreDemoDataService([FirebaseFirestore? firestore])
    : _paths = FirestorePaths(firestore ?? FirebaseFirestore.instance);
}
