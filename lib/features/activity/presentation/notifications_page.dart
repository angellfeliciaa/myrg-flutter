import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../data/activity_api.dart';
import '../data/activity_repository.dart';
import '../data/notification_api.dart';
import '../../pawn/presentation/pawn_photo_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => BackendConfig.enabled
      ? const _InboxPage()
      : Scaffold(
          appBar: AppBar(title: const Text('Notifikasi')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Update pengajuan kamu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              ...ActivityRepository.ongoing
                  .where((item) => item.pawn?.requiresRetake == true)
                  .map(
                    (item) => FlowSection(
                      title: 'Foto perangkat perlu diulang',
                      children: [
                        Text(
                          item.pawn!.retakeInstructions!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Text('No. ${item.reference}'),
                        TextButton(
                          onPressed: () => context.push(
                            AppRoutes.activityDetail,
                            extra: item,
                          ),
                          child: const Text('Lihat pengajuan'),
                        ),
                      ],
                    ),
                  ),
              const FlowInfo(
                'Pratinjau notifikasi. Update petugas penjemputan dan permintaan foto ulang akan mengikuti data Raja Gadai.',
              ),
            ],
          ),
        );
}

/// Backend mode: the MyRG inbox (GET /notifications).
class _InboxPage extends StatefulWidget {
  const _InboxPage();
  @override
  State<_InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<_InboxPage> {
  List<InboxNotification>? _items;
  int _unread = 0;
  int _page = 1;
  int _lastPage = 1;
  bool _loadingMore = false;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await NotificationApi.inbox();
      if (mounted) {
        setState(() {
          _items = page.items;
          _unread = page.unread;
          _page = 1;
          _lastPage = page.lastPage;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.displayMessage);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await NotificationApi.inbox(page: _page + 1);
      if (!mounted) return;
      final known = {for (final n in _items!) n.id};
      setState(() {
        // A notification that arrived meanwhile shifts the pages: skip duplicates.
        _items = [
          ..._items!,
          ...page.items.where((n) => !known.contains(n.id)),
        ];
        _unread = page.unread;
        _page++;
        _lastPage = page.lastPage;
      });
    } on ApiException catch (e) {
      if (mounted) _snack(e.displayMessage);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// Marks it read on screen right away (no reload of the whole inbox), then opens what it is
  /// about.
  Future<void> _open(InboxNotification n) async {
    if (_opening) return;
    _opening = true;
    try {
      if (!n.read) {
        setState(() {
          _items = [for (final i in _items!) i.id == n.id ? i.asRead() : i];
          _unread = (_unread - 1).clamp(0, 1 << 30);
        });
        // Best effort: a failed mark-as-read must not block opening the transaction.
        NotificationApi.markRead(n.id).catchError((_) {});
      }
      if (n.type == 'FOTO_ULANG' && n.formId != null) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PawnPhotoPage(formId: n.formId!, retakeLabels: n.labels),
          ),
        );
        return;
      }
      final number = n.transactionNumber;
      if (number == null) return;
      await ActivityApi.load(); // cached when fresh
      final match =
          [
            ...ActivityRepository.ongoing,
            ...ActivityRepository.history,
          ].where((t) => t.id == number).firstOrNull ??
          await ActivityApi.detail(number);
      if (mounted) await context.push(AppRoutes.activityDetail, extra: match);
    } on ApiException catch (e) {
      if (mounted) _snack(e.displayMessage);
    } finally {
      _opening = false;
    }
  }

  Future<void> _readAll() async {
    try {
      await NotificationApi.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = [for (final i in _items ?? <InboxNotification>[]) i.asRead()];
        _unread = 0;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_unread > 0)
            TextButton(onPressed: _readAll, child: const Text('Tandai dibaca')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_error != null) ...[
              FlowInfo(_error!, warning: true),
              TextButton(onPressed: _load, child: const Text('Coba lagi')),
            ] else if (items == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: Text('Belum ada notifikasi.')),
              )
            else ...[
              for (final n in items)
                _NotificationTile(n, onTap: () => _open(n)),
              if (_page < _lastPage)
                Center(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        )
                      : TextButton(
                          onPressed: _loadMore,
                          child: const Text('Muat lebih banyak'),
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.n, {required this.onTap});
  final InboxNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: n.read ? Colors.white : AppColors.primary.withValues(alpha: .06),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.divider),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                ),
                if (!n.read)
                  const CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(n.body, style: const TextStyle(fontSize: 13, height: 1.5)),
            if (n.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat('d MMM yyyy, HH:mm', 'id').format(n.createdAt!),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
