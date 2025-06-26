import 'package:flutter/material.dart';
import '../../models/assignment.dart';
import '../../models/submission.dart';
import '../../services/assignment_service.dart';
import '../common/color.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final Assignment assignment;
  final AssignmentService _assignmentService = AssignmentService();

  AssignmentDetailScreen({required this.assignment, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(assignment.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(assignment.description),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Due: ${formatDate(assignment.dueDate.toLocal())}'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Submissions',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<Submission>>(
              stream:
                  _assignmentService.getSubmissionsForAssignment(assignment.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final submissions = snapshot.data!;
                if (submissions.isEmpty)
                  return const Center(child: Text('No submissions yet.'));
                return ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    return ListTile(
                      title: Text('Student: ${submission.studentId}'),
                      subtitle: Text(
                          'Submitted: ${formatDate(submission.submittedAt.toLocal())}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.grade),
                        onPressed: () {
                          // TODO: Open grading dialog
                        },
                      ),
                      onTap: () {
                        // TODO: Open submission file/PDF
                      },
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
