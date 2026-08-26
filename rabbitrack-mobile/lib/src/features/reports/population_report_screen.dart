import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'population_report_controller.dart';
import 'population_report_models.dart';
import 'population_report_repository.dart';

class PopulationReportScreen extends ConsumerWidget {
  const PopulationReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(populationReportProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/more'),
        title: const Text('Population report'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, ref),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: report.when(
        data: (item) {
          if (item.total == 0) {
            return const AppState(
              icon: Icons.groups_outlined,
              title: 'No active rabbits yet',
              message:
                  'Active rabbit counts will appear here after registration.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(populationReportProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                _PopulationHeader(total: item.total),
                const SizedBox(height: 12),
                _ReportGroup(title: 'Sex', rows: item.bySex, total: item.total),
                const SizedBox(height: 12),
                _ReportGroup(
                  title: 'Status',
                  rows: item.byStatus,
                  total: item.total,
                ),
                const SizedBox(height: 12),
                _ReportGroup(
                  title: 'Breed',
                  rows: item.byBreed,
                  total: item.total,
                ),
                const SizedBox(height: 12),
                _ReportGroup(
                  title: 'Location',
                  rows: item.byLocation,
                  total: item.total,
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Population report unavailable',
          message: 'Try again. Offline demo data should remain available.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(populationReportProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a farm before exporting.')),
      );
      return;
    }

    try {
      final csv = await ref
          .read(populationReportRepositoryProvider)
          .exportCsv(farm.id);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/population-report.csv');
      await file.writeAsString(csv);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Population report saved to ${file.path}')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export population report.')),
      );
    }
  }
}

class _PopulationHeader extends StatelessWidget {
  const _PopulationHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: RabbiTrackColors.warmTan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: RabbiTrackColors.cream,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'active rabbits in the herd',
                  style: TextStyle(
                    color: RabbiTrackColors.mintGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGroup extends StatelessWidget {
  const _ReportGroup({
    required this.title,
    required this.rows,
    required this.total,
  });

  final String title;
  final List<PopulationReportRow> rows;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RabbiTrackColors.mintGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: RabbiTrackColors.forestGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            _ReportRow(row: row, total: total),
            if (row != rows.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.row, required this.total});

  final PopulationReportRow row;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (row.count / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _label(row.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${row.count}',
              style: const TextStyle(
                color: RabbiTrackColors.forestGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio,
            backgroundColor: RabbiTrackColors.cream,
            color: RabbiTrackColors.sageGreen,
          ),
        ),
      ],
    );
  }
}

String _label(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
