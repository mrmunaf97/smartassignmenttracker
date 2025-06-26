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
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../common/image_viewer_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter/services.dart' show NetworkAssetBundle;

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
                  AssignmentDocumentOpener(fileUrl: assignment.fileUrl!),
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
  final _remarksController = TextEditingController();
  final _assignmentService = AssignmentService();
  final _offlineService = OfflineService();
  bool _loading = false;
  String? _error;
  String? _fileName;
  String? _filePath;
  Uint8List? _fileBytes;
  bool _viewLoading = false;

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          _fileBytes = result.files.single.bytes;
          _filePath = null;
        } else {
          _filePath = result.files.single.path;
          _fileBytes = null;
        }
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
      String? fileUrlToSave;
      if ((_filePath != null && _filePath!.isNotEmpty) ||
          (kIsWeb && _fileBytes != null)) {
        Uint8List? uploadBytes;
        String? fileName = _fileName;
        if (kIsWeb) {
          uploadBytes = _fileBytes;
          if (uploadBytes == null)
            throw Exception('No file bytes found for web upload');
        } else {
          if (_filePath == null)
            throw Exception('No file path found for mobile upload');
          uploadBytes = await File(_filePath!).readAsBytes();
        }
        final storage = Supabase.instance.client.storage;
        final uploadPath =
            'submissions/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        String? contentType = 'application/octet-stream';
        if (fileName != null) {
          final lower = fileName.toLowerCase();
          if (lower.endsWith('.pdf')) {
            contentType = 'application/pdf';
          } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
            contentType = 'image/jpeg';
          } else if (lower.endsWith('.png')) {
            contentType = 'image/png';
          } else if (lower.endsWith('.gif')) {
            contentType = 'image/gif';
          }
        }
        final uploadRes = await storage.from('uploads').uploadBinary(
              uploadPath,
              uploadBytes!,
              fileOptions: FileOptions(contentType: contentType),
            );
        if (uploadRes.isEmpty) throw Exception('File upload failed');
        fileUrlToSave = storage.from('uploads').getPublicUrl(uploadPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fileName loaded successfully')),
          );
        }
      }
      final submission = Submission(
        id: '',
        assignmentId: widget.assignment.id,
        studentId: studentId,
        fileUrl: fileUrlToSave,
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
              title: Text(_fileName == null ? 'Pick File' : _fileName!),
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

class AssignmentDocumentOpener extends StatefulWidget {
  final String fileUrl;
  final String label;
  const AssignmentDocumentOpener(
      {required this.fileUrl, this.label = 'View Document', Key? key})
      : super(key: key);

  @override
  State<AssignmentDocumentOpener> createState() =>
      _AssignmentDocumentOpenerState();
}

class _AssignmentDocumentOpenerState extends State<AssignmentDocumentOpener> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(_getFileIcon(widget.fileUrl)),
      label: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Text(widget.label),
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
        if (kIsWeb) {
          final url = widget.fileUrl;
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
          return;
        }
        setState(() => _loading = true);
        String filePath = widget.fileUrl;
        if (filePath.startsWith('http')) {
          final data =
              (await NetworkAssetBundle(Uri.parse(filePath)).load(filePath))
                  .buffer
                  .asUint8List();
          final tempDir = Directory.systemTemp;
          final fileName = filePath.split('/').last;
          final tempFile = File('${tempDir.path}/$fileName');
          await tempFile.writeAsBytes(data);
          filePath = tempFile.path;
        }
        await OpenFile.open(filePath);
        setState(() => _loading = false);
      },
    );
  }
}

IconData _getFileIcon(String url) {
  final lowerUrl = url.toLowerCase();
  if (lowerUrl.endsWith('.pdf')) return Icons.picture_as_pdf;
  if (lowerUrl.endsWith('.jpg') ||
      lowerUrl.endsWith('.jpeg') ||
      lowerUrl.endsWith('.png') ||
      lowerUrl.endsWith('.gif')) return Icons.image;
  return Icons.insert_drive_file;
}
