import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import 'weight_controller.dart';
import 'weight_list_options.dart';
import 'weight_models.dart';

class WeightListScreen extends ConsumerWidget {
  const WeightListScreen({super.key, this.rabbitId});

  final String? rabbitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRabbitProfileView = rabbitId != null;
    final weights = isRabbitProfileView
        ? ref.watch(rabbitWeightListProvider(rabbitId!))
        : ref.watch(weightListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRabbitProfileView ? 'Rabbit weights' : 'Weights'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          isRabbitProfileView
              ? '/weights/new?rabbitId=$rabbitId'
              : '/weights/new',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Weight'),
      ),
      body: weights.when(
        data: (items) {
          if (items.isEmpty) {
            return AppState(
              icon: Icons.monitor_weight,
              title: isRabbitProfileView
                  ? 'No weights for this rabbit'
                  : 'No weights yet',
              message:
                  'Record rabbit or litter weights to track growth and compare progress over time.',
              actionLabel: 'Record weight',
              actionIcon: Icons.add,
              onAction: () => context.push(
                isRabbitProfileView
                    ? '/weights/new?rabbitId=$rabbitId'
                    : '/weights/new',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => isRabbitProfileView
                ? ref.refresh(rabbitWeightListProvider(rabbitId!).future)
                : ref.refresh(weightListProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WeightSummaryCard(weights: items),
                const SizedBox(height: 12),
                for (final weight in items) ...[
                  _WeightTile(weight: weight),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load weights',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => isRabbitProfileView
              ? ref.invalidate(rabbitWeightListProvider(rabbitId!))
              : ref.invalidate(weightListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _WeightSummaryCard extends StatelessWidget {
  const _WeightSummaryCard({required this.weights});

  final List<WeightSummary> weights;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_weight, color: RabbiTrackColors.warmTan),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryMetric(
              label: 'Records',
              value: weightListCountText(weights.length),
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: 'Latest',
              value: latestWeightValue(weights),
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: 'Date',
              value: latestWeightDate(weights),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RabbiTrackColors.mintGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: RabbiTrackColors.cream,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WeightTile extends StatelessWidget {
  const _WeightTile({required this.weight});

  final WeightSummary weight;

  @override
  Widget build(BuildContext context) {
    final target =
        weight.rabbitIdentifier ?? weight.litterIdentifier ?? 'Record';
    final targetType = weightRecordTargetType(weight);
    final method = weight.method == null ? '' : ' | ${weight.method}';

    return SoftListTile(
      icon: Icons.monitor_weight,
      title: target,
      subtitle: '$targetType | ${weight.weighedOn}$method',
      trailing: Text(weightRecordValueText(weight), textAlign: TextAlign.end),
    );
  }
}
