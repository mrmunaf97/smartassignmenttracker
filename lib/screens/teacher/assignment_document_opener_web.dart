import 'package:flutter/material.dart';
import 'dart:html' as html;

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
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue, width: 1.5),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () async {
        setState(() => _loading = true);
        final url = widget.fileUrl;
        final fileName = url.split('/').last;
        final anchor = html.AnchorElement(href: url)
          ..download = fileName
          ..target = 'blank';
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName downloaded')),
        );
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
