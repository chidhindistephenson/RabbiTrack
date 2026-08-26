import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/money_format.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import 'sale_controller.dart';
import 'sale_models.dart';

class SaleListScreen extends ConsumerWidget {
  const SaleListScreen({super.key, this.rabbitId});

  final String? rabbitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRabbitProfileView = rabbitId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRabbitProfileView ? 'Rabbit sales' : 'Sales'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          isRabbitProfileView ? '/sales/new?rabbitId=$rabbitId' : '/sales/new',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Sale'),
      ),
      body: SaleListContent(rabbitId: rabbitId),
    );
  }
}

class SaleListContent extends ConsumerWidget {
  const SaleListContent({super.key, this.rabbitId});

  final String? rabbitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRabbitProfileView = rabbitId != null;
    final sales = isRabbitProfileView
        ? ref.watch(rabbitSaleListProvider(rabbitId!))
        : ref.watch(saleListProvider);
    final report = ref.watch(saleReportProvider);

    return sales.when(
      data: (items) {
        return RefreshIndicator(
          onRefresh: () async {
            final refreshedReport = ref.refresh(saleReportProvider.future);
            final refreshedSales = isRabbitProfileView
                ? ref.refresh(rabbitSaleListProvider(rabbitId!).future)
                : ref.refresh(saleListProvider.future);

            await refreshedReport;
            await refreshedSales;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              report.when(
                data: (summary) => _SaleReportHeader(report: summary),
                error: (error, stackTrace) => const SizedBox.shrink(),
                loading: () => const _SaleReportLoading(),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: AppState(
                    icon: Icons.sell_outlined,
                    title: isRabbitProfileView
                        ? 'No sale record for this rabbit'
                        : 'No sales yet',
                    message:
                        'Record completed rabbit sales to keep revenue and buyer history in one place.',
                    actionLabel: 'Add sale',
                    actionIcon: Icons.add,
                    onAction: () => context.push(
                      isRabbitProfileView
                          ? '/sales/new?rabbitId=$rabbitId'
                          : '/sales/new',
                    ),
                    minHeight: 260,
                  ),
                )
              else
                for (final sale in items) ...[
                  _SaleTile(sale: sale),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
      error: (error, stackTrace) => AppState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load sales',
        message: 'Try again. Offline demo data should remain available.',
        actionLabel: 'Retry',
        onAction: () => isRabbitProfileView
            ? ref.invalidate(rabbitSaleListProvider(rabbitId!))
            : ref.invalidate(saleListProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SaleReportHeader extends StatelessWidget {
  const _SaleReportHeader({required this.report});

  final SaleReport report;

  @override
  Widget build(BuildContext context) {
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
                'Total revenue',
                style: TextStyle(
                  color: RabbiTrackColors.mintGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(report.currency, report.totalRevenue),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: RabbiTrackColors.cream,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SaleStatTile(
                label: 'Completed sales',
                value: '${report.saleCount}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SaleStatTile(
                label: 'Average sale',
                value: formatMoney(report.currency, report.averageSale),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SaleStatTile extends StatelessWidget {
  const _SaleStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RabbiTrackColors.forestGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleReportLoading extends StatelessWidget {
  const _SaleReportLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 96,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale});

  final SaleSummary sale;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: Icons.sell_outlined,
      title: sale.rabbitIdentifier ?? 'Rabbit sale',
      subtitle: [
        sale.buyerName,
        sale.buyerPhone,
        sale.soldOn,
      ].whereType<String>().join(' | '),
      trailing: Text(formatMoney(sale.currency, sale.salePrice)),
    );
  }
}
