import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/network/backend_config.dart';
import 'flow_widgets.dart';

/// Pages the webview may open: https everywhere. A debug build may also open the MyRG backend
/// it is connected to over plain http (the stand-in payment page of a local test backend).
bool rgWebviewAllows(Uri uri) {
  if (uri.host.isEmpty) return false;
  if (uri.scheme == 'https') return true;
  return kDebugMode &&
      uri.scheme == 'http' &&
      uri.host == Uri.parse(BackendConfig.baseUrl).host;
}

/// A local backend builds its links from APP_URL (often http://localhost:8000), which the
/// emulator cannot open: debug builds point such links at the API host instead.
Uri rgWebviewLocalFix(Uri uri) {
  if (!kDebugMode || !{'localhost', '127.0.0.1'}.contains(uri.host)) return uri;
  final api = Uri.parse(BackendConfig.baseUrl);
  return uri.replace(scheme: api.scheme, host: api.host, port: api.port);
}

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
        !rgWebviewAllows(widget.url!) ||
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
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            return target != null && rgWebviewAllows(target)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
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
  final parsed = Uri.tryParse(url ?? '');
  final candidate = parsed == null ? null : rgWebviewLocalFix(parsed);
  final safeUrl = candidate != null && rgWebviewAllows(candidate)
      ? candidate
      : null;
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => RgWebviewPage(title: title, url: safeUrl),
    ),
  );
}
