import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String createdBy;
  final String? fileUrl;
  final int totalGrade;
  final String subject;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.createdBy,
    this.fileUrl,
    this.totalGrade = 30,
    required this.subject,
  });

  factory Assignment.fromMap(Map<String, dynamic> map, String id) {
    return Assignment(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      fileUrl: map['fileUrl'],
      totalGrade: map['totalGrade'] ?? 30,
      subject: map['subject'] ?? 'Theory of Computation',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'createdBy': createdBy,
      'fileUrl': fileUrl,
      'totalGrade': totalGrade,
      'subject': subject,
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      createdBy: json['createdBy'] ?? '',
      fileUrl: json['fileUrl'],
      totalGrade: json['totalGrade'] ?? 30,
      subject: json['subject'] ?? 'Theory of Computation',
    );
  }
}
