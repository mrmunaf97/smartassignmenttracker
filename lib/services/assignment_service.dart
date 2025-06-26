import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../models/submission.dart';

class AssignmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Assignments
  Future<void> createAssignment(Assignment assignment) async {
    await _db.collection('assignments').add(assignment.toMap());
  }

  Stream<List<Assignment>> getAssignments() {
    return _db.collection('assignments').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => Assignment.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Submissions
  Future<void> submitAssignment(Submission submission) async {
    await _db.collection('submissions').add(submission.toMap());
  }

  Stream<List<Submission>> getSubmissionsForAssignment(String assignmentId) {
    return _db
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Submission.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Submission>> getSubmissionsForStudent(String studentId) {
    return _db
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Submission.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _db.collection('assignments').doc(assignmentId).delete();
  }

  Future<void> updateSubmission(Submission submission) async {
    await _db
        .collection('submissions')
        .doc(submission.id)
        .update(submission.toMap());
  }
}
