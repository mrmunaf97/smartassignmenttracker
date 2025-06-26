import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../models/assignment.dart';
import '../../services/offline_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'create_assignment_screen.dart';
import 'assignments_page.dart';
import 'overdue_submissions_page.dart';
import 'students_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/submission.dart';
import '../../screens/common/pdf_viewer_screen.dart';
import 'dart:io';
import 'pending_assignments_page.dart';
import 'submitted_assignments_page.dart';
import '../common/color.dart';
import '../common/about_us_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final AssignmentService _assignmentService = AssignmentService();
  final OfflineService _offlineService = OfflineService();
  final AuthService _authService = AuthService();

  TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  Key _refreshKey = UniqueKey();

  Future<String> _getAvatar() async {
    final user = await widget._offlineService.getUser();
    if (user != null &&
        user['photoUrl'] != null &&
        user['photoUrl'].toString().isNotEmpty) {
      return user['photoUrl'];
    }
    return 'assets/teacher.png';
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

  void _refreshDashboard() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
                final userName = userData?['name'] ?? 'Teacher';
                final userEmail = userData?['email'] ?? 'teacher@example.com';

                return FutureBuilder<String>(
                  future: _getAvatar(),
                  builder: (context, avatarSnapshot) {
                    final avatar = avatarSnapshot.data ?? 'assets/teacher.png';
                    return UserAccountsDrawerHeader(
                      accountName: Text(userName),
                      accountEmail: Text(userEmail),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: avatar.startsWith('http')
                            ? NetworkImage(avatar)
                            : AssetImage(avatar) as ImageProvider,
                        onBackgroundImageError: (exception, stackTrace) {
                          print('Error loading teacher avatar: $exception');
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
              leading: const Icon(Icons.assignment_add),
              title: const Text('Create Assignment'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateAssignmentScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: const Text('View Submissions'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewSubmissionsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Students'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentsPage(),
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
              leading: const Icon(Icons.delete),
              title: const Text('Delete Assignment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssignmentsPage(deleteMode: true),
                  ),
                );
              },
            ),
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
              const SizedBox(height: 12),
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // First row: Students (40%), Assignments (60%)
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildStatCard(
                      context,
                      'Total Students',
                      'Loading...',
                      Icons.people,
                      AppColors.primary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentsPage(),
                          ),
                        );
                      },
                      cardColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: _buildStatCard(
                      context,
                      'Total Assignments',
                      'Loading...',
                      Icons.assignment,
                      AppColors.primaryVariant,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AssignmentsPage(),
                          ),
                        );
                      },
                      cardColor: AppColors.surface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Second row: Dues (60%), Pendings (40%)
              FutureBuilder<List<int>>(
                key: _refreshKey,
                future: Future.wait([
                  _getOverdueAssignmentsCount(),
                  _getPendingAssignmentsCount(),
                ]),
                builder: (context, snapshot) {
                  final values = snapshot.data ?? [0, 0];
                  return Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildStatCardDirect(
                          context,
                          'Dues',
                          values[0].toString(),
                          Icons.warning,
                          AppColors.warning,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OverdueSubmissionsPage(),
                              ),
                            );
                          },
                          cardColor: AppColors.surface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _buildStatCardDirect(
                          context,
                          'Pendings',
                          values[1].toString(),
                          Icons.hourglass_empty,
                          AppColors.secondary,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PendingAssignmentsPage(),
                              ),
                            );
                          },
                          cardColor: AppColors.surface,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Third row: Submitted Assignments (100% width)
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: FutureBuilder<int>(
                      future: _getSubmittedAssignmentsCount(),
                      builder: (context, snapshot) {
                        final submittedValue = snapshot.hasData
                            ? snapshot.data.toString()
                            : 'Loading...';
                        return _buildStatCardDirect(
                          context,
                          'Submitted Assignments',
                          submittedValue,
                          Icons.check_circle,
                          AppColors.success,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SubmittedAssignmentsPage(),
                              ),
                            );
                          },
                          cardColor: AppColors.surface,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Top Students Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'Top Students',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTopStudentsCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color iconColor, VoidCallback onTap,
      {Color? cardColor}) {
    return FutureBuilder<String>(
      future: _getStatValue(title),
      builder: (context, snapshot) {
        final displayValue = snapshot.data ?? 'Loading...';

        return Card(
          elevation: 0,
          color: cardColor ?? Color(0xFFE0F7FA),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayValue,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    icon,
                    color: iconColor, // Use original icon color
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

  Widget _buildStatCardDirect(BuildContext context, String title, String value,
      IconData icon, Color iconColor, VoidCallback onTap,
      {Color? cardColor}) {
    return Card(
      elevation: 0,
      color: cardColor ?? Color(0xFFE0F7FA),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Icon(
                icon,
                color: iconColor, // Use original icon color
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getStatValue(String title) async {
    try {
      final db = FirebaseFirestore.instance;

      switch (title) {
        case 'Total Students':
          final studentsSnapshot = await db
              .collection('users')
              .where('role', isEqualTo: 'student')
              .get();
          print('Found ${studentsSnapshot.docs.length} students in Firestore');

          // Debug: Print all users to see what's in the database
          final allUsersSnapshot = await db.collection('users').get();
          print('Total users in database: ${allUsersSnapshot.docs.length}');
          for (var doc in allUsersSnapshot.docs) {
            final userData = doc.data();
            print(
                'User: ${userData['name']} - Role: ${userData['role']} - Email: ${userData['email']}');
          }

          return studentsSnapshot.docs.length.toString();

        case 'Total Assignments':
          final assignmentsSnapshot = await db.collection('assignments').get();
          print(
              'Found ${assignmentsSnapshot.docs.length} assignments in Firestore');
          return assignmentsSnapshot.docs.length.toString();

        case 'Overdue Assignments':
          // Get all assignments
          final assignmentsSnapshot = await db.collection('assignments').get();
          final studentsSnapshot = await db
              .collection('users')
              .where('role', isEqualTo: 'student')
              .get();
          int overdueCount = 0;
          for (var assignmentDoc in assignmentsSnapshot.docs) {
            final assignmentData = assignmentDoc.data();
            final dueDate = (assignmentData['dueDate'] as Timestamp).toDate();
            if (dueDate.isBefore(DateTime.now())) {
              final assignmentId = assignmentDoc.id;
              final submissionsSnapshot = await db
                  .collection('submissions')
                  .where('assignmentId', isEqualTo: assignmentId)
                  .get();
              final submittedStudentIds = submissionsSnapshot.docs
                  .map((doc) => doc['studentId'])
                  .toSet();
              for (var studentDoc in studentsSnapshot.docs) {
                if (!submittedStudentIds.contains(studentDoc.id)) {
                  overdueCount++;
                }
              }
            }
          }
          return overdueCount.toString();

        case 'Pending Assignments':
          // Get all assignments
          final assignmentsSnapshot = await db.collection('assignments').get();
          final studentsSnapshot = await db
              .collection('users')
              .where('role', isEqualTo: 'student')
              .get();
          int pendingCount = 0;
          for (var assignmentDoc in assignmentsSnapshot.docs) {
            final assignmentData = assignmentDoc.data();
            final dueDate = (assignmentData['dueDate'] as Timestamp).toDate();
            if (dueDate.isAfter(DateTime.now())) {
              final assignmentId = assignmentDoc.id;
              final submissionsSnapshot = await db
                  .collection('submissions')
                  .where('assignmentId', isEqualTo: assignmentId)
                  .get();
              final submittedStudentIds = submissionsSnapshot.docs
                  .map((doc) => doc['studentId'])
                  .toSet();
              for (var studentDoc in studentsSnapshot.docs) {
                if (!submittedStudentIds.contains(studentDoc.id)) {
                  pendingCount++;
                }
              }
            }
          }
          return pendingCount.toString();

        default:
          return '0';
      }
    } catch (e) {
      print('Error loading stat $title: $e');
      return 'Error';
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
                child: Text('Error: ${snapshot.error}'),
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
    try {
      final db = FirebaseFirestore.instance;

      // Get all students from Firestore
      final studentsSnapshot = await db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      List<Map<String, dynamic>> students = [];

      for (var doc in studentsSnapshot.docs) {
        final studentData = doc.data();
        final studentId = doc.id;

        // Get student's submissions to calculate ranking
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

        // Use sum of grades for ranking
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

      // Sort students by sum of grades (highest first)
      students.sort((a, b) => b['sumGrade'].compareTo(a['sumGrade']));

      // Add ranking
      for (int i = 0; i < students.length; i++) {
        students[i]['rank'] = i + 1;
      }

      return students;
    } catch (e) {
      print('Error loading top students: $e');
      return [];
    }
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

  Future<int> _getOverdueAssignmentsCount() async {
    final db = FirebaseFirestore.instance;
    final assignmentsSnapshot = await db.collection('assignments').get();
    final studentsSnapshot =
        await db.collection('users').where('role', isEqualTo: 'student').get();
    int overdueCount = 0;
    for (var assignmentDoc in assignmentsSnapshot.docs) {
      final assignmentData = assignmentDoc.data();
      final dueDate = (assignmentData['dueDate'] as Timestamp).toDate();
      if (dueDate.isBefore(DateTime.now())) {
        final assignmentId = assignmentDoc.id;
        final submissionsSnapshot = await db
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .get();
        final submittedStudentIds =
            submissionsSnapshot.docs.map((doc) => doc['studentId']).toSet();
        for (var studentDoc in studentsSnapshot.docs) {
          if (!submittedStudentIds.contains(studentDoc.id)) {
            overdueCount++;
          }
        }
      }
    }
    return overdueCount;
  }

  Future<int> _getPendingAssignmentsCount() async {
    final db = FirebaseFirestore.instance;
    final assignmentsSnapshot = await db.collection('assignments').get();
    final studentsSnapshot =
        await db.collection('users').where('role', isEqualTo: 'student').get();
    print(
        'Fetched assignments: ${assignmentsSnapshot.docs.length}, students: ${studentsSnapshot.docs.length}');
    int pendingCount = 0;
    for (var assignmentDoc in assignmentsSnapshot.docs) {
      final assignmentData = assignmentDoc.data();
      final dueDate = (assignmentData['dueDate'] as Timestamp).toDate();
      if (dueDate.isAfter(DateTime.now())) {
        final assignmentId = assignmentDoc.id;
        final submissionsSnapshot = await db
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .get();
        final submittedStudentIds =
            submissionsSnapshot.docs.map((doc) => doc['studentId']).toSet();
        print(
            'Assignment $assignmentId, submittedStudentIds: $submittedStudentIds');
        for (var studentDoc in studentsSnapshot.docs) {
          if (!submittedStudentIds.contains(studentDoc.id)) {
            pendingCount++;
            print(
                'Student ${studentDoc.id} has not submitted for assignment $assignmentId');
          }
        }
      }
    }
    print('Pending count: $pendingCount');
    return pendingCount;
  }

  Future<int> _getSubmittedAssignmentsCount() async {
    final db = FirebaseFirestore.instance;
    final submissionsSnapshot = await db.collection('submissions').get();
    return submissionsSnapshot.docs.length;
  }
}

class ViewSubmissionsScreen extends StatefulWidget {
  const ViewSubmissionsScreen({Key? key}) : super(key: key);

  @override
  State<ViewSubmissionsScreen> createState() => _ViewSubmissionsScreenState();
}

class _ViewSubmissionsScreenState extends State<ViewSubmissionsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  late Future<List<Assignment>> _assignmentsFuture;
  late Future<List<Submission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _assignmentsFuture =
        _assignmentService.getAssignments().first.then((assignments) {
      debugPrint('Fetched assignments:');
      for (var a in assignments) {
        debugPrint('Assignment: id=${a.id}, title=${a.title}');
      }
      return assignments;
    });
    _submissionsFuture = _getAllSubmissions();
  }

  Future<List<Submission>> _getAllSubmissions() async {
    final assignments = await _assignmentService.getAssignments().first;
    List<Submission> allSubs = [];
    for (final assignment in assignments) {
      final subs = await _assignmentService
          .getSubmissionsForAssignment(assignment.id)
          .first;
      debugPrint(
          'For assignment id=${assignment.id}, found ${subs.length} submissions');
      for (var s in subs) {
        debugPrint(
            'Submission: id=${s.id}, assignmentId=${s.assignmentId}, studentId=${s.studentId}');
      }
      allSubs.addAll(subs);
    }
    debugPrint('Total submissions loaded: ${allSubs.length}');
    return allSubs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Submissions')),
      body: FutureBuilder<List<Assignment>>(
        future: _assignmentsFuture,
        builder: (context, assignmentSnap) {
          if (!assignmentSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final assignments = assignmentSnap.data!;
          return FutureBuilder<List<Submission>>(
            future: _submissionsFuture,
            builder: (context, subSnap) {
              if (!subSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final submissions = subSnap.data!;
              if (submissions.isEmpty) {
                return const Center(child: Text('No submissions yet.'));
              }
              return ListView.builder(
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final submission = submissions[index];
                  final assignment = assignments.firstWhere(
                      (a) => a.id == submission.assignmentId,
                      orElse: () => Assignment(
                          id: '',
                          title: 'Unknown',
                          description: '',
                          dueDate: DateTime.now(),
                          createdBy: '',
                          subject: '',
                          totalGrade: 0));
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SubmissionTile(
                        submission: submission,
                        assignment: assignment,
                        onAction: () => setState(() {
                          _submissionsFuture = _getAllSubmissions();
                        }),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class SubmissionTile extends StatefulWidget {
  final Submission submission;
  final Assignment assignment;
  final VoidCallback onAction;
  const SubmissionTile(
      {required this.submission,
      required this.assignment,
      required this.onAction,
      Key? key})
      : super(key: key);

  @override
  State<SubmissionTile> createState() => _SubmissionTileState();
}

class _SubmissionTileState extends State<SubmissionTile> {
  final _gradeController = TextEditingController();
  String? _status; // 'approved', 'rejected', or null
  bool _loading = false;
  String? _error;
  bool _confirmed = false;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _gradeController.text = widget.submission.grade?.toString() ?? '';
    _status =
        widget.submission.status == 'pending' ? null : widget.submission.status;
    _confirmed = widget.submission.status != 'pending';
    _fetchStudentName();
  }

  Future<void> _fetchStudentName() async {
    final db = FirebaseFirestore.instance;
    final doc =
        await db.collection('users').doc(widget.submission.studentId).get();
    if (mounted) {
      setState(() {
        _studentName = doc.data()?['name'] ?? widget.submission.studentId;
      });
    }
  }

  void _onStatusChanged(bool? value) {
    if (_confirmed) return;
    setState(() {
      if (value == null) {
        _status = null;
      } else {
        _status = value ? 'approved' : 'rejected';
      }
    });
  }

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (_status == null) {
      if (mounted) {
        setState(() {
          _error = 'Please approve or reject.';
          _loading = false;
        });
      }
      return;
    }
    double? gradeValue;
    if (_status == 'approved') {
      gradeValue = double.tryParse(_gradeController.text);
      if (gradeValue == null || gradeValue < 0) {
        if (mounted) {
          setState(() {
            _error = 'Enter a valid grade.';
            _loading = false;
          });
        }
        return;
      }
      if (gradeValue > widget.assignment.totalGrade) {
        if (mounted) {
          setState(() {
            _error = 'Grade cannot exceed ${widget.assignment.totalGrade}.';
            _loading = false;
          });
        }
        return;
      }
    }
    try {
      final updated = widget.submission.copyWith(
        grade: _status == 'approved' ? _gradeController.text : null,
        status: _status,
      );
      await AssignmentService().updateSubmission(updated);
      if (mounted) {
        setState(() {
          _confirmed = true;
        });
      }
      widget.onAction();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Color _getStatusColor(String? status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.amber; // pending
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assignment: ${widget.assignment.title}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Student: ${_studentName ?? widget.submission.studentId}'),
        Text(
            'Submitted: ${formatDate(widget.submission.submittedAt.toLocal())}'),
        if (widget.submission.remarks != null &&
            widget.submission.remarks!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: Text('Description: ${widget.submission.remarks}',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        if (widget.submission.fileUrl != null &&
            widget.submission.fileUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              icon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset(
                  'assets/splash.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              label: const Text('View Document'),
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
                final url = widget.submission.fileUrl!;
                final lowerUrl = url.toLowerCase();
                if (lowerUrl.endsWith('.pdf')) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(fileUrl: url),
                    ),
                  );
                } else if (lowerUrl.endsWith('.jpg') ||
                    lowerUrl.endsWith('.jpeg') ||
                    lowerUrl.endsWith('.png') ||
                    lowerUrl.endsWith('.gif')) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageViewerScreen(imageUrl: url),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unsupported file type')),
                  );
                }
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
          child: Row(
            children: [
              const Text('Status: '),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _status == null ? 'Pending' : _status!.capitalize(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        if (!_confirmed)
          Row(
            children: [
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _status = 'approved';
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _status == 'approved'
                      ? Colors.green[400]
                      : Colors.green[100],
                  foregroundColor:
                      _status == 'approved' ? Colors.white : Colors.green[900],
                  elevation: 0,
                ),
                child: const Text('Approve'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _status = 'rejected';
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _status == 'rejected' ? Colors.red[400] : Colors.red[100],
                  foregroundColor:
                      _status == 'rejected' ? Colors.white : Colors.red[900],
                  elevation: 0,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
        if (_status == 'approved')
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: _gradeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Grade (max ${widget.assignment.totalGrade})',
                errorText: _error,
              ),
              enabled: !_confirmed,
            ),
          ),
        if (!_confirmed && _status != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: ElevatedButton(
              onPressed: _loading ? null : _confirm,
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm'),
            ),
          ),
        if (_confirmed)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Decision confirmed. No further changes allowed.',
                style: TextStyle(color: Colors.grey[600])),
          ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      this.isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  const ImageViewerScreen({required this.imageUrl, Key? key}) : super(key: key);

  bool get isNetworkImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  bool get isFileUri => imageUrl.startsWith('file://');

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (isNetworkImage) {
      imageWidget = Image.network(imageUrl);
    } else if (isFileUri) {
      imageWidget = Image.file(File(Uri.parse(imageUrl).toFilePath()));
    } else {
      imageWidget = Image.file(File(imageUrl));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Image Viewer')),
      body: Center(
        child: imageWidget,
      ),
    );
  }
}
