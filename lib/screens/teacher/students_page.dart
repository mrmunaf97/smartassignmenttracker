import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/subject_service.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
    });

    try {
      // Get all students from Firestore
      final studentsSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      List<Map<String, dynamic>> students = [];

      for (var doc in studentsSnapshot.docs) {
        final studentData = doc.data();
        final studentId = doc.id;

        // Get student's submissions to calculate ranking
        final submissionsSnapshot = await _db
            .collection('submissions')
            .where('studentId', isEqualTo: studentId)
            .get();

        double totalGrade = 0;
        int gradedSubmissions = 0;

        for (var submissionDoc in submissionsSnapshot.docs) {
          final submissionData = submissionDoc.data();
          if (submissionData['grade'] != null &&
              submissionData['grade'].toString().isNotEmpty) {
            final grade =
                double.tryParse(submissionData['grade'].toString()) ?? 0;
            totalGrade += grade;
            gradedSubmissions++;
          }
        }

        // Calculate average grade
        double averageGrade =
            gradedSubmissions > 0 ? totalGrade / gradedSubmissions : 0;

        students.add({
          'id': studentId,
          'name': studentData['name'] ?? 'Unknown',
          'email': studentData['email'] ?? 'No email',
          'averageGrade': averageGrade,
          'totalSubmissions': submissionsSnapshot.docs.length,
          'gradedSubmissions': gradedSubmissions,
        });
      }

      // Sort students by average grade (highest first)
      students.sort((a, b) => b['averageGrade'].compareTo(a['averageGrade']));

      // Add ranking
      for (int i = 0; i < students.length; i++) {
        students[i]['rank'] =
            students[i]['gradedSubmissions'] > 0 ? i + 1 : null;
      }

      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Students Count
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${_students.length} students registered',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return _buildStudentCard(student, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Students Registered Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Students will appear here once they register',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    final rank = student['rank'];
    final averageGrade = student['averageGrade'];
    final totalSubmissions = student['totalSubmissions'];
    final gradedSubmissions = student['gradedSubmissions'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Rank Circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: rank != null ? _getRankColor(rank) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  rank?.toString() ?? '-',
                  style: TextStyle(
                    color: rank != null ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student['email'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (rank != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradeColor(averageGrade),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${averageGrade.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '$gradedSubmissions/$totalSubmissions graded',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Icon
            Icon(
              rank != null ? Icons.star : Icons.pending,
              color: rank != null ? Colors.amber : Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.blue;
    }
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) {
      return Colors.green;
    } else if (grade >= 80) {
      return Colors.blue;
    } else if (grade >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
