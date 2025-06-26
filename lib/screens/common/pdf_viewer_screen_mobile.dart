import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:open_file/open_file.dart';
import 'dart:io';

class PlatformPdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  const PlatformPdfViewerScreen({required this.fileUrl, Key? key})
      : super(key: key);

  @override
  State<PlatformPdfViewerScreen> createState() =>
      _PlatformPdfViewerScreenState();
}

class _PlatformPdfViewerScreenState extends State<PlatformPdfViewerScreen> {
  PdfController? _controller;
  bool _loading = true;
  String? _error;
  String? _externalFilePath;
  bool _openedExternally = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      Future<PdfDocument> docFuture;
      if (widget.fileUrl.startsWith('http')) {
        final data = (await NetworkAssetBundle(Uri.parse(widget.fileUrl))
                .load(widget.fileUrl))
            .buffer
            .asUint8List();
        // Save to temp file for external opening
        final tempDir = Directory.systemTemp;
        final fileName = widget.fileUrl.split('/').last;
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(data);
        _externalFilePath = tempFile.path;
        docFuture = PdfDocument.openData(data);
      } else {
        _externalFilePath = widget.fileUrl;
        docFuture = PdfDocument.openFile(widget.fileUrl);
      }
      setState(() {
        _controller = PdfController(document: docFuture);
        _loading = false;
      });
      // Immediately open externally after loading
      _openExternal();
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: $e';
        _loading = false;
      });
    }
  }

  void _openExternal() async {
    if (_openedExternally) return;
    _openedExternally = true;
    if (_externalFilePath != null && await File(_externalFilePath!).exists()) {
      await OpenFile.open(_externalFilePath!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('File not available for external viewer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_loading && _error == null && widget.fileUrl.isNotEmpty) {
        final fileName = widget.fileUrl.split('/').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName loaded successfully')),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : PdfView(controller: _controller!),
    );
  }
}
