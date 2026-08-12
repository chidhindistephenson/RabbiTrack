import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/detail_section.dart';
import '../../shared/app_state.dart';
import '../../theme/rabbitrack_colors.dart';
import 'breeding_options.dart';
import 'mating_controller.dart';
import 'mating_models.dart';

class MatingDetailScreen extends ConsumerWidget {
  const MatingDetailScreen({required this.matingId, super.key});

  final String matingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mating = ref.watch(matingDetailProvider(matingId));
    final currentMating = mating.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/breeding'),
        title: const Text('Breeding record'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        actions: currentMating == null
            ? null
            : [
                if (isPregnancyCheckDue(
                  status: currentMating.status,
                  dueOn: currentMating.pregnancyCheckDueOn,
                ))
                  IconButton(
                    tooltip: 'Pregnancy check',
                    onPressed: () =>
                        context.push('/breeding/$matingId/pregnancy-check'),
                    icon: const Icon(Icons.fact_check_outlined),
                  ),
                if (canRecordKindling(currentMating.status))
                  IconButton(
                    tooltip: 'Record kindling',
                    onPressed: () =>
                        context.push('/litters/new?matingId=$matingId'),
                    icon: const Icon(Icons.child_care_outlined),
                  ),
              ],
      ),
      body: mating.when(
        data: (item) => RefreshIndicator(
          onRefresh: () => ref.refresh(matingDetailProvider(matingId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Header(mating: item),
              const SizedBox(height: 12),
              DetailSection(
                title: 'Timeline',
                children: [
                  DetailInfoRow('Mated', item.matedAt ?? '-', labelWidth: 130),
                  DetailInfoRow(
                    'Pregnancy check',
                    item.pregnancyCheckDueOn,
                    labelWidth: 130,
                  ),
                  DetailInfoRow(
                    'Nest box',
                    item.nestBoxDueOn ?? '-',
                    labelWidth: 130,
                  ),
                  DetailInfoRow(
                    'Expected kindling',
                    item.expectedKindlingOn,
                    labelWidth: 130,
                  ),
                  DetailInfoRow(
                    'Outcome',
                    matingOutcomeLabel(item.outcome),
                    labelWidth: 130,
                  ),
                  DetailInfoRow(
                    'Behavior',
                    item.behaviorObserved ?? '-',
                    labelWidth: 130,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PregnancyChecksSection(checks: item.pregnancyChecks),
              const SizedBox(height: 12),
              _BreedingActions(mating: item),
              const SizedBox(height: 12),
              _LittersSection(litters: item.litters),
            ],
          ),
        ),
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load breeding record',
          message: 'Check that the API server is running, then try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(matingDetailProvider(matingId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _BreedingActions extends StatelessWidget {
  const _BreedingActions({required this.mating});

  final MatingDetail mating;

  @override
  Widget build(BuildContext context) {
    final canCheck = isPregnancyCheckDue(
      status: mating.status,
      dueOn: mating.pregnancyCheckDueOn,
    );
    final canRevise = canRevisePregnancyDecision(mating.status);
    final canKindle = canRecordKindling(mating.status);

    if (!canCheck && !canRevise && !canKindle) {
      return const SizedBox.shrink();
    }

    return DetailSection(
      title: 'Actions',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (canCheck)
              FilledButton.icon(
                onPressed: () =>
                    context.push('/breeding/${mating.id}/pregnancy-check'),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Pregnancy check'),
              ),
            if (canRevise)
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/breeding/${mating.id}/pregnancy-check?revise=1',
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit decision'),
              ),
            if (canKindle)
              FilledButton.icon(
                onPressed: () =>
                    context.push('/litters/new?matingId=${mating.id}'),
                icon: const Icon(Icons.child_care_outlined),
                label: const Text('Record kindling'),
              ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mating});

  final MatingDetail mating;

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
            '${mating.doeIdentifier} x ${mating.buckIdentifier}',
            style: textTheme.titleLarge?.copyWith(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            breedingStatusLabel(mating.status),
            style: textTheme.bodyMedium?.copyWith(
              color: RabbiTrackColors.mintGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _PregnancyChecksSection extends StatelessWidget {
  const _PregnancyChecksSection({required this.checks});

  final List<PregnancyCheckSummary> checks;

  @override
  Widget build(BuildContext context) {
    if (checks.isEmpty) {
      return const DetailSection(
        title: 'Pregnancy checks',
        children: [DetailInfoRow('Latest', 'No checks recorded')],
      );
    }

    return DetailSection(
      title: 'Pregnancy checks',
      children: [
        for (final check in checks)
          DetailInfoRow(
            check.checkedOn ?? 'Check',
            pregnancyCheckResultLabel(check.result),
          ),
      ],
    );
  }
}

class _LittersSection extends StatelessWidget {
  const _LittersSection({required this.litters});

  final List<MatingLitterSummary> litters;

  @override
  Widget build(BuildContext context) {
    if (litters.isEmpty) {
      return const DetailSection(
        title: 'Litters',
        children: [DetailInfoRow('Result', 'No litter recorded')],
      );
    }

    return DetailSection(
      title: 'Litters',
      children: [
        for (final litter in litters)
          DetailInfoRow(
            litter.identifier,
            '${litter.kindledOn ?? '-'} | Alive ${litter.bornAlive ?? 0} | Dead ${litter.bornDead ?? 0}',
          ),
      ],
    );
  }
}
