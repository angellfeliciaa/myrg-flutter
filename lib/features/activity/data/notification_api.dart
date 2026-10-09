import '../../../core/network/myrg_api.dart';

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.createdAt,
    this.transactionNumber,
    this.formId,
    this.labels = const [],
  });

  factory InboxNotification.fromApi(Map<String, dynamic> json) {
    final data = json['data'];
    return InboxNotification(
      id: (json['id'] as num).toInt(),
      type: '${json['type'] ?? 'INFO'}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      read: json['read'] == true,
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      transactionNumber: data is Map
          ? data['transactionNumber'] as String?
          : null,
      formId: data is Map ? data['formId'] as String? : null,
      labels: data is Map && data['labels'] is List
          ? [for (final l in data['labels'] as List) '$l']
          : const [],
    );
  }

  final int id;
  final String type, title, body;
  final bool read;
  final DateTime? createdAt;

  /// Set on transaction notifications (gadai baru, perpanjangan, pelunasan, jatuh tempo).
  final String? transactionNumber;

  /// FOTO_ULANG (Gadai Online): the submission and the sides to shoot again.
  final String? formId;
  final List<String> labels;

  InboxNotification asRead() => InboxNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    read: true,
    createdAt: createdAt,
    transactionNumber: transactionNumber,
    formId: formId,
    labels: labels,
  );
}

/// One page of the inbox.
typedef InboxPage = ({List<InboxNotification> items, int unread, int lastPage});

/// The member's inbox at MyRG (GET /notifications). Pushes need Firebase, which is not in the
/// app yet; the inbox works without it.
class NotificationApi {
  const NotificationApi._();

  /// Newest first, 20 per page; meta.unread is for the whole inbox.
  static Future<InboxPage> inbox({int page = 1}) async {
    final data =
        await MyrgApi.get('/notifications', query: {'page': page})
            as Map<String, dynamic>;
    final items = [
      for (final n in data['items'] as List? ?? const [])
        if (n is Map) InboxNotification.fromApi(Map<String, dynamic>.from(n)),
    ];
    final meta = data['meta'];
    int read(String key, int fallback) =>
        meta is Map ? (meta[key] as num? ?? fallback).toInt() : fallback;
    return (
      items: items,
      unread: read('unread', 0),
      lastPage: read('lastPage', 1),
    );
  }

  static Future<void> markRead(int id) =>
      MyrgApi.post('/notifications/$id/read');

  static Future<void> markAllRead() => MyrgApi.post('/notifications/read-all');
}
