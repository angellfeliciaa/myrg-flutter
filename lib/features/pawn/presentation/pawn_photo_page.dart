import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../data/online_pawn_api.dart';

enum _Mode { choose, otherPhone, thisPhone }

/// Gadai Online part 2: photos of the item for [formId]. Pops a [PawnRange] once Raja Gadai
/// has them. Two ways (notes #14):
/// - another phone (recommended): a one-time link shown as QR, opened on the second phone;
/// - this phone: allowed, but the estimate is reduced and the branch checks the item again.
///
/// [retakeLabels]: sides the officer asked to shoot again (FOTO_ULANG notification).
class PawnPhotoPage extends StatefulWidget {
  const PawnPhotoPage({
    required this.formId,
    this.productName,
    this.retakeLabels = const [],
    this.pollInterval = const Duration(seconds: 3),
    super.key,
  });
  final String formId;
  final String? productName;
  final List<String> retakeLabels;
  final Duration pollInterval;
  @override
  State<PawnPhotoPage> createState() => _PawnPhotoPageState();
}

class _PawnPhotoPageState extends State<PawnPhotoPage>
    with WidgetsBindingObserver {
  _Mode _mode = _Mode.choose;
  bool _busy = false;
  String? _error;

  // Another phone
  PhotoLink? _link;
  PhotoProgress? _progress;
  Timer? _poll;
  bool _checking = false;

  // This phone
  final _photos = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  /// No polling while the app is in the background (battery, data); resumes with a check.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_mode == _Mode.otherPhone && _poll == null) _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  void _startPolling() {
    final link = _link;
    if (link == null || link.expired || (_progress?.complete ?? false)) return;
    _poll?.cancel();
    _poll = Timer.periodic(widget.pollInterval, (_) => _checkProgress());
    _checkProgress();
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startOtherPhone() => _run(() async {
    final link = await OnlinePawnApi.createPhotoLink(widget.formId);
    if (!mounted) return;
    setState(() {
      _mode = _Mode.otherPhone;
      _link = link;
      _progress = null;
    });
    _startPolling();
  });

  Future<void> _checkProgress() async {
    // A slow answer must not pile up requests: skip ticks while one is on the way.
    if (_checking) return;
    _checking = true;
    try {
      final progress = await OnlinePawnApi.photoProgress(widget.formId);
      if (!mounted) return;
      setState(() => _progress = progress);
      if (progress.complete || _link!.expired) _stopPolling();
    } on ApiException catch (_) {
      // Next tick tries again; a network blip must not end the session.
    } finally {
      _checking = false;
    }
  }

  Future<void> _sendOtherPhone() => _run(() async {
    final result = await OnlinePawnApi.submitPhotoLink(widget.formId);
    if (mounted) Navigator.pop(context, result);
  });

  Future<void> _shoot(String label) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text('Foto sisi ${photoSides[label]}'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
    if (source == null) return;
    // Resized on the phone: 7 photos go up in one request.
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _photos[label] = bytes);
  }

  Future<void> _sendThisPhone() => _run(() async {
    final result = await OnlinePawnApi.submitPhotos(widget.formId, _photos);
    if (mounted) Navigator.pop(context, result);
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _mode == _Mode.choose && !_busy,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop || _busy) return;
      _stopPolling();
      setState(() {
        _mode = _Mode.choose;
        _error = null;
      });
    },
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Foto Barang')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.productName != null)
            Text(
              widget.productName!,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          Text(
            'No. pengajuan ${widget.formId}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (widget.retakeLabels.isNotEmpty) ...[
            FlowInfo(
              'Petugas meminta foto ulang: ${widget.retakeLabels.map((l) => photoSides[l] ?? l).join(', ')}. '
              'Kirim ulang ketujuh sisi agar pengajuan bisa diperiksa.',
              warning: true,
            ),
            const SizedBox(height: 16),
          ],
          ...switch (_mode) {
            _Mode.choose => _choose(),
            _Mode.otherPhone => _otherPhone(),
            _Mode.thisPhone => _thisPhone(),
          },
          if (_error != null) ...[
            const SizedBox(height: 16),
            FlowInfo(_error!, warning: true),
          ],
        ],
      ),
    ),
  );

  List<Widget> _choose() => [
    const Text(
      'Foto 7 sisi barang: depan, belakang, atas, bawah, kiri, kanan, dan layar menyala.',
      style: TextStyle(fontSize: 14, height: 1.5),
    ),
    const SizedBox(height: 20),
    _option(
      icon: Icons.qr_code_2_rounded,
      title: 'Pakai HP lain (disarankan)',
      body:
          'Barang yang digadai adalah HP ini, jadi foto diambil dengan HP lain. Pindai QR, lalu ikuti petunjuk di HP tersebut.',
      onTap: _busy ? null : _startOtherPhone,
    ),
    const SizedBox(height: 12),
    _option(
      icon: Icons.phone_android_rounded,
      title: 'Foto dari HP ini',
      body:
          'Bisa dipakai bila tidak ada HP lain, tetapi estimasi pinjaman menjadi lebih rendah dan barang diperiksa ulang di cabang.',
      onTap: _busy
          ? null
          : () => setState(() {
              _mode = _Mode.thisPhone;
              _error = null;
            }),
    ),
    if (_busy) ...[
      const SizedBox(height: 24),
      const Center(child: CircularProgressIndicator()),
    ],
  ];

  Widget _option({
    required IconData icon,
    required String title,
    required String body,
    required VoidCallback? onTap,
  }) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.divider),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  List<Widget> _otherPhone() {
    final link = _link!;
    final progress = _progress;
    final uploaded = progress?.uploaded ?? const <String>{};
    final expired = link.expired && !(progress?.complete ?? false);
    return [
      const Text(
        'Pindai QR ini dengan HP lain',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'Kamera HP lain akan membuka halaman foto Raja Gadai. Tidak perlu masuk akun. Biarkan halaman ini tetap terbuka.',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 16),
      Center(
        child: Opacity(
          opacity: expired ? .2 : 1,
          child: QrImageView(
            data: link.captureUrl,
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
      ),
      Center(
        child: TextButton.icon(
          onPressed: expired
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: link.captureUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link foto disalin.')),
                  );
                },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Salin link'),
        ),
      ),
      if (expired) ...[
        const FlowInfo('Link foto sudah tidak berlaku.', warning: true),
        const SizedBox(height: 12),
        AppButton(
          label: 'Buat Link Baru',
          isLoading: _busy,
          onPressed: _startOtherPhone,
        ),
      ] else
        Text(
          'Berlaku sampai pukul ${TimeOfDay.fromDateTime(link.expiresAt).format(context)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      const SizedBox(height: 20),
      for (final side in photoSides.entries)
        _sideRow(side.key, side.value, done: uploaded.contains(side.key)),
      const SizedBox(height: 20),
      AppButton(
        label: progress?.complete == true
            ? 'Kirim Foto'
            : 'Menunggu foto (${uploaded.length}/${photoSides.length})',
        isLoading: _busy,
        onPressed: progress?.complete == true ? _sendOtherPhone : null,
      ),
    ];
  }

  List<Widget> _thisPhone() => [
    const FlowInfo(
      'Foto dari HP yang sama: estimasi pinjaman dipotong dan barang diperiksa ulang di cabang.',
      warning: true,
    ),
    const SizedBox(height: 16),
    GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        for (final side in photoSides.entries)
          InkWell(
            onTap: _busy ? null : () => _shoot(side.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.retakeLabels.contains(side.key)
                      ? AppColors.error
                      : AppColors.divider,
                ),
                image: _photos[side.key] == null
                    ? null
                    : DecorationImage(
                        // Thumbnail decode: 7 full 1280 px photos would take ~45 MB.
                        image: ResizeImage(
                          MemoryImage(_photos[side.key]!),
                          width: 360,
                        ),
                        fit: BoxFit.cover,
                        opacity: .6,
                      ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _photos.containsKey(side.key)
                        ? Icons.check_circle
                        : Icons.add_a_photo_outlined,
                    color: _photos.containsKey(side.key)
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    side.value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
    const SizedBox(height: 20),
    AppButton(
      label: 'Kirim ${_photos.length}/${photoSides.length} Foto',
      isLoading: _busy,
      onPressed: _photos.length == photoSides.length ? _sendThisPhone : null,
    ),
  ];

  Widget _sideRow(String label, String name, {required bool done}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.success : AppColors.divider,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name)),
        if (widget.retakeLabels.contains(label))
          const Text(
            'Diminta ulang',
            style: TextStyle(fontSize: 12, color: AppColors.error),
          ),
      ],
    ),
  );
}
