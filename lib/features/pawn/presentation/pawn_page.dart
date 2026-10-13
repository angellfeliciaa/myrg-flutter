import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/rg_integration.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/rg_webview_page.dart';
import '../../membership/data/member_repository.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../data/device_inspector.dart';
import '../data/online_pawn_api.dart';
import 'pawn_photo_page.dart';
import '../../support/presentation/support_page.dart';
import '../models/pawn_submission.dart';
import '../../simulation/models/valuation.dart';
import '../../../core/utils/formatter.dart';

class PawnPage extends StatefulWidget {
  const PawnPage({this.inspector, this.submission, this.estimate, super.key});

  /// Defaults to [DeviceInspector.forApp] (RG's SDK once it is added).
  final DeviceInspector? inspector;
  final PawnSubmission? submission;
  final ValuationResult? estimate;
  @override
  State<PawnPage> createState() => _PawnPageState();
}

class _PawnPageState extends State<PawnPage> {
  int _step = 0;
  String _category = 'HP';
  PawnSubmission? _submission;
  ValuationResult? _estimate;
  bool _courier = false;
  bool _acceptedCourierCost = false;
  bool _identityReady = false;
  bool _busy = false;
  String? _error;
  late final DeviceInspector _inspector =
      widget.inspector ?? DeviceInspector.forApp();

  /// Backend mode: the device check is done, the photos (part 2) are still to send.
  bool get _needsPhotos =>
      BackendConfig.enabled &&
      _submission != null &&
      !_submission!.isPreview &&
      !_photosSent;
  bool _photosSent = false;
  bool _manualReview = false;
  final _branch = TextEditingController();
  final _bank = TextEditingController();
  final _address = TextEditingController();
  static const _steps = ['Barang', 'Verifikasi', 'Pengiriman'];

  @override
  void initState() {
    super.initState();
    _submission = widget.submission;
    _estimate = widget.estimate;
    if (widget.estimate != null) {
      _category = switch (widget.estimate!.category.id) {
        'phone' => 'HP',
        'laptop' => 'Laptop',
        'tablet' => 'Tablet',
        'camera' => 'Kamera',
        _ => 'Lainnya',
      };
    }
    if (_submission != null) _step = 1;
  }

  @override
  void dispose() {
    _branch.dispose();
    _bank.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _inspect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _inspector.inspect(context);
      if (result != null && mounted) {
        setState(() {
          _submission = result;
          _photosSent = false;
          if (!BackendConfig.enabled || result.isPreview) _step = 1;
        });
        if (_needsPhotos) await _takePhotos();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Pemeriksaan perangkat belum tersedia. Silakan coba kembali atau kunjungi cabang.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takePhotos() async {
    final submission = _submission!;
    final range = await Navigator.push<PawnRange>(
      context,
      MaterialPageRoute(
        builder: (_) => PawnPhotoPage(
          formId: submission.formId,
          productName: submission.productName,
          estimate: submission.estimatedLoan,
        ),
      ),
    );
    if (range == null || !mounted) return;
    setState(() {
      _submission = PawnSubmission(
        formId: submission.formId,
        transactionNumber: submission.transactionNumber,
        productName: submission.productName,
        estimatedLoan: range.label,
        estimatedProcessHours: submission.estimatedProcessHours,
      );
      _photosSent = true;
      _manualReview = range.manualReviewRequired;
      _step = 1;
      _error = null;
    });
  }

  void _continue() {
    final member = MemberRepository.profile.value;
    if (!member.canReuseVerification && !_identityReady) {
      setState(
        () => _error = BackendConfig.enabled
            ? 'Hasil pemeriksaan dan foto sudah diterima Raja Gadai. Verifikasi KTP dan rekening belum bisa dilakukan dari aplikasi; tim Raja Gadai akan menghubungi kamu untuk langkah berikutnya.'
            : 'Verifikasi KTP dan rekening diperlukan sebelum melanjutkan.',
      );
      return;
    }
    setState(() {
      _step = 2;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_branch.text.trim().isEmpty ||
        (!MemberRepository.profile.value.canReuseVerification &&
            _bank.text.trim().isEmpty) ||
        (_courier && (_address.text.trim().isEmpty || !_acceptedCourierCost))) {
      setState(
        () => _error =
            'Lengkapi cabang tujuan, rekening, dan informasi pengiriman.',
      );
      return;
    }
    if (_submission?.isPreview != true) {
      setState(
        () => _error = BackendConfig.enabled
            ? 'Hasil pemeriksaan dan foto sudah diterima Raja Gadai. Pengiriman barang dan pencairan belum bisa diatur dari aplikasi; tim Raja Gadai akan menghubungi kamu.'
            : 'Pengajuan belum dapat dikirim. Silakan coba lagi setelah layanan tersedia.',
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.fact_check_outlined,
          color: AppColors.primary,
          size: 36,
        ),
        title: const Text('Pratinjau pengajuan selesai'),
        content: const Text(
          'Alur verifikasi dan pengiriman berhasil ditinjau. Belum ada pengajuan atau foto yang dikirim ke Raja Gadai.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Gadai Online')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: index <= _step
                          ? AppColors.secondary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _steps[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: index == _step
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_step == 0) ..._goods(),
        if (_step == 1) ..._verification(),
        if (_step == 2) ..._shipping(),
        if (_error != null) ...[
          const SizedBox(height: 16),
          FlowInfo(_error!, warning: true),
        ],
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() {
              _step--;
              _error = null;
            }),
            child: const Text('Kembali ke langkah sebelumnya'),
          ),
      ],
    ),
  );

