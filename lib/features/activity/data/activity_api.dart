import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../core/network/backend_config.dart';
import '../../../core/network/myrg_api.dart';
import '../models/activity_transaction.dart';

/// Ongoing pawns and history from the backend (GET /transactions). In demo mode the lists stay
/// the fixtures from [ActivityRepository].
abstract final class ActivityApi {
  static final ongoing = ValueNotifier<List<ActivityTransaction>?>(null);
  static final history = ValueNotifier<List<ActivityTransaction>?>(null);

  /// Last load failed (lists still null): pages show "coba lagi" instead of a spinner.
  static final loadError = ValueNotifier<Object?>(null);

  static Future<void>? _loading;
  static DateTime? _loadedAt;

  /// Bumped by every new load and by [clear]: an older answer that arrives late (e.g. the
  /// previous member's, after logout) is dropped instead of overwriting newer data.
  static int _generation = 0;

  /// Data younger than this is shown as is when a page opens (pull to refresh forces a reload).
  static const fresh = Duration(seconds: 30);

  /// Loads both lists. Pages opening at the same time share one request; [force] skips the
  /// freshness check and does not reuse a request that started earlier (pull to refresh,
  /// after a payment).
  static Future<void> load({bool force = false}) {
    if (!BackendConfig.enabled) return Future.value();
    final loadedAt = _loadedAt;
    if (!force &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < fresh) {
      return Future.value();
    }
    final running = _loading;
    if (!force && running != null) return running;

    final generation = ++_generation;
    late final Future<void> request;
    request = _load(generation).whenComplete(() {
      if (identical(_loading, request)) _loading = null;
    });
    _loading = request;
    return request;
  }

  static Future<void> _load(int generation) async {
    try {
      final results = await Future.wait([_list('active'), _list('history')]);
      if (generation != _generation) return; // a newer load or a logout won
      ongoing.value = results[0];
      history.value = results[1];
      loadError.value = null;
      _loadedAt = DateTime.now();
    } catch (e) {
      if (generation == _generation) loadError.value = e;
      rethrow;
    }
  }

  /// Logout / another account: nothing of the previous member stays on screen.
  static void clear() {
    _generation++;
    _loading = null;
    _loadedAt = null;
    ongoing.value = null;
    history.value = null;
    loadError.value = null;
  }

  /// Pull-to-refresh: re-reads the member's transactions from Raja Gadai (max once per 2 minutes).
  static Future<void> refreshFromRg() async {
    await MyrgApi.post('/transactions/refresh');
    await load(force: true);
  }

  /// The backend pages the list; read every page (50 per page, at most 10 pages) so Riwayat is
  /// not cut off at the first page.
  static Future<List<ActivityTransaction>> _list(String filter) async {
    final items = <ActivityTransaction>[];
    var page = 1;
    var lastPage = 1;
    do {
      final data =
          await MyrgApi.get(
                '/transactions',
                query: {'filter': filter, 'page': page, 'perPage': 50},
              )
              as Map;
      for (final item in data['items'] as List) {
        items.add(fromApi(Map<String, dynamic>.from(item as Map)));
      }
      final meta = data['meta'];
      lastPage = meta is Map ? (meta['lastPage'] as num? ?? 1).toInt() : 1;
      page++;
    } while (page <= lastPage && page <= 10);
    return items;
  }

  /// Detail gadai (GET /transactions/{no}): the list item plus the extension/redeem history.
  static Future<ActivityTransaction> detail(String transactionNumber) async {
    final data = await MyrgApi.get(
      '/transactions/${Uri.encodeComponent(transactionNumber)}',
    );
    return fromApi(Map<String, dynamic>.from(data as Map));
  }

  static String? _dateLabel(Object? ymd) {
    final date = DateTime.tryParse('${ymd ?? ''}');
    return date == null ? null : DateFormat('d MMMM y', 'id').format(date);
  }

  /// "Warna: Hitam, Storage: 128GB, IMEI: 3569..., Kondisi: Baik" -> one value.
  static String? _attribute(Object? attributes, String key) {
    final match = RegExp(
      '$key'
      r'\s*:\s*([^,]+)',
      caseSensitive: false,
    ).firstMatch('${attributes ?? ''}');
    return match?.group(1)?.trim();
  }

  static String _paymentLabel(Object? type) =>
      switch ('${type ?? ''}'.toUpperCase()) {
        'TRANSFER' || 'VA' || 'VIRTUAL_ACCOUNT' => 'Transfer / Virtual Account',
        'CASH' || 'TUNAI' => 'Tunai di cabang',
        '' => '-',
        final other => other,
      };

  /// One item of GET /transactions (or the detail, which adds `summary`) -> the app's model
  /// (docs/integrasi-flutter.md, section 5).
  static ActivityTransaction fromApi(Map<String, dynamic> t) {
    final item = (t['item'] is Map)
        ? Map<String, dynamic>.from(t['item'] as Map)
        : const <String, dynamic>{};
    final summary = (t['summary'] is Map)
        ? Map<String, dynamic>.from(t['summary'] as Map)
        : null;
    final number = '${t['transactionNumber']}';
    final extensions = [
      for (final (i, e)
          in (summary?['extensions'] as List? ?? const []).indexed)
        if (e is Map)
          PawnEvent(
            'Perpanjangan ke-${i + 1}',
            [
              _dateLabel(e['date']) ?? '-',
              if (e['paidAmount'] is num)
                'Rp ${NumberFormat.decimalPattern('id').format(e['paidAmount'])}',
            ].join(' • '),
            reference: e['nextDueDate'] == null
                ? null
                : 'Jatuh tempo baru ${_dateLabel(e['nextDueDate'])}',
          ),
    ];

    return ActivityTransaction(
      id: number,
      reference: '#$number',
      title: (item['itemName'] as String?) ?? 'Barang gadai',
      subtitle: item['itemType'] as String?,
      type: ActivityType.pawn,
      status:
          ActivityStatus.values.asNameMap()[t['activityStatus']] ??
          ActivityStatus.processing,
      dateLabel: (t['dateLabel'] as String?) ?? '',
      dateIso: t['pawnDate'] as String?,
      dueDate: t['dueDateLabel'] as String?,
      attentionLabel: t['attentionLabel'] as String?,
      amount: (t['amountLabel'] as String?) ?? '',
      pawn: PawnDetails(
        startedAt: (t['dateLabel'] as String?) ?? '',
        tenor: '-',
        principal: ((t['loanAmount'] ?? t['amount']) as num?)?.toInt() ?? 0,
        totalPayable: (t['debt'] as num?)?.toInt(),
        branchName: (t['location'] as String?) ?? '',
        imei: _attribute(item['itemAttribute'], 'IMEI'),
        condition: _attribute(item['itemAttribute'], 'Kondisi'),
        extensionEvents: extensions,
        redeemedAt: _dateLabel(summary?['redeemedAt']),
        redemptionMethod: summary?['redeemPaymentType'] == null
            ? null
            : _paymentLabel(summary!['redeemPaymentType']),
      ),
    );
  }
}
