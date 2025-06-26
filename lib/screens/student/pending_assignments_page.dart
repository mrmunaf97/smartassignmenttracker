import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../models/assignment.dart';
import '../../services/subject_service.dart';
import '../common/color.dart';
import '../teacher/assignment_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingAssignmentsPage extends StatefulWidget {
  final String studentId;

  const PendingAssignmentsPage({super.key, required this.studentId});

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

  Future<List<Map<String, dynamic>>> _getPendingAssignments() async {
    final assignmentsSnapshot = await _db.collection('assignments').get();
    final submissionsSnapshot = await _db
        .collection('submissions')
        .where('studentId', isEqualTo: widget.studentId)
        .get();

    final submittedAssignmentIds =
        submissionsSnapshot.docs.map((doc) => doc['assignmentId']).toSet();

    List<Map<String, dynamic>> pendingList = [];
    final now = DateTime.now();

    for (var doc in assignmentsSnapshot.docs) {
      final data = doc.data();
      final dueDate = (data['dueDate'] as Timestamp).toDate();
      final subject = data['subject'] ?? '';

      // Check if assignment is not submitted and due date is in the future
      if (!submittedAssignmentIds.contains(doc.id) &&
          dueDate.isAfter(now) &&
          (_selectedSubject == 'All' || subject == _selectedSubject)) {
        pendingList.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'subject': subject,
          'dueDate': dueDate,
          'totalGrade': data['totalGrade'] ?? 0,
          'documentUrl': data['documentUrl'] ?? '',
        });
      }
    }

    // Sort by due date (earliest first)
    pendingList.sort((a, b) => a['dueDate'].compareTo(b['dueDate']));

    return pendingList;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getFilenameFromUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return url.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Assignments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
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
              future: _getPendingAssignments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pendingList = snapshot.data ?? [];

                if (pendingList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending assignments!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have submitted all your assignments.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: pendingList.length,
                  itemBuilder: (context, index) {
                    final item = pendingList[index];
                    final dueDate = item['dueDate'] as DateTime;
                    final isDueSoon =
                        dueDate.difference(DateTime.now()).inDays <= 3;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          // Create Assignment object from the data
                          final assignment = Assignment(
                            id: item['id'],
                            title: item['title'],
                            description: item['description'],
                            subject: item['subject'],
                            dueDate: item['dueDate'],
                            totalGrade: item['totalGrade'],
                            fileUrl: item['documentUrl'],
                            createdBy:
                                'Teacher', // Default value since we don't have this data
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignmentDetailScreen(
                                assignment: assignment,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDueSoon
                                          ? AppColors.warning
                                          : AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isDueSoon ? 'Due Soon' : 'Pending',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['description'],
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.subject,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['subject'],
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.grade,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item['totalGrade']} marks',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: isDueSoon
                                        ? AppColors.warning
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due: ${_formatDate(dueDate)}',
                                    style: TextStyle(
                                      color: isDueSoon
                                          ? AppColors.warning
                                          : AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: isDueSoon
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (item['documentUrl'].isNotEmpty) ...[
                                    const Spacer(),
                                    Icon(
                                      Icons.attach_file,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _getFilenameFromUrl(
                                            item['documentUrl']),
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
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
