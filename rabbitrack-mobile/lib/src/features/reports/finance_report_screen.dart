import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/money_format.dart';
import '../../theme/rabbitrack_colors.dart';
import '../expenses/expense_list_screen.dart';
import '../sales/sale_list_screen.dart';
import 'finance_report_controller.dart';
import 'finance_report_models.dart';
import 'finance_report_options.dart';

class FinanceReportScreen extends ConsumerStatefulWidget {
  const FinanceReportScreen({super.key});

  @override
  ConsumerState<FinanceReportScreen> createState() =>
      _FinanceReportScreenState();
}

class _FinanceReportScreenState extends ConsumerState<FinanceReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance report'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        bottom: TabBar(
          controller: _tabController,
          labelColor: RabbiTrackColors.cream,
          unselectedLabelColor: RabbiTrackColors.mintGreen,
          indicatorColor: RabbiTrackColors.warmTan,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      floatingActionButton: switch (_tabController.index) {
        1 => FloatingActionButton.extended(
          onPressed: () => context.push('/sales/new'),
          icon: const Icon(Icons.add),
          label: const Text('Sale'),
        ),
        2 => FloatingActionButton.extended(
          onPressed: () => context.push('/expenses/new'),
          icon: const Icon(Icons.add),
          label: const Text('Expense'),
        ),
        _ => null,
      },
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FinanceOverviewTab(),
          SaleListContent(),
          ExpenseListContent(),
        ],
      ),
    );
  }
}

class _FinanceOverviewTab extends ConsumerWidget {
  const _FinanceOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(monthlyFinanceReportProvider);

    return report.when(
      data: (item) => RefreshIndicator(
        onRefresh: () async {
          final refreshed = ref.refresh(monthlyFinanceReportProvider.future);
          await refreshed;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            _FinanceReportHeader(report: item),
            const SizedBox(height: 14),
            if (item.months.isEmpty)
              const AppState(
                icon: Icons.bar_chart,
                title: 'No finance history yet',
                message:
                    'Sales and expenses will build the monthly report automatically.',
                minHeight: 260,
              )
            else
              for (final month in item.months) ...[
                _FinanceMonthTile(currency: item.currency, month: month),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
      error: (error, stackTrace) => AppState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load report',
        message: 'Check the API server and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(monthlyFinanceReportProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FinanceReportHeader extends StatelessWidget {
  const _FinanceReportHeader({required this.report});

  final MonthlyFinanceReport report;

  @override
  Widget build(BuildContext context) {
    final totals = financeTotals(report.months);
    final netColor = totals.net < 0
        ? Colors.red.shade200
        : RabbiTrackColors.cream;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 6 months',
            style: TextStyle(
              color: RabbiTrackColors.mintGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(report.currency, totals.net.toStringAsFixed(2)),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: netColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${financeResultLabel(totals.net)} | Margin ${totals.margin.toStringAsFixed(1)}%',
            style: const TextStyle(color: RabbiTrackColors.cream),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                'Revenue ${formatMoney(report.currency, totals.revenue.toStringAsFixed(2))}',
                style: const TextStyle(color: RabbiTrackColors.cream),
              ),
              Text(
                'Expenses ${formatMoney(report.currency, totals.expenses.toStringAsFixed(2))}',
                style: const TextStyle(color: RabbiTrackColors.cream),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceMonthTile extends StatelessWidget {
  const _FinanceMonthTile({required this.currency, required this.month});

  final String currency;
  final MonthlyFinanceRow month;

  @override
  Widget build(BuildContext context) {
    final net = financeAmount(month.netIncome);
    final revenue = financeAmount(month.revenue);
    final expenses = financeAmount(month.expenses);
    final maxValue = [
      revenue,
      expenses,
      net.abs(),
    ].fold<double>(0, (max, value) => value > max ? value : max);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  month.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                formatMoney(currency, month.netIncome),
                style: TextStyle(
                  color: net < 0
                      ? Colors.red.shade700
                      : RabbiTrackColors.forestGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FinanceLine(
            label: 'Revenue',
            value: formatMoney(currency, month.revenue),
            ratio: financeBarRatio(month.revenue, maxValue),
            color: RabbiTrackColors.forestGreen,
          ),
          const SizedBox(height: 6),
          _FinanceLine(
            label: 'Expenses',
            value: formatMoney(currency, month.expenses),
            ratio: financeBarRatio(month.expenses, maxValue),
            color: RabbiTrackColors.warmTan,
          ),
        ],
      ),
    );
  }
}

class _FinanceLine extends StatelessWidget {
  const _FinanceLine({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: ratio,
            backgroundColor: RabbiTrackColors.mintGreen.withValues(alpha: 0.3),
            color: color,
          ),
        ),
      ],
    );
  }
}
