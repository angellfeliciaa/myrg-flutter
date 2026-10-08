import 'package:flutter/material.dart';
import '../../../core/network/rg_integration.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/rg_webview_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({this.transactionNumber = '', super.key});
  final String transactionNumber;
  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  late final _number = TextEditingController(text: widget.transactionNumber);
  final _form = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
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
            decoration: const InputDecoration(
              labelText: 'Nomor transaksi',
              hintText: 'Contoh: RG77123',
            ),
            validator: (value) => value?.trim().isEmpty != false
                ? 'Masukkan nomor transaksi'
                : null,
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            FlowInfo(_error!, warning: true),
            const SizedBox(height: 16),
          ],
          AppButton(
            label: 'Hubungkan ke Chat RG',
            isLoading: _loading,
            onPressed: _start,
          ),
        ],
      ),
    ),
  );
}
