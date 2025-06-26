import 'package:flutter/material.dart';

class PlatformPdfViewerScreen extends StatelessWidget {
  final String fileUrl;
  const PlatformPdfViewerScreen({required this.fileUrl, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('PDF viewing not supported on this platform.')),
    );
  }
}
