import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../data/activity_api.dart';
import '../models/activity_transaction.dart';
import 'activity_detail_page.dart';

/// Opens the detail with what the list already has, then (backend mode) swaps in the full
/// detail from GET /transactions/{no}: extension history, redeem date and method.
class ActivityDetailRoute extends StatefulWidget {
  const ActivityDetailRoute({required this.transaction, super.key});
  final ActivityTransaction transaction;
  @override
  State<ActivityDetailRoute> createState() => _ActivityDetailRouteState();
}

class _ActivityDetailRouteState extends State<ActivityDetailRoute> {
  late ActivityTransaction _transaction = widget.transaction;

  @override
  void initState() {
    super.initState();
    if (BackendConfig.enabled && widget.transaction.type == ActivityType.pawn) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await ActivityApi.detail(widget.transaction.id);
      if (mounted) setState(() => _transaction = detail);
    } on ApiException catch (_) {
      // The list data is still shown; the history appears on the next open.
    }
  }

  @override
  Widget build(BuildContext context) =>
      ActivityDetailPage(transaction: _transaction);
}
