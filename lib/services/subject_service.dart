import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class SubjectService {
  static const String subjectsBoxName = 'subjectsBox';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Default subjects
  static const List<String> defaultSubjects = [
    'Theory of Computation',
    'Web Programming',
    'System Software',
  ];

  // Get all subjects from local storage
  Future<List<String>> getSubjects() async {
    final box = await Hive.openBox(subjectsBoxName);
    final subjects = box.get('subjects', defaultValue: defaultSubjects);
    return List<String>.from(subjects);
  }

  // Add a new subject
  Future<void> addSubject(String subject) async {
    final box = await Hive.openBox(subjectsBoxName);
    final subjects =
        List<String>.from(box.get('subjects', defaultValue: defaultSubjects));

    if (!subjects.contains(subject)) {
      subjects.add(subject);
      await box.put('subjects', subjects);

      // Also save to Firestore for sync across devices
      try {
        await _db.collection('subjects').doc('list').set({
          'subjects': subjects,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving subjects to Firestore: $e');
      }
    }
  }

  // Remove a subject
  Future<void> removeSubject(String subject) async {
    final box = await Hive.openBox(subjectsBoxName);
    final subjects =
        List<String>.from(box.get('subjects', defaultValue: defaultSubjects));

    if (subjects.contains(subject)) {
      subjects.remove(subject);
      await box.put('subjects', subjects);

      // Also update Firestore
      try {
        await _db.collection('subjects').doc('list').set({
          'subjects': subjects,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating subjects in Firestore: $e');
      }
    }
  }

  // Sync subjects from Firestore
  Future<void> syncSubjects() async {
    try {
      final doc = await _db.collection('subjects').doc('list').get();
      if (doc.exists && doc.data() != null) {
        final subjects =
            List<String>.from(doc.data()!['subjects'] ?? defaultSubjects);
        final box = await Hive.openBox(subjectsBoxName);
        await box.put('subjects', subjects);
      }
    } catch (e) {
      print('Error syncing subjects: $e');
    }
  }

  // Initialize subjects (call this on app startup)
  Future<void> initializeSubjects() async {
    final box = await Hive.openBox(subjectsBoxName);
    if (!box.containsKey('subjects')) {
      await box.put('subjects', defaultSubjects);
    }
  }
}
