import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/color.dart';

class SubmittedAssignmentsPage extends StatefulWidget {
  const SubmittedAssignmentsPage({super.key});

  @override
  State<SubmittedAssignmentsPage> createState() =>
      _SubmittedAssignmentsPageState();
}

class _SubmittedAssignmentsPageState extends State<SubmittedAssignmentsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _getSubmittedAssignments() async {
    final submissionsSnapshot = await _db.collection('submissions').get();
    final assignmentsSnapshot = await _db.collection('assignments').get();
    final studentsSnapshot =
        await _db.collection('users').where('role', isEqualTo: 'student').get();

    final assignmentsMap = {
      for (var doc in assignmentsSnapshot.docs) doc.id: doc.data()
    };
    final studentsMap = {
      for (var doc in studentsSnapshot.docs) doc.id: doc.data()
    };

    List<Map<String, dynamic>> result = [];
    for (var doc in submissionsSnapshot.docs) {
      final submission = doc.data();
      final student = studentsMap[submission['studentId']] ?? {};
      final assignment = assignmentsMap[submission['assignmentId']] ?? {};
      result.add({
        'studentName': student['name'] ?? submission['studentId'],
        'assignmentTitle': assignment['title'] ?? submission['assignmentId'],
        'submittedAt': (submission['submittedAt'] as Timestamp?)?.toDate(),
        'status': submission['status'] ?? 'pending',
        'grade': submission['grade'],
        'totalGrade': assignment['totalGrade'],
      });
    }
    return result;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submitted Assignments')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getSubmittedAssignments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final submissions = snapshot.data!;
          if (submissions.isEmpty) {
            return const Center(child: Text('No submitted assignments found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final item = submissions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(item['status'] ?? 'pending'),
                    child: Text(
                      item['studentName'].toString().isNotEmpty
                          ? item['studentName'][0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(item['studentName'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assignment: ${item['assignmentTitle']}'),
                      if (item['submittedAt'] != null)
                        Text('Submitted: ${formatDate(item['submittedAt'])}'),
                      Text('Status: ${item['status']}'),
                      Text(
                          'Grade: ${item['grade'] ?? '-'} / ${item['totalGrade'] ?? '-'}'),
                    ],
                  ),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
