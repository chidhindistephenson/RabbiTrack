import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/money_format.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import 'expense_controller.dart';
import 'expense_models.dart';
import 'expense_options.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Expense'),
      ),
      body: const ExpenseListContent(),
    );
  }
}

class ExpenseListContent extends ConsumerWidget {
  const ExpenseListContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);
    final report = ref.watch(expenseReportProvider);

    return expenses.when(
      data: (items) {
        return RefreshIndicator(
          onRefresh: () async {
            final refreshedReport = ref.refresh(expenseReportProvider.future);
            final refreshedExpenses = ref.refresh(expenseListProvider.future);

            await refreshedReport;
            await refreshedExpenses;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              report.when(
                data: (summary) => _ExpenseReportHeader(report: summary),
                error: (error, stackTrace) => const SizedBox.shrink(),
                loading: () => const _ExpenseReportLoading(),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: AppState(
                    icon: Icons.payments_outlined,
                    title: 'No expenses yet',
                    message:
                        'Track feed, medicine, housing, labor, and other costs as they happen.',
                    actionLabel: 'Add expense',
                    actionIcon: Icons.add,
                    onAction: () => context.push('/expenses/new'),
                    minHeight: 260,
                  ),
                )
              else
                for (final expense in items) ...[
                  _ExpenseTile(expense: expense),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
      error: (error, stackTrace) => AppState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load expenses',
        message: 'Try again. Offline demo data should remain available.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(expenseListProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ExpenseReportHeader extends StatelessWidget {
  const _ExpenseReportHeader({required this.report});

  final ExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final topCategories = report.byCategory.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RabbiTrackColors.forestGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total expenses',
                style: TextStyle(
                  color: RabbiTrackColors.mintGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(report.currency, report.total),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: RabbiTrackColors.cream,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (topCategories.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final category in topCategories)
            _ExpenseCategoryBar(
              category: category,
              currency: report.currency,
              maxTotal: _maxCategoryTotal(topCategories),
            ),
        ],
      ],
    );
  }

  double _maxCategoryTotal(List<ExpenseCategoryTotal> categories) {
    return categories
        .map((category) => double.tryParse(category.total) ?? 0)
        .fold<double>(0, (max, value) => value > max ? value : max);
  }
}

class _ExpenseCategoryBar extends StatelessWidget {
  const _ExpenseCategoryBar({
    required this.category,
    required this.currency,
    required this.maxTotal,
  });

  final ExpenseCategoryTotal category;
  final String currency;
  final double maxTotal;

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(category.total) ?? 0;
    final progress = maxTotal <= 0 ? 0.0 : total / maxTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
                  _categoryLabel(category.category),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                formatMoney(currency, category.total),
                style: const TextStyle(
                  color: RabbiTrackColors.forestGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: RabbiTrackColors.mintGreen.withValues(
                alpha: 0.35,
              ),
              color: RabbiTrackColors.warmTan,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${category.count} record${category.count == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ExpenseReportLoading extends StatelessWidget {
  const _ExpenseReportLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 96,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final ExpenseSummary expense;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: Icons.payments_outlined,
      title: expenseCategoryLabel(expense.category),
      subtitle: [
        expense.vendor,
        expense.spentOn,
      ].whereType<String>().join(' | '),
      trailing: Text(formatMoney(expense.currency, expense.amount)),
    );
  }
}

String _categoryLabel(String category) {
  return expenseCategoryLabel(category);
}
