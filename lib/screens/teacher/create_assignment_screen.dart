import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../models/assignment.dart';
import '../../services/subject_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../common/color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _gradeController = TextEditingController(text: '30'); // Default grade
  final _subjectService = SubjectService();
  DateTime? _dueDate;
  String? _filePath;
  String? _selectedSubject;
  List<String> _subjects = [];
  final _assignmentService = AssignmentService();
  bool _loading = false;
  String? _error;
  String? _fileName;
  Uint8List? _fileBytes;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _subjectService.getSubjects();
    setState(() {
      _subjects = subjects;
      if (_subjects.isNotEmpty && _selectedSubject == null) {
        _selectedSubject = _subjects.first;
      }
    });
  }

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

  void _showSubjectManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SubjectManagementDialog(
          subjects: _subjects,
          onSubjectsChanged: () {
            _loadSubjects();
          },
        );
      },
    );
  }

  void _createAssignment() async {
    if (_dueDate == null || _selectedSubject == null) {
      setState(() {
        _error = 'Please select a due date and subject';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
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
            'assignments/${DateTime.now().millisecondsSinceEpoch}_$fileName';
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
      final assignment = Assignment(
        id: '',
        title: _titleController.text,
        description: _descController.text,
        dueDate: _dueDate!,
        createdBy: 'teacherId', // TODO: Replace with actual teacher id
        fileUrl: fileUrlToSave, // Save Supabase public URL
        totalGrade: int.tryParse(_gradeController.text) ?? 30,
        subject: _selectedSubject!,
      );
      await _assignmentService.createAssignment(assignment);
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Create Assignment'),
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: kIsWeb
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _buildCreateAssignmentCard(),
                    ),
                  )
                : _buildCreateAssignmentCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAssignmentCard() {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Assignment',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details below',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'Total Grade',
                hintText: 'Enter total grade (e.g., 30)',
                prefixIcon: Icon(Icons.grade),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Subject: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    isExpanded: true,
                    hint: const Text('Select Subject'),
                    items: _subjects.map((String subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubject = newValue;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showSubjectManagementDialog,
                  tooltip: 'Manage Subjects',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_dueDate == null
                  ? 'Pick Due Date'
                  : formatDate(_dueDate!.toLocal())),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title:
                  Text(_fileName == null ? 'Pick File (optional)' : _fileName!),
              trailing: const Icon(Icons.attach_file),
              onTap: _pickFile,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _createAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Subject Management Dialog
class SubjectManagementDialog extends StatefulWidget {
  final List<String> subjects;
  final VoidCallback onSubjectsChanged;

  const SubjectManagementDialog({
    super.key,
    required this.subjects,
    required this.onSubjectsChanged,
  });

  @override
  State<SubjectManagementDialog> createState() =>
      _SubjectManagementDialogState();
}

class _SubjectManagementDialogState extends State<SubjectManagementDialog> {
  final _subjectService = SubjectService();
  final _newSubjectController = TextEditingController();
  String? _selectedSubjectToRemove;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Subjects'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add new subject
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubjectController,
                    decoration: const InputDecoration(
                      labelText: 'New Subject',
                      hintText: 'Enter subject name',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (_newSubjectController.text.trim().isNotEmpty) {
                      await _subjectService
                          .addSubject(_newSubjectController.text.trim());
                      _newSubjectController.clear();
                      widget.onSubjectsChanged();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Remove subject
            const Text(
              'Remove Subject:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedSubjectToRemove,
              isExpanded: true,
              hint: const Text('Select subject to remove'),
              items: widget.subjects.map((String subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSubjectToRemove = newValue;
                });
              },
            ),
            const SizedBox(height: 8),
            if (_selectedSubjectToRemove != null)
              ElevatedButton(
                onPressed: () async {
                  await _subjectService
                      .removeSubject(_selectedSubjectToRemove!);
                  setState(() {
                    _selectedSubjectToRemove = null;
                  });
                  widget.onSubjectsChanged();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove Subject'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
