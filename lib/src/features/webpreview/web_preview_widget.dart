import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/services/webpreview_service.dart';

/// Embeds the local server preview (task.md §22).
///
/// Listens for [WebPreviewService.urlStream] and also reads the current
/// [WebPreviewService.previewUrl] once on init. Shows an empty state until a
/// server is detected.
class WebPreviewWidget extends StatefulWidget {
  const WebPreviewWidget({super.key, this.showAddressBar = true});

  final bool showAddressBar;

  @override
  State<WebPreviewWidget> createState() => _WebPreviewWidgetState();
}

class _WebPreviewWidgetState extends State<WebPreviewWidget> {
  final _service = WebPreviewService();

  StreamSubscription<String?>? _urlSub;
  InAppWebViewController? _webController;
  String? _url;

  @override
  void initState() {
    super.initState();
    _urlSub = _service.urlStream.listen(_onUrl, onError: (_) {});
    unawaited(_loadInitialUrl());
  }

  @override
  void dispose() {
    _urlSub?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialUrl() async {
    try {
      final url = await _service.previewUrl;
      if (url != null) _onUrl(url);
    } on Exception {
      // Native preview API unavailable yet; stream events will drive us.
    }
  }

  void _onUrl(String? url) {
    if (!mounted || url == null || url == _url) return;
    final controller = _webController;
    if (controller != null) {
      unawaited(controller.loadUrl(urlRequest: URLRequest(url: WebUri(url))));
    }
    setState(() => _url = url);
  }

  Future<void> _reload() => _webController?.reload() ?? Future.value();

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) {
      return const _EmptyState();
    }
    return Column(
      children: [
        if (widget.showAddressBar) _buildAddressBar(url),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: false,
              transparentBackground: true,
            ),
            onWebViewCreated: (controller) => _webController = controller,
            onConsoleMessage: (_, message) {},
          ),
        ),
      ],
    );
  }

  Widget _buildAddressBar(String url) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Reload',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public_off,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No server detected.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Run a task that serves HTTP '
            '(e.g. php artisan serve / npm run dev).',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}