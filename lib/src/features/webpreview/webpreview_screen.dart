import 'package:flutter/material.dart';

import 'web_preview_widget.dart';

/// Web preview: in-app browser for a locally served app (task.md §22).
class WebPreviewScreen extends StatelessWidget {
  const WebPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Web Preview')),
      body: const WebPreviewWidget(),
    );
  }
}