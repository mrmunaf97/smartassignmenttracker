import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'package:flutter/services.dart' show NetworkAssetBundle;

class PdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  const PdfViewerScreen({required this.fileUrl, super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfController? _controller;
  bool _loading = true;
  String? _error;

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
        docFuture = PdfDocument.openData(data);
      } else if (File(widget.fileUrl).existsSync()) {
        docFuture = PdfDocument.openFile(widget.fileUrl);
      } else {
        docFuture = PdfDocument.openAsset(widget.fileUrl);
      }
      setState(() {
        _controller = PdfController(document: docFuture);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
