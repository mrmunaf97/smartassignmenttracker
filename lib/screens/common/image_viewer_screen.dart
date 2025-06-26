import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  const ImageViewerScreen({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (imageUrl.isNotEmpty) {
        final fileName = imageUrl.split('/').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName loaded successfully')),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Image Viewer')),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
