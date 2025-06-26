import 'package:flutter/material.dart';
import '../../models/assignment.dart';
import '../../services/assignment_service.dart';
import '../../models/submission.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/offline_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/color.dart';
import 'package:open_file/open_file.dart';
import '../common/pdf_viewer_screen.dart';

class AssignmentListScreen extends StatelessWidget {
  final Assignment assignment;
  const AssignmentListScreen({required this.assignment, super.key});

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
                  const Text('Assignment Document:'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
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
                    onPressed: () async {
                      final url = assignment.fileUrl!;
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
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AssignmentSubmissionScreen(assignment: assignment),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssignmentSubmissionScreen extends StatefulWidget {
  final Assignment assignment;
  const AssignmentSubmissionScreen({required this.assignment, super.key});

  @override
  State<AssignmentSubmissionScreen> createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState
    extends State<AssignmentSubmissionScreen> {
  String? _filePath;
  final _remarksController = TextEditingController();
  final _assignmentService = AssignmentService();
  final _offlineService = OfflineService();
  bool _loading = false;
  String? _error;

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
    }
  }

  void _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _offlineService.getUser();
      final studentId = user?['uid'] ?? 'unknown';
      final submission = Submission(
        id: '',
        assignmentId: widget.assignment.id,
        studentId: studentId,
        fileUrl: _filePath, // TODO: Upload file and get URL
        submittedAt: DateTime.now(),
        grade: null,
        remarks: _remarksController.text,
      );
      final docRef = await FirebaseFirestore.instance
          .collection('submissions')
          .add(submission.toMap());
      // Update the submission with the Firestore document ID
      await FirebaseFirestore.instance
          .collection('submissions')
          .doc(docRef.id)
          .update({'id': docRef.id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Assignment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(_filePath == null
                  ? 'Pick File'
                  : getFileNameFromPath(_filePath)),
              trailing: const Icon(Icons.attach_file),
              onTap: _pickFile,
            ),
            TextField(
              controller: _remarksController,
              decoration:
                  const InputDecoration(labelText: 'Remarks (optional)'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
