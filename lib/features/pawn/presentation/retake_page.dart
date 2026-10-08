import 'package:flutter/material.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../activity/models/activity_transaction.dart';
import '../data/device_inspector.dart';

class RetakePage extends StatefulWidget {
  const RetakePage({
    required this.transaction,
    this.inspector = const UnavailableDeviceInspector(),
    super.key,
  });
  final ActivityTransaction transaction;
  final DeviceInspector inspector;
  @override
  State<RetakePage> createState() => _RetakePageState();
}

class _RetakePageState extends State<RetakePage> {
  bool _loading = false;
  String? _message;
  Future<void> _retake() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final formId = widget.transaction.pawn?.formId;
      if (formId == null) throw const FormatException('No form ID');
      final result = await widget.inspector.inspect(context, formId: formId);
      if (result != null && result.formId != formId) {
        throw const FormatException('Form ID mismatch');
      }
      if (mounted && result != null) {
        setState(
          () => _message =
              'Foto diterima. Tunggu pembaruan hasil verifikasi dari Raja Gadai.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Pengambilan foto ulang belum tersedia. Coba lagi atau hubungi cabang.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Foto Ulang Perangkat')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          widget.transaction.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        FlowInfo(
          widget.transaction.pawn?.retakeInstructions ??
              'Ambil ulang foto yang diminta petugas.',
          warning: true,
        ),
        const SizedBox(height: 20),
        const Text(
          'Foto akan dikaitkan dengan pengajuan yang sama. Ikuti petunjuk pemeriksaan perangkat Raja Gadai.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (_message != null) ...[
          FlowInfo(_message!),
          const SizedBox(height: 16),
        ],
        AppButton(
          label: 'Mulai Foto Ulang',
          isLoading: _loading,
          onPressed: _retake,
        ),
      ],
    ),
  );
}
