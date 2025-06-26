import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../models/assignment.dart';
import '../../services/subject_service.dart';
import 'package:open_file/open_file.dart';
import '../common/pdf_viewer_screen.dart';
import '../common/color.dart';

class AssignmentsPage extends StatefulWidget {
  final bool deleteMode;
  const AssignmentsPage({super.key, this.deleteMode = false});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  final AssignmentService _assignmentService = AssignmentService();
  final SubjectService _subjectService = SubjectService();
  String _selectedSubject = 'All';
  String _searchQuery = '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ... existing filter/search code ...
          Expanded(
            child: StreamBuilder<List<Assignment>>(
              stream: _assignmentService.getAssignments(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<Assignment> assignments = snapshot.data!;
                // ... existing filter/search logic ...
                if (assignments.isEmpty) {
                  return const Center(child: Text('No assignments found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        title: Text(
                          assignment.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(truncateToWords(assignment.description)),
                            const SizedBox(height: 4),
                            Text(
                              'Subject: ${assignment.subject}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Due: ${formatDate(assignment.dueDate.toLocal())}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total Grade: ${assignment.totalGrade}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: widget.deleteMode
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  // Show confirmation dialog
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm Deletion'),
                                        content: Text(
                                            'Are you sure you want to delete the assignment "${assignment.title}"? This action cannot be undone and will also delete all related submissions.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            style: TextButton.styleFrom(
                                                foregroundColor: Colors.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmed == true) {
                                    await _assignmentService
                                        .deleteAssignment(assignment.id);
                                    setState(() {});
                                  }
                                },
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: widget.deleteMode
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AssignmentDetailPage(
                                        assignment: assignment),
                                  ),
                                );
                              },
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Assignments'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Enter assignment title or description...',
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}

class AssignmentDetailPage extends StatelessWidget {
  final Assignment assignment;
  const AssignmentDetailPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(assignment.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description:',
                style: Theme.of(context).textTheme.titleMedium),
            Text(assignment.description),
            const SizedBox(height: 16),
            Text('Subject: ${assignment.subject}'),
            Text('Due Date: ${formatDate(assignment.dueDate.toLocal())}'),
            Text('Total Grade: ${assignment.totalGrade}'),
            const SizedBox(height: 16),
            if (assignment.fileUrl != null && assignment.fileUrl!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Uploaded Document:'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Open Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final url = assignment.fileUrl!;
                      // TODO: Fetch the file from your API here if needed
                      // Example:
                      // final apiFileUrl = await fetchFileUrlFromApi(assignment.id);
                      // Use apiFileUrl instead of url below if needed
                      if (url.startsWith('http')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(fileUrl: url),
                          ),
                        );
                      } else {
                        await OpenFile.open(url);
                      }
                    },
                  ),
                ],
              )
            else
              const Text('No document uploaded.'),
          ],
        ),
      ),
    );
  }
}