  List<Widget> _goods() => [
    if (_needsPhotos) ...[
      FlowSection(
        title: _submission!.productName,
        children: [
          FlowValue('Nomor pengajuan', _submission!.formId),
          Text(
            _submission!.estimatedLoan,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pemeriksaan perangkat selesai. Langkah berikutnya: foto 7 sisi barang.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          AppButton(label: 'Ambil Foto Barang', onPressed: _takePhotos),
        ],
      ),
      const SizedBox(height: 16),
    ],
    if (_estimate case final estimate?) ...[
      FlowSection(
        title: estimate.productName,
        children: [
          Text(estimate.model.variant),
          const SizedBox(height: 8),
          Text(
            '${Formatter.rupiah(estimate.minimum)} – ${Formatter.rupiah(estimate.maximum)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Estimasi contoh dari Cek Pinjaman. Pemeriksaan barang tetap diperlukan sebelum pengajuan.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    ],
    const Text(
      'Apa yang mau kamu gadaikan?',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 10),
    const Text(
      'Pilih jenis barang. Pemeriksaan dan foto akan dipandu oleh Raja Gadai.',
      style: TextStyle(fontSize: 14, height: 1.5),
    ),
    const SizedBox(height: 20),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ['HP', 'Laptop', 'Tablet', 'Kamera', 'Lainnya']
          .map(
            (category) => ChoiceChip(
              label: Text(category),
              selected: _category == category,
              onSelected: (_) => setState(() {
                if (_category != category) _estimate = null;
                _category = category;
                _error = null;
              }),
            ),
          )
          .toList(),
    ),
    const SizedBox(height: 24),
    const FlowInfo(
      'Estimasi lama proses akan ditampilkan setelah data dan foto perangkat diterima.',
    ),
    const SizedBox(height: 20),
    AppButton(
      label: _category == 'HP'
          ? 'Mulai Pemeriksaan Perangkat'
          : 'Buka Form Raja Gadai',
      isLoading: _busy,
      onPressed: _category == 'HP'
          ? _inspect
          : () => openRgWebview(
              context,
              title: 'Gadai $_category',
              url: RgIntegration.otherGoodsUrl,
            ),
    ),
    if (RgIntegration.preview) ...[
      const SizedBox(height: 20),
      const Text(
        'Pratinjau • Gunakan contoh perangkat untuk meninjau langkah berikutnya.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      TextButton(
        onPressed: () => setState(() {
          final preview = PawnPreview.submission(_category);
          final estimate = _estimate;
          _submission = estimate == null
              ? preview
              : PawnSubmission(
                  formId: preview.formId,
                  transactionNumber: preview.transactionNumber,
                  productName:
                      '${estimate.productName} • ${estimate.model.variant}',
                  estimatedLoan:
                      '${Formatter.rupiah(estimate.minimum)} – ${Formatter.rupiah(estimate.maximum)}',
                  estimatedProcessHours: preview.estimatedProcessHours,
                  isPreview: true,
                );
          _step = 1;
          _error = null;
        }),
        child: const Text('Coba alur dengan contoh perangkat'),
      ),
    ],
  ];

  List<Widget> _verification() {
    final member = MemberRepository.profile.value;
    return [
      const Text(
        'Verifikasi pengajuan',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 18),
      FlowSection(
        title: _submission!.productName,
        children: [
          FlowValue('Nomor pengajuan', _submission!.transactionNumber),
          const Text(
            'Estimasi pinjaman',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            _submission!.estimatedLoan,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Estimasi proses: ${_submission!.estimatedProcessHours} jam setelah data lengkap.',
            style: const TextStyle(fontSize: 13),
          ),
          if (_manualReview) ...[
            const SizedBox(height: 8),
            const Text(
              'Foto diambil dari HP yang sama: estimasi sudah dipotong dan barang diperiksa ulang di cabang.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
      if (member.canReuseVerification)
        const FlowInfo(
          'KTP dan rekening kamu sudah terverifikasi dari gadai sebelumnya. Kamu dapat langsung melanjutkan.',
        )
      else
        FlowSection(
          title: 'Verifikasi KTP & rekening',
          children: [
            const Text(
              'Nasabah baru perlu menyelesaikan verifikasi identitas dan rekening pencairan.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            if (RgIntegration.preview)
              OutlinedButton(
                onPressed: () => setState(() => _identityReady = true),
                child: Text(
                  _identityReady
                      ? 'Pratinjau verifikasi selesai'
                      : 'Simulasikan verifikasi',
                ),
              ),
          ],
        ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => _submission!.isPreview || !BackendConfig.enabled
            ? context.push(
                AppRoutes.support,
                extra: _submission!.transactionNumber,
              )
            : Navigator.push<void>(
                context,
                MaterialPageRoute(
                  // Not a pawn yet: the banding is about the Gadai Online submission.
                  builder: (_) => SupportPage(
                    transactionNumber: _submission!.formId,
                    referenceType: 'valuation',
                  ),
                ),
              ),
        icon: const Icon(Icons.support_agent_rounded),
        label: const Text('Ajukan Banding'),
      ),
      const SizedBox(height: 12),
      AppButton(label: 'Lanjut Gadai', onPressed: _continue),
    ];
  }

  List<Widget> _shipping() => [
    const Text(
      'Atur pengiriman',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 18),
    FlowSection(
      title: 'Rekening pencairan',
      children: [
        if (MemberRepository.profile.value.canReuseVerification)
          const Text(
            'Rekening terverifikasi yang tersimpan akan digunakan.',
            style: TextStyle(fontSize: 14, height: 1.5),
          )
        else
          TextField(
            controller: _bank,
            decoration: const InputDecoration(labelText: 'Rekening pencairan'),
          ),
      ],
    ),
    FlowSection(
      title: 'Cabang tujuan',
      children: [
        TextField(
          controller: _branch,
          decoration: const InputDecoration(labelText: 'Nama cabang'),
        ),
      ],
    ),
    FlowSection(
      title: 'Metode pengiriman',
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Bawa ke Cabang'),
              icon: Icon(Icons.storefront_outlined),
            ),
            ButtonSegment(
              value: true,
              label: Text('Dijemput oleh Kurir'),
              icon: Icon(Icons.local_shipping_outlined),
            ),
          ],
          selected: {_courier},
          onSelectionChanged: (values) =>
              setState(() => _courier = values.single),
        ),
        if (_courier) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Alamat penjemputan'),
          ),
          const SizedBox(height: 12),
          const FlowInfo(
            'Apabila proses gadai gagal, biaya kurir menjadi tanggungan nasabah.',
            warning: true,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acceptedCourierCost,
            onChanged: (v) => setState(() => _acceptedCourierCost = v!),
            title: const Text(
              'Saya memahami ketentuan biaya kurir',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ],
    ),
    AppButton(label: 'Submit', onPressed: _submit),
  ];
}
