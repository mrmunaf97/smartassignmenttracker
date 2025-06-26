import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// Only import dart:js if on web
import 'dart:js' as js;

class PlatformPdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  const PlatformPdfViewerScreen({required this.fileUrl, Key? key})
      : super(key: key);

  @override
  State<PlatformPdfViewerScreen> createState() =>
      _PlatformPdfViewerScreenState();
}

class _PlatformPdfViewerScreenState extends State<PlatformPdfViewerScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = widget.fileUrl;
      bool opened = false;
      if (await canLaunchUrl(Uri.parse(url))) {
        try {
          await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
          opened = true;
        } catch (_) {}
      }
      if (!opened) {
        try {
          js.context.callMethod('open', [url, '_blank']);
          opened = true;
        } catch (_) {}
      }
      if (!opened) {
        setState(() {
          _error = 'Could not open PDF in new tab.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: _error != null
          ? Center(child: Text(_error!))
          : const Center(child: Text('PDF opened in new tab.')),
    );
  }
}
