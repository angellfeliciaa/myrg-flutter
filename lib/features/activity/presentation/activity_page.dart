import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../home/presentation/widgets/home_bottom_navigation.dart';
import '../data/activity_repository.dart';
import '../models/activity_transaction.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/backend_config.dart';
import '../data/activity_api.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ActivityApi.ongoing.addListener(_onData);
    ActivityApi.history.addListener(_onData);
    ActivityApi.loadError.addListener(_onData);
    ActivityApi.load().catchError((Object e) => _showError(e));
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : 'Data belum bisa dimuat. Coba lagi.',
          ),
        ),
      );
  }

  int _tabIndex = 0;
  String _category = 'Semua';
  String _status = 'Semua';
  DateTimeRange? _dateRange;

  static const _categories = [
    'Semua',
    'Gadai',
    'Pembayaran',
    'Pencairan',
    'Top Up',
  ];

  @override
  void dispose() {
    ActivityApi.ongoing.removeListener(_onData);
    ActivityApi.history.removeListener(_onData);
    ActivityApi.loadError.removeListener(_onData);
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityTransaction> get _visibleTransactions {
    final source = _tabIndex == 0
        ? ActivityRepository.ongoing
        : ActivityRepository.history;
    final query = _searchController.text.trim().toLowerCase();

    return source.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.reference.toLowerCase().contains(query);
      final matchesCategory =
          _category == 'Semua' || _labelForType(item.type) == _category;
      final matchesStatus =
          _status == 'Semua' || _labelForStatus(item.status) == _status;
      final date = DateTime.tryParse(item.dateIso ?? '');
      final matchesDate =
          _dateRange == null ||
          (date != null &&
              !date.isBefore(_dateRange!.start) &&
              !date.isAfter(_dateRange!.end));
      return matchesQuery && matchesCategory && matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> _showFilter() async {
    final result =
        await showModalBottomSheet<
          ({String type, String status, DateTimeRange? range})
        >(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _ActivityFilterSheet(
            selectedType: _category,
            selectedStatus: _status,
            selectedRange: _dateRange,
          ),
        );

    if (result != null && mounted) {
      setState(() {
        _category = result.type;
        _status = result.status;
        _dateRange = result.range;
      });
    }
  }

  void _openDetail(ActivityTransaction transaction) {
    context.push(AppRoutes.activityDetail, extra: transaction);
  }

  void _handleNavigation(String item) {
    if (item == 'Home') {
      context.go(AppRoutes.home);
      return;
    }
    if (item == 'Aktivitas') return;
    if (item == 'Akun') {
      context.go(AppRoutes.account);
      return;
    }
    if (item == 'Gadai Online') {
      context.push(AppRoutes.pawn);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$item akan segera tersedia.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 86),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFAFC),
        bottomNavigationBar: HomeBottomNavigation(
          selectedItem: 'Aktivitas',
          onItemTap: _handleNavigation,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              _buildCategoryFilters(),
              _buildSearch(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktivitas',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pantau semua transaksi kamu di satu tempat',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Unduh riwayat transaksi',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Laporan transaksi sedang disiapkan.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primarySoft,
            ),
            icon: const Icon(Icons.download_rounded, size: 21),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(2, (index) {
          final selected = _tabIndex == index;
          final label = index == 0 ? 'Berjalan' : 'Riwayat';
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() {
                _tabIndex = index;
                _status = 'Semua';
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.only(top: 10, bottom: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.secondary : AppColors.divider,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _categories[index];
          final selected = label == _category;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _category = label),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            backgroundColor: Colors.white,
            selectedColor: AppColors.primary,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    final hasActiveFilter = _status != 'Semua' || _dateRange != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari transaksi atau barang',
                hintStyle: const TextStyle(
                  color: Color(0xFF9A969E),
                  fontSize: 12,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 21),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Badge(
            isLabelVisible: hasActiveFilter,
            smallSize: 8,
            backgroundColor: AppColors.secondary,
            child: IconButton.outlined(
              tooltip: 'Filter aktivitas',
              onPressed: _showFilter,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primarySoft.withValues(alpha: 0.5),
                side: const BorderSide(color: Color(0xFFD9C7E8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (ActivityRepository.loading) {
      // Backend mode, first load still running or failed.
      if (ActivityApi.loadError.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Transaksi belum bisa dimuat.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ActivityApi.load(
                  force: true,
                ).catchError((Object e) => _showError(e)),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    final transactions = _visibleTransactions;
    if (transactions.isEmpty) {
      return _EmptyActivity(
        onReset: () {
          _searchController.clear();
          setState(() {
            _category = 'Semua';
            _status = 'Semua';
            _dateRange = null;
          });
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        if (!BackendConfig.enabled) {
          await Future<void>.delayed(const Duration(milliseconds: 650));
          return;
        }
        try {
          await ActivityApi.refreshFromRg();
        } catch (e) {
          _showError(e);
        }
      },
      child: _tabIndex == 0
          ? _OngoingList(transactions: transactions, onOpen: _openDetail)
          : _HistoryList(transactions: transactions, onOpen: _openDetail),
    );
  }
}

class _OngoingList extends StatelessWidget {
  const _OngoingList({required this.transactions, required this.onOpen});

  final List<ActivityTransaction> transactions;
  final ValueChanged<ActivityTransaction> onOpen;

  @override
  Widget build(BuildContext context) {
    final attention = transactions
        .where(
          (item) =>
              item.status == ActivityStatus.needsAttention ||
              item.status == ActivityStatus.probation,
        )
        .toList();
    final processing = transactions
        .where((item) => item.status == ActivityStatus.processing)
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 42),
      children: [
        if (attention.isNotEmpty) ...[
          const _SectionTitle(
            title: 'Perlu Perhatian',
            subtitle: 'Selesaikan sebelum melewati tenggat',
          ),
          const SizedBox(height: 12),
          ...attention.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: _AttentionCard(
                transaction: item,
                onTap: () => onOpen(item),
              ),
            ),
          ),
        ],
        if (processing.isNotEmpty) ...[
          const _SectionTitle(
            title: 'Sedang Diproses',
            subtitle: 'Status mengikuti pembaruan dari Raja Gadai',
          ),
          const SizedBox(height: 4),
          ...processing.map(
            (item) =>
                _ActivityTile(transaction: item, onTap: () => onOpen(item)),
          ),
        ],
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.transactions, required this.onOpen});

  final List<ActivityTransaction> transactions;
  final ValueChanged<ActivityTransaction> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 42),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final item = transactions[index];
        String monthFor(ActivityTransaction transaction) {
          final date = DateTime.tryParse(transaction.dateIso ?? '');
          return date == null
              ? 'Riwayat transaksi'
              : DateFormat('MMMM yyyy', 'id').format(date);
        }

        final showMonth =
            index == 0 || monthFor(item) != monthFor(transactions[index - 1]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMonth) ...[
              if (index > 0) const SizedBox(height: 16),
              _SectionTitle(
                title: monthFor(item),
                subtitle: index == 0 ? 'Aktivitas terbaru kamu' : null,
              ),
              const SizedBox(height: 4),
            ],
            _ActivityTile(transaction: item, onTap: () => onOpen(item)),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.transaction, required this.onTap});

  final ActivityTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF2CCCC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F401A59),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFFD64B50),
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        transaction.attentionLabel ?? 'Perlu perhatian',
                        style: const TextStyle(
                          color: Color(0xFFD64B50),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 74,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Image.asset(
                            AppAssets.activityIphone,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                transaction.subtitle ?? '',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const _StatusDot(color: Color(0xFFD95055)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Jatuh tempo',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    height: 12,
                                    width: 1,
                                    color: AppColors.divider,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      transaction.dueDate ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFFD95055),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nominal Pembayaran',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                transaction.amount,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(84, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            transaction.status == ActivityStatus.probation
                                ? 'Hubungi CS'
                                : 'Bayar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.transaction, required this.onTap});
  final ActivityTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final success = transaction.status == ActivityStatus.success;
    final accent = _colorForType(transaction.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconForType(transaction.type), color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No. ${transaction.reference}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          _labelForStatus(transaction.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: success
                                ? AppColors.success
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          transaction.dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (success) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${transaction.isIncome ? '+' : '−'} ${transaction.amount}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primary,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Aktivitas tidak ditemukan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        const Text(
          'Coba ubah kata pencarian atau atur ulang filter yang aktif.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: onReset,
            child: const Text('Reset filter'),
          ),
        ),
      ],
    );
  }
}

class _ActivityFilterSheet extends StatefulWidget {
  const _ActivityFilterSheet({
    required this.selectedType,
    required this.selectedStatus,
    required this.selectedRange,
  });

  final String selectedType;
  final String selectedStatus;
  final DateTimeRange? selectedRange;

  @override
  State<_ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<_ActivityFilterSheet> {
  late String _type = widget.selectedType;
  late String _status = widget.selectedStatus;
  late DateTimeRange? _range = widget.selectedRange;
  static const _types = ['Semua', 'Gadai', 'Pembayaran', 'Top Up', 'Pencairan'];
  static const _statuses = [
    'Semua',
    'Berhasil',
    'Diproses',
    'Gagal',
    'Probation',
  ];

  Future<void> _pickRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      helpText: 'Pilih rentang tanggal',
      saveText: 'Simpan',
    );
    if (selected != null && mounted) setState(() => _range = selected);
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      24,
      14,
      24,
      20 + MediaQuery.viewPaddingOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D3DB),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filter aktivitas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Rentang tanggal',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              _range == null
                  ? 'Semua tanggal'
                  : '${DateFormat('d MMM yyyy', 'id').format(_range!.start)} – ${DateFormat('d MMM yyyy', 'id').format(_range!.end)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 22),
          _FilterGroup(
            title: 'Jenis aktivitas',
            options: _types,
            selected: _type,
            onSelected: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 20),
          _FilterGroup(
            title: 'Status',
            options: _statuses,
            selected: _status,
            onSelected: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, (
                type: _type,
                status: _status,
                range: _range,
              )),
              child: const Text(
                'Terapkan Filter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _type = 'Semua';
                _status = 'Semua';
                _range = null;
              }),
              child: const Text('Reset'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 9,
          children: options.map((option) {
            final active = option == selected;
            return ChoiceChip(
              label: Text(option),
              selected: active,
              onSelected: (_) => onSelected(option),
              showCheckmark: false,
              selectedColor: AppColors.secondary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: active ? AppColors.secondary : AppColors.divider,
              ),
              labelStyle: TextStyle(
                color: active
                    ? const Color(0xFF294400)
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: const StadiumBorder(),
            );
          }).toList(),
        ),
      ],
    );
  }
}

String _labelForType(ActivityType type) => switch (type) {
  ActivityType.pawn => 'Gadai',
  ActivityType.payment => 'Pembayaran',
  ActivityType.disbursement => 'Pencairan',
  ActivityType.topUp => 'Top Up',
};

String _labelForStatus(ActivityStatus status) => switch (status) {
  ActivityStatus.needsAttention => 'Jatuh Tempo',
  ActivityStatus.processing => 'Diproses',
  ActivityStatus.success => 'Berhasil',
  ActivityStatus.failed => 'Gagal',
  ActivityStatus.probation => 'Probation',
};

IconData _iconForType(ActivityType type) => switch (type) {
  ActivityType.pawn => Icons.phone_android_rounded,
  ActivityType.payment => Icons.account_balance_wallet_outlined,
  ActivityType.disbursement => Icons.south_west_rounded,
  ActivityType.topUp => Icons.savings_outlined,
};

Color _colorForType(ActivityType type) => switch (type) {
  ActivityType.pawn => AppColors.primary,
  ActivityType.payment => const Color(0xFF72AF37),
  ActivityType.disbursement => const Color(0xFF4A9A72),
  ActivityType.topUp => const Color(0xFF7B45B0),
};
