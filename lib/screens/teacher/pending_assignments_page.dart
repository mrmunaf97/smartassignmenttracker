import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../models/assignment.dart';
import '../../services/subject_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingAssignmentsPage extends StatefulWidget {
  const PendingAssignmentsPage({super.key});

  @override
  State<PendingAssignmentsPage> createState() => _PendingAssignmentsPageState();
}

class _PendingAssignmentsPageState extends State<PendingAssignmentsPage> {
  final AssignmentService _assignmentService = AssignmentService();
  final SubjectService _subjectService = SubjectService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedSubject = 'All';
  List<String> _subjects = ['All'];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _subjectService.getSubjects();
    setState(() {
      _subjects = ['All', ...subjects];
    });
  }

  Future<List<Map<String, dynamic>>> _getPendingStudents() async {
    final assignmentsSnapshot = await _db.collection('assignments').get();
    final studentsSnapshot =
        await _db.collection('users').where('role', isEqualTo: 'student').get();
    List<Map<String, dynamic>> pendingList = [];

    for (var assignmentDoc in assignmentsSnapshot.docs) {
      final assignmentData = assignmentDoc.data();
      final dueDate = (assignmentData['dueDate'] as Timestamp).toDate();
      final subject = assignmentData['subject'] ?? '';
      if (dueDate.isAfter(DateTime.now()) &&
          (_selectedSubject == 'All' || subject == _selectedSubject)) {
        final assignmentId = assignmentDoc.id;
        final submissionsSnapshot = await _db
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .get();
        final submittedStudentIds =
            submissionsSnapshot.docs.map((doc) => doc['studentId']).toSet();
        for (var studentDoc in studentsSnapshot.docs) {
          if (!submittedStudentIds.contains(studentDoc.id)) {
            final studentData = studentDoc.data();
            pendingList.add({
              'studentName': studentData['name'] ?? 'Unknown',
              'studentEmail': studentData['email'] ?? '',
              'subject': subject,
              'assignment': assignmentData['title'] ?? '',
              'dueDate': dueDate,
            });
          }
        }
      }
    }
    return pendingList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Assignments'),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Filter by Subject: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    isExpanded: true,
                    items: _subjects.map((String subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubject = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getPendingStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pendingList = snapshot.data ?? [];
                if (pendingList.isEmpty) {
                  return const Center(
                      child: Text('No pending assignments found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: pendingList.length,
                  itemBuilder: (context, index) {
                    final item = pendingList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          child: Text(
                            item['studentName'].toString().isNotEmpty
                                ? item['studentName'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          item['studentName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${item['studentEmail']}'),
                            Text('Subject: ${item['subject']}'),
                            Text('Assignment: ${item['assignment']}'),
                            Text(
                              'Due Date: ${item['dueDate'].toString().split(' ')[0]}',
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.hourglass_empty,
                            color: Colors.blueGrey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
