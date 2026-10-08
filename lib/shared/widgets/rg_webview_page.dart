import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'flow_widgets.dart';

class RgWebviewPage extends StatefulWidget {
  const RgWebviewPage({required this.title, this.url, super.key});
  final String title;
  final Uri? url;
  @override
  State<RgWebviewPage> createState() => _RgWebviewPageState();
}

class _RgWebviewPageState extends State<RgWebviewPage> {
  WebViewController? _controller;
  int _progress = 0;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    if (widget.url == null ||
        widget.url!.scheme != 'https' ||
        kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform)) {
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _failed = true);
            }
          },
          onNavigationRequest: (request) =>
              Uri.tryParse(request.url)?.scheme == 'https'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(widget.url!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: _controller == null
        ? const Padding(
            padding: EdgeInsets.all(24),
            child: FlowInfo(
              'Layanan ini belum tersedia. Silakan hubungi cabang atau coba lagi nanti.',
              warning: true,
            ),
          )
        : _failed
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Halaman belum berhasil dimuat.'),
                TextButton(
                  onPressed: () {
                    setState(() => _failed = false);
                    _controller!.reload();
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          )
        : Column(
            children: [
              if (_progress < 100)
                LinearProgressIndicator(value: _progress / 100),
              Expanded(child: WebViewWidget(controller: _controller!)),
            ],
          ),
  );
}

Future<void> openRgWebview(
  BuildContext context, {
  required String title,
  String? url,
}) {
  final candidate = Uri.tryParse(url ?? '');
  final safeUrl =
      candidate != null &&
          candidate.scheme == 'https' &&
          candidate.host.isNotEmpty
      ? candidate
      : null;
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => RgWebviewPage(title: title, url: safeUrl),
    ),
  );
}
