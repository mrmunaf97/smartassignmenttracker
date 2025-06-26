import 'package:flutter/material.dart';
// Platform-specific implementation will be imported below
import 'pdf_viewer_screen_stub.dart'
    if (dart.library.html) 'pdf_viewer_screen_web.dart'
    if (dart.library.io) 'pdf_viewer_screen_mobile.dart';

class PdfViewerScreen extends StatelessWidget {
  final String fileUrl;
  const PdfViewerScreen({required this.fileUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformPdfViewerScreen(fileUrl: fileUrl);
  }
}
