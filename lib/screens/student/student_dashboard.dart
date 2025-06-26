import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../models/assignment.dart';
import '../../services/offline_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../teacher/assignment_detail_screen.dart';
import '../teacher/assignments_page.dart';
import 'assignment_list_screen.dart';
import '../../models/submission.dart';
import '../../services/subject_service.dart';
import '../common/color.dart';
import 'package:open_file/open_file.dart';
import '../common/pdf_viewer_screen.dart';
import '../common/about_us_screen.dart';
import 'pending_assignments_page.dart';

class StudentDashboard extends StatefulWidget {
  final AssignmentService _assignmentService = AssignmentService();
  final OfflineService _offlineService = OfflineService();
  final AuthService _authService = AuthService();

  StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Key _refreshKey = UniqueKey();
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadStudentId();
  }

  Future<void> _loadStudentId() async {
    final user = await widget._offlineService.getUser();
    setState(() {
      _studentId = user?['uid'];
    });
  }

  void _refreshDashboard() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  Future<String> _getAvatar() async {
    final user = await widget._offlineService.getUser();
    if (user != null &&
        user['photoUrl'] != null &&
        user['photoUrl'].toString().isNotEmpty) {
      return user['photoUrl'];
    }
    return 'assets/student.png';
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    return await widget._offlineService.getUser();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await widget._authService.signOut();
      await widget._offlineService.clearUser();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _getUserData(),
              builder: (context, snapshot) {
                final userData = snapshot.data;
                final userName = userData?['name'] ?? 'Student';
                final userEmail = userData?['email'] ?? 'student@example.com';

                return FutureBuilder<String>(
                  future: _getAvatar(),
                  builder: (context, avatarSnapshot) {
                    final avatar = avatarSnapshot.data ?? 'assets/student.png';
                    return UserAccountsDrawerHeader(
                      accountName: Text(userName),
                      accountEmail: Text(userEmail),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: avatar.startsWith('http')
                            ? NetworkImage(avatar)
                            : AssetImage(avatar) as ImageProvider,
                        onBackgroundImageError: (exception, stackTrace) {
                          print('Error loading student avatar: $exception');
                        },
                      ),
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Submission'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DeleteSubmissionScreen(studentId: _studentId!),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Status and Grade'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StatusAndGradeScreen(studentId: _studentId!),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutUsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: KeyedSubtree(
        key: _refreshKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // First row: Assignments (60%), Dues (40%)
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildStatCard(
                      context,
                      'Assignments',
                      _studentId,
                      Icons.assignment,
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignmentsListForStudent(
                                studentId: _studentId!),
                          ),
                        );
                      },
                      statType: 'total',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildStatCard(
                      context,
                      'Dues',
                      _studentId,
                      Icons.warning,
                      Colors.orange,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DueAssignmentsListForStudent(
                                studentId: _studentId!),
                          ),
                        );
                      },
                      statType: 'due',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Second row: Pendings (40%), Submitted (60%)
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildStatCard(
                      context,
                      'Pendings',
                      _studentId,
                      Icons.hourglass_empty,
                      Colors.blueGrey,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PendingAssignmentsPage(
                              studentId: _studentId!,
                            ),
                          ),
                        );
                      },
                      statType: 'pending',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: _buildStatCard(
                      context,
                      'Submitted',
                      _studentId,
                      Icons.check_circle,
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmittedAssignmentsListForStudent(
                                studentId: _studentId!),
                          ),
                        );
                      },
                      statType: 'submitted',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                'Top Students',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTopStudentsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String? studentId,
      IconData icon, Color color, VoidCallback onTap,
      {required String statType}) {
    return FutureBuilder<String>(
      future: _getStatValue(statType, studentId),
      builder: (context, snapshot) {
        final displayValue = snapshot.data ?? '...';
        return Card(
          elevation: 0,
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayValue,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    icon,
                    color: color,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _getStatValue(String statType, String? studentId) async {
    if (studentId == null) return '...';
    final db = FirebaseFirestore.instance;
    switch (statType) {
      case 'total':
        final assignmentsSnapshot = await db.collection('assignments').get();
        return assignmentsSnapshot.docs.length.toString();
      case 'due':
        final assignmentsSnapshot = await db.collection('assignments').get();
        final submissionsSnapshot = await db
            .collection('submissions')
            .where('studentId', isEqualTo: studentId)
            .get();
        final submittedAssignmentIds =
            submissionsSnapshot.docs.map((doc) => doc['assignmentId']).toSet();
        int dueCount = 0;
        for (var doc in assignmentsSnapshot.docs) {
          final data = doc.data();
          final dueDate = (data['dueDate'] as Timestamp).toDate();
          if (dueDate.isBefore(DateTime.now()) &&
              !submittedAssignmentIds.contains(doc.id)) {
            dueCount++;
          }
        }
        return dueCount.toString();
      case 'submitted':
        final submissionsSnapshot = await db
            .collection('submissions')
            .where('studentId', isEqualTo: studentId)
            .get();
        return submissionsSnapshot.docs.length.toString();
      case 'pending':
        final assignmentsSnapshot = await db.collection('assignments').get();
        final submissionsSnapshot = await db
            .collection('submissions')
            .where('studentId', isEqualTo: studentId)
            .get();
        final submittedAssignmentIds =
            submissionsSnapshot.docs.map((doc) => doc['assignmentId']).toSet();
        int pendingCount = 0;
        final now = DateTime.now();
        for (var doc in assignmentsSnapshot.docs) {
          final data = doc.data();
          final dueDate = (data['dueDate'] as Timestamp).toDate();
          // Pending = not submitted and due date is in the future
          if (!submittedAssignmentIds.contains(doc.id) &&
              dueDate.isAfter(now)) {
            pendingCount++;
          }
        }
        return pendingCount.toString();
      default:
        return '0';
    }
  }

  Widget _buildTopStudentsCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getTopStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('Error: \\${snapshot.error}'),
              ),
            ),
          );
        }
        final topStudents = snapshot.data ?? [];
        if (topStudents.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Text(
                        'Top Performers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No students with grades yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text(
                      'Top Performers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...topStudents.take(5).map((student) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _getRankColor(student['rank']),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${student['rank']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                student['email'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradeColor(student['sumGrade']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${student['sumGrade'].toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getTopStudents() async {
    final db = FirebaseFirestore.instance;
    final studentsSnapshot =
        await db.collection('users').where('role', isEqualTo: 'student').get();
    List<Map<String, dynamic>> students = [];
    for (var doc in studentsSnapshot.docs) {
      final studentData = doc.data();
      final studentId = doc.id;
      final submissionsSnapshot = await db
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
      double sumGrade = totalGrade;
      if (gradedSubmissions > 0) {
        students.add({
          'id': studentId,
          'name': studentData['name'] ?? 'Unknown',
          'email': studentData['email'] ?? 'No email',
          'sumGrade': sumGrade,
          'totalSubmissions': submissionsSnapshot.docs.length,
          'gradedSubmissions': gradedSubmissions,
        });
      }
    }
    students.sort((a, b) => b['sumGrade'].compareTo(a['sumGrade']));
    for (int i = 0; i < students.length; i++) {
      students[i]['rank'] = i + 1;
    }
    return students;
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

class AssignmentsListForStudent extends StatelessWidget {
  final String studentId;
  const AssignmentsListForStudent({required this.studentId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AssignmentService assignmentService = AssignmentService();
    return Scaffold(
      appBar: AppBar(title: const Text('All Assignments')),
      body: StreamBuilder<List<Assignment>>(
        stream: assignmentService.getAssignments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final assignments = snapshot.data!;
          if (assignments.isEmpty) {
            return const Center(child: Text('No assignments found.'));
          }
          return ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(assignment.title),
                  subtitle: Text('Due: \\${assignment.dueDate.toLocal()}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AssignmentListScreen(assignment: assignment),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DueAssignmentsListForStudent extends StatelessWidget {
  final String studentId;
  const DueAssignmentsListForStudent({required this.studentId, Key? key})
      : super(key: key);

  Future<List<Assignment>> _getDueAssignments() async {
    final db = FirebaseFirestore.instance;
    final assignmentsSnapshot = await db.collection('assignments').get();
    final submissionsSnapshot = await db
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .get();
    final submittedAssignmentIds =
        submissionsSnapshot.docs.map((doc) => doc['assignmentId']).toSet();
    List<Assignment> dueAssignments = [];
    for (var doc in assignmentsSnapshot.docs) {
      final data = doc.data();
      final dueDate = (data['dueDate'] as Timestamp).toDate();
      if (dueDate.isBefore(DateTime.now()) &&
          !submittedAssignmentIds.contains(doc.id)) {
        dueAssignments.add(Assignment.fromMap(data, doc.id));
      }
    }
    return dueAssignments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Due Assignments')),
      body: FutureBuilder<List<Assignment>>(
        future: _getDueAssignments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final assignments = snapshot.data!;
          if (assignments.isEmpty) {
            return const Center(child: Text('No due assignments!'));
          }
          return ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(assignment.title),
                  subtitle: Text('Due: \\${assignment.dueDate.toLocal()}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AssignmentListScreen(assignment: assignment),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SubmittedAssignmentsListForStudent extends StatelessWidget {
  final String studentId;
  const SubmittedAssignmentsListForStudent({required this.studentId, Key? key})
      : super(key: key);

  Future<List<Map<String, dynamic>>> _getSubmittedAssignments() async {
    final db = FirebaseFirestore.instance;
    final submissionsSnapshot = await db
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .get();
    final assignmentsSnapshot = await db.collection('assignments').get();
    final assignmentsMap = {
      for (var doc in assignmentsSnapshot.docs) doc.id: doc.data()
    };
    List<Map<String, dynamic>> result = [];
    for (var doc in submissionsSnapshot.docs) {
      final submission = doc.data();
      final assignmentData = assignmentsMap[submission['assignmentId']];
      result.add({
        'submissionId': doc.id,
        'assignmentTitle': assignmentData != null
            ? assignmentData['title'] ?? 'Unknown'
            : 'Unknown',
        'assignmentDescription': assignmentData != null
            ? assignmentData['description'] ?? 'No description'
            : 'No description',
        'submittedAt': (submission['submittedAt'] as Timestamp).toDate(),
        'status': submission['status'] ?? 'pending',
        'remarks': submission['remarks'] ?? '',
        'fileUrl': submission['fileUrl'] ?? '',
        'grade': submission['grade'],
        'totalGrade':
            assignmentData != null ? assignmentData['totalGrade'] ?? 0 : 0,
      });
    }
    return result;
  }

  void _showSubmissionDetails(
      BuildContext context, Map<String, dynamic> submission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(submission['assignmentTitle']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Assignment Description:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(submission['assignmentDescription']),
                const SizedBox(height: 16),
                Text('Submitted: ${formatDate(submission['submittedAt'])}'),
                const SizedBox(height: 8),
                if (submission['remarks'] != null &&
                    submission['remarks'].isNotEmpty) ...[
                  Text('Your Remarks:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(submission['remarks']),
                  const SizedBox(height: 8),
                ],
                if (submission['fileUrl'] != null &&
                    submission['fileUrl'].isNotEmpty) ...[
                  Text('Uploaded File:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(getFileNameFromPath(submission['fileUrl'])),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('View File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      final url = submission['fileUrl'];
                      if (url.startsWith('http')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(fileUrl: url),
                          ),
                        );
                      } else {
                        OpenFile.open(url);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (submission['grade'] != null) ...[
                  Text(
                      'Grade: ${submission['grade']}/${submission['totalGrade']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      )),
                ],
                Text('Status: ${submission['status']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(submission['status']),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
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
            return const Center(child: Text('No submitted assignments!'));
          }
          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              final status = submission['status'] ?? 'pending';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(submission['assignmentTitle']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Submitted: ${formatDate(submission['submittedAt'])}'),
                      if (submission['remarks'] != null &&
                          submission['remarks'].isNotEmpty)
                        Text('Remarks: ${submission['remarks']}'),
                      if (submission['fileUrl'] != null &&
                          submission['fileUrl'].isNotEmpty)
                        Text(
                            'File: ${getFileNameFromPath(submission['fileUrl'])}'),
                      if (submission['grade'] != null)
                        Text(
                            'Grade: ${submission['grade']}/${submission['totalGrade']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () {
                    _showSubmissionDetails(context, submission);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DeleteSubmissionScreen extends StatefulWidget {
  final String studentId;
  const DeleteSubmissionScreen({required this.studentId, Key? key})
      : super(key: key);

  @override
  State<DeleteSubmissionScreen> createState() => _DeleteSubmissionScreenState();
}

class _DeleteSubmissionScreenState extends State<DeleteSubmissionScreen> {
  late Future<List<Map<String, dynamic>>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  void _loadSubmissions() {
    setState(() {
      _submissionsFuture = _getStudentSubmissions();
    });
  }

  Future<List<Map<String, dynamic>>> _getStudentSubmissions() async {
    final db = FirebaseFirestore.instance;
    final submissionsSnapshot = await db
        .collection('submissions')
        .where('studentId', isEqualTo: widget.studentId)
        .get();
    final assignmentsSnapshot = await db.collection('assignments').get();
    final assignmentsMap = {
      for (var doc in assignmentsSnapshot.docs) doc.id: doc.data()
    };
    List<Map<String, dynamic>> result = [];
    for (var doc in submissionsSnapshot.docs) {
      final submission = doc.data();
      final assignmentData = assignmentsMap[submission['assignmentId']];
      result.add({
        'submissionId': doc.id,
        'assignmentTitle': assignmentData != null
            ? assignmentData['title'] ?? 'Unknown'
            : 'Unknown',
        'assignmentDescription': assignmentData != null
            ? assignmentData['description'] ?? 'No description'
            : 'No description',
        'submittedAt': (submission['submittedAt'] as Timestamp).toDate(),
        'status': submission['status'] ?? 'pending',
        'remarks': submission['remarks'] ?? '',
        'fileUrl': submission['fileUrl'] ?? '',
        'grade': submission['grade'],
        'totalGrade':
            assignmentData != null ? assignmentData['totalGrade'] ?? 0 : 0,
      });
    }
    return result;
  }

  Future<void> _deleteSubmission(
      BuildContext context, String submissionId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this submission? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('submissions')
        .doc(submissionId)
        .delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Submission deleted')));
    _loadSubmissions();
  }

  void _showSubmissionDetails(
      BuildContext context, Map<String, dynamic> submission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(submission['assignmentTitle']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Assignment Description:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(submission['assignmentDescription']),
                const SizedBox(height: 16),
                Text('Submitted: ${formatDate(submission['submittedAt'])}'),
                const SizedBox(height: 8),
                if (submission['remarks'] != null &&
                    submission['remarks'].isNotEmpty) ...[
                  Text('Your Remarks:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(submission['remarks']),
                  const SizedBox(height: 8),
                ],
                if (submission['fileUrl'] != null &&
                    submission['fileUrl'].isNotEmpty) ...[
                  Text('Uploaded File:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(getFileNameFromPath(submission['fileUrl'])),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('View File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      final url = submission['fileUrl'];
                      if (url.startsWith('http')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(fileUrl: url),
                          ),
                        );
                      } else {
                        OpenFile.open(url);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (submission['grade'] != null) ...[
                  Text(
                      'Grade: ${submission['grade']}/${submission['totalGrade']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      )),
                ],
                Text('Status: ${submission['status']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(submission['status']),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
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
      appBar: AppBar(title: const Text('View Submission')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _submissionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final submissions = snapshot.data!;
          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions found.'));
          }
          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final sub = submissions[index];
              final status = sub['status'] ?? 'pending';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(sub['assignmentTitle']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submitted: ${formatDate(sub['submittedAt'])}'),
                      if (sub['remarks'] != null && sub['remarks'].isNotEmpty)
                        Text('Remarks: ${sub['remarks']}'),
                      if (sub['fileUrl'] != null && sub['fileUrl'].isNotEmpty)
                        Text('File: ${getFileNameFromPath(sub['fileUrl'])}'),
                      if (sub['grade'] != null)
                        Text('Grade: ${sub['grade']}/${sub['totalGrade']}'),
                    ],
                  ),
                  trailing: status == 'pending'
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _deleteSubmission(
                                context, sub['submissionId']);
                          },
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lock, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('Graded',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                  onTap: () {
                    _showSubmissionDetails(context, sub);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StatusAndGradeScreen extends StatelessWidget {
  final String studentId;
  const StatusAndGradeScreen({required this.studentId, Key? key})
      : super(key: key);

  Future<List<Map<String, dynamic>>> _getStatusAndGrades() async {
    final db = FirebaseFirestore.instance;
    final submissionsSnapshot = await db
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .get();
    final assignmentsSnapshot = await db.collection('assignments').get();
    final assignmentsMap = {
      for (var doc in assignmentsSnapshot.docs) doc.id: doc.data()
    };
    List<Map<String, dynamic>> result = [];
    for (var doc in submissionsSnapshot.docs) {
      final submission = doc.data();
      final assignmentData = assignmentsMap[submission['assignmentId']];
      result.add({
        'assignmentTitle': assignmentData != null
            ? assignmentData['title'] ?? 'Unknown'
            : 'Unknown',
        'submittedAt': (submission['submittedAt'] as Timestamp).toDate(),
        'status': submission['status'] ?? 'pending',
        'grade': submission['grade'],
        'totalGrade':
            assignmentData != null ? assignmentData['totalGrade'] ?? 0 : 0,
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
      appBar: AppBar(title: const Text('Status and Grade')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getStatusAndGrades(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No submissions yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item['assignmentTitle'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.event, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text('Submitted: ${formatDate(item['submittedAt'])}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.info,
                              size: 18, color: _statusColor(item['status'])),
                          const SizedBox(width: 6),
                          Text(
                            'Status: ${item['status'].toString().capitalize()}',
                            style: TextStyle(
                              color: _statusColor(item['status']),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (item['status'] == 'approved' && item['grade'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Icon(Icons.grade,
                                  size: 18, color: Colors.blue[700]),
                              const SizedBox(width: 6),
                              Text(
                                'Grade: ${item['grade']}/${item['totalGrade']}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
