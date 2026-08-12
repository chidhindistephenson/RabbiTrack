import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../shared/detail_section.dart';
import '../../theme/rabbitrack_colors.dart';
import 'litter_controller.dart';
import 'litter_models.dart';
import 'litter_options.dart';

class LitterDetailScreen extends ConsumerWidget {
  const LitterDetailScreen({required this.litterId, super.key});

  final String litterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final litter = ref.watch(litterDetailProvider(litterId));

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/litters'),
        title: const Text('Litter profile'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        actions: [
          litter.maybeWhen(
            data: (item) => IconButton(
              tooltip: 'Record weight',
              onPressed: () => context.push('/litters/$litterId/weight'),
              icon: const Icon(Icons.monitor_weight),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          litter.maybeWhen(
            data: (item) => IconButton(
              tooltip: item.status == 'weaned'
                  ? 'Litter already weaned'
                  : 'Record weaning',
              onPressed: item.status == 'weaned'
                  ? null
                  : () => context.push('/litters/$litterId/weaning'),
              icon: const Icon(Icons.check_circle_outline),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: litter.when(
        data: (item) => RefreshIndicator(
          onRefresh: () => ref.refresh(litterDetailProvider(litterId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Header(litter: item),
              const SizedBox(height: 12),
              DetailSection(
                title: 'Kindling',
                children: [
                  DetailInfoRow('Kindled', item.kindledOn),
                  DetailInfoRow('Born alive', '${item.kitsBornAlive}'),
                  DetailInfoRow('Stillborn', '${item.kitsStillborn}'),
                  DetailInfoRow('Weak kits', '${item.kitsWeak}'),
                  DetailInfoRow('Current live', '${item.currentLiveCount}'),
                  DetailInfoRow('Planned weaning', item.plannedWeaningOn),
                ],
              ),
              const SizedBox(height: 12),
              _WeaningsSection(weanings: item.weanings),
              const SizedBox(height: 12),
              _WeightsSection(weights: item.weights),
            ],
          ),
        ),
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load litter profile',
          message: 'Check that the API server is running, then try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(litterDetailProvider(litterId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.litter});

  final LitterDetail litter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            litter.identifier,
            style: textTheme.titleLarge?.copyWith(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${litter.doeIdentifier}${litter.buckIdentifier == null ? '' : ' x ${litter.buckIdentifier}'} | ${litterStatusLabel(litter.status)}',
            style: textTheme.bodyMedium?.copyWith(
              color: RabbiTrackColors.mintGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeaningsSection extends StatelessWidget {
  const _WeaningsSection({required this.weanings});

  final List<LitterWeaningSummary> weanings;

  @override
  Widget build(BuildContext context) {
    if (weanings.isEmpty) {
      return const DetailSection(
        title: 'Weaning',
        children: [DetailInfoRow('Status', 'Not weaned yet')],
      );
    }

    return DetailSection(
      title: 'Weaning',
      children: [
        for (final weaning in weanings)
          DetailInfoRow(
            weaning.weanedOn ?? 'Weaning',
            '${weaning.numberWeaned} weaned | ${weaning.averageWeightValue ?? '-'} ${weaning.weightUnit ?? 'kg'} | ${weaning.destination ?? '-'}',
          ),
      ],
    );
  }
}

class _WeightsSection extends StatelessWidget {
  const _WeightsSection({required this.weights});

  final List<LitterWeightSummary> weights;

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return const DetailSection(
        title: 'Weights',
        children: [DetailInfoRow('Latest', 'No litter weights recorded')],
      );
    }

    return DetailSection(
      title: 'Weights',
      children: [
        for (final weight in weights.take(5))
          DetailInfoRow(
            weight.weighedOn ?? 'Weight',
            '${weight.weightValue} ${weight.weightUnit}',
          ),
      ],
    );
  }
}
