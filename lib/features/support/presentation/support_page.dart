import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../../../core/network/myrg_api.dart';
import '../../../core/network/rg_integration.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/rg_webview_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({
    this.transactionNumber = '',
    this.referenceType = 'transaction',
    super.key,
  });
  final String transactionNumber;

  /// 'transaction' (nomor transaksi gadai) or 'valuation' (Form ID of a Gadai Online
  /// submission, before it becomes a pawn).
  final String referenceType;
  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  late final _number = TextEditingController(text: widget.transactionNumber);
  final _message = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  String? _sent;
  @override
  void dispose() {
    _number.dispose();
    _message.dispose();
    super.dispose();
  }

  /// Backend mode: the appeal is recorded at MyRG (POST /appeals) so CS sees it in the admin
  /// panel. When a chat link is configured (or CS attached RG's), the chat opens right away.
  Future<void> _startWithBackend() async {
    try {
      final data =
          await MyrgApi.post(
                '/appeals',
                body: {
                  'referenceType': widget.referenceType,
                  'referenceNumber': _number.text.trim(),
                  if (_message.text.trim().isNotEmpty)
                    'message': _message.text.trim(),
                },
              )
              as Map<String, dynamic>;
      final url = data['conversationUrl'] as String?;
      final id = data['conversationId'] ?? '#${data['id']}';
      if (!mounted) return;
      if (url != null && url.startsWith('https://')) {
        await openRgWebview(context, title: 'Chat Raja Gadai', url: url);
      } else {
        setState(
          () => _sent =
              'Banding terkirim ($id). Tim CS Raja Gadai akan menghubungi kamu lewat nomor HP terdaftar.',
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    }
  }

  Future<void> _start() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _sent = null;
    });
    if (BackendConfig.enabled) {
      await _startWithBackend();
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final response = await RgIntegration.dio.postUri(
        RgIntegration.requireHttps(RgIntegration.conversationUrl),
        data: {'transactionNumber': _number.text.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      final id = data['conversationId'] as String;
      final url = data['conversationUrl'] as String;
      if (id.isEmpty) throw const FormatException('Missing conversation ID');
      RgIntegration.requireHttps(url);
      if (!mounted) return;
      await openRgWebview(context, title: 'Chat Raja Gadai', url: url);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chat belum dapat dihubungkan. Silakan coba lagi atau datang ke cabang.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bantuan & Banding')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.support_agent_rounded, size: 56),
          const SizedBox(height: 20),
          const Text(
            'Bicarakan transaksi kamu',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'Masukkan nomor transaksi. Tim CS atau penaksir Raja Gadai akan membantu memeriksa pengajuan dan banding kamu.',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _number,
            decoration: InputDecoration(
              labelText: widget.referenceType == 'valuation'
                  ? 'Nomor pengajuan'
                  : 'Nomor transaksi',
              hintText: 'Contoh: RG77123',
            ),
            validator: (value) => value?.trim().isEmpty != false
                ? 'Masukkan nomor transaksi'
                : null,
          ),
          if (BackendConfig.enabled) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _message,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Ceritakan masalahnya (opsional)',
                hintText:
                    'Contoh: Taksiran terlalu rendah dibanding harga pasar',
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_sent != null) ...[FlowInfo(_sent!), const SizedBox(height: 16)],
          if (_error != null) ...[
            FlowInfo(_error!, warning: true),
            const SizedBox(height: 16),
          ],
          AppButton(
            // No live chat yet in backend mode: the banding is recorded for CS to follow up.
            label: BackendConfig.enabled
                ? 'Kirim Banding'
                : 'Hubungkan ke Chat RG',
            isLoading: _loading,
            onPressed: _start,
          ),
        ],
      ),
    ),
  );
}
