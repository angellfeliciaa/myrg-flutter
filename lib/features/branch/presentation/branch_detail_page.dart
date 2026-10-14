import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/backend_config.dart';
import '../../../shared/widgets/phase_one_widgets.dart';
import '../models/branch.dart';
import 'branch_page.dart';

class BranchDetailPage extends StatelessWidget {
  const BranchDetailPage({required this.branch, super.key});
  final Branch branch;

  /// Backend mode: the outlet in Google Maps / the phone's dialer. Says so when the phone has
  /// no app for it.
  Future<void> _open(
    ScaffoldMessengerState messenger,
    Uri uri,
    String failure,
  ) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(failure)));
  }

  void _openMaps(BuildContext context) => _open(
    ScaffoldMessenger.of(context),
    branch.mapsUri!,
    'Google Maps tidak bisa dibuka.',
  );

  void _map(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(branch.address),
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: const Center(child: BranchMapImage()),
              ),
            ),
            const Text(
              'Peta ilustrasi FE. Cubit untuk memperbesar; navigasi lokasi asli belum dihubungkan.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            PhaseOneButton(
              label: 'Tutup Peta',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
  void _contact(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hubungi ${branch.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (BackendConfig.enabled) ...[
              Text(
                branch.phone == null
                    ? 'Nomor telepon cabang ini belum tersedia.'
                    : 'Telepon: ${branch.phone}',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (branch.phone != null) ...[
                PhaseOneButton(
                  label: 'Telepon Cabang',
                  onPressed: () {
                    Navigator.pop(context);
                    _open(
                      messenger,
                      branch.dialUri!,
                      'Aplikasi telepon tidak bisa dibuka.',
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: branch.phone!));
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Nomor cabang disalin.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 48),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Salin Nomor'),
                ),
              ],
            ] else ...[
              const Text(
                'Ini simulasi FE. Nomor telepon dan WhatsApp cabang asli belum tersedia; tidak ada panggilan atau pesan yang dikirim.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              PhaseOneButton(
                label: 'Simulasikan Panggilan',
                onPressed: () {
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Simulasi panggilan selesai. Tidak menghubungi cabang.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Backend mode: "Buka Peta" is Google Maps and needs the outlet's coordinates; "Hubungi
    // Cabang" needs its phone number. A button without its data is left out.
    final live = BackendConfig.enabled;
    final showMap = !live || branch.hasLocation;
    final showContact = !live || branch.phone != null;
    return PhaseOneScaffold(
      title: 'Detail Cabang',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          GestureDetector(
            onTap: live && branch.hasLocation ? () => _openMaps(context) : null,
            child: const BranchMapImage(detail: true),
          ),
          if (showMap || showContact) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                if (showMap)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          live ? _openMaps(context) : _map(context),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        foregroundColor: AppColors.primary,
                      ),
                      // The longer label must not wrap on a narrow phone.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          live ? 'Buka di Google Maps' : 'Buka Peta',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                if (showMap && showContact) const SizedBox(width: 24),
                if (showContact)
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _contact(context),
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text(
                        'Hubungi Cabang',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(
            branch.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            branch.address,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          BranchMeta(branch: branch),
          const SizedBox(height: 24),
          PhaseOneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Jam Operasional',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                for (final entry in branch.openingHours)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.$1,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          entry.$2,
                          style: TextStyle(
                            fontSize: 12,
                            color: entry.$2 == 'Tutup'
                                ? Colors.red
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PhaseOneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Layanan Tersedia',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 8,
                    runSpacing: 16,
                    children: [
                      for (
                        int index = 0;
                        index < branch.services.length;
                        index++
                      )
                        SizedBox(
                          width: (constraints.maxWidth - 24) / 4,
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? const Color(0xFFEEDFFE)
                                      : const Color(0xFFCCE18A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.asset(
                                  'assets/icons/branch_${['phone', 'electronics', 'payment', 'collection'][index]}.png',
                                  width: [35.0, 25.0, 30.0, 30.0][index],
                                  height: [35.0, 25.0, 30.0, 30.0][index],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                branch.services[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!live) ...[
            const SizedBox(height: 16),
            const Text(
              'Data cabang contoh untuk demo FE.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
