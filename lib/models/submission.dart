import 'package:cloud_firestore/cloud_firestore.dart';

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? fileUrl;
  final DateTime submittedAt;
  final String? grade;
  final String? remarks;
  final String status; // pending, approved, rejected

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.fileUrl,
    required this.submittedAt,
    this.grade,
    this.remarks,
    this.status = 'pending',
  });

  factory Submission.fromMap(Map<String, dynamic> map, String id) {
    return Submission(
      id: id,
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      fileUrl: map['fileUrl'],
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      grade: map['grade'],
      remarks: map['remarks'],
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'fileUrl': fileUrl,
      'submittedAt': submittedAt,
      'grade': grade,
      'remarks': remarks,
      'status': status,
    };
  }

  Submission copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? fileUrl,
    DateTime? submittedAt,
    String? grade,
    String? remarks,
    String? status,
  }) {
    return Submission(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      fileUrl: fileUrl ?? this.fileUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      grade: grade ?? this.grade,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
    );
  }
}
