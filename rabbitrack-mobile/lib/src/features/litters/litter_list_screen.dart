import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import 'litter_controller.dart';
import 'litter_models.dart';
import 'litter_options.dart';

class LitterListScreen extends ConsumerWidget {
  const LitterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Litters'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/litters/new'),
        icon: const Icon(Icons.add),
        label: const Text('Kindling'),
      ),
      body: const LitterListContent(),
    );
  }
}

class LitterListContent extends ConsumerWidget {
  const LitterListContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final litters = ref.watch(litterListProvider);

    return litters.when(
      data: (items) {
        if (items.isEmpty) {
          return AppState(
            icon: Icons.child_care,
            title: 'No litters yet',
            message:
                'Record a kindling to start tracking live kits, weaning dates, and litter weight history.',
            actionLabel: 'Record kindling',
            actionIcon: Icons.add,
            onAction: () => context.push('/litters/new'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(litterListProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            itemBuilder: (context, index) => _LitterTile(
              litter: items[index],
              onTap: () => context.push('/litters/${items[index].id}'),
              onWean: () => context.push('/litters/${items[index].id}/weaning'),
            ),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: items.length,
          ),
        );
      },
      error: (error, stackTrace) => AppState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load litters',
        message: 'Check the API server and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(litterListProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LitterTile extends StatelessWidget {
  const _LitterTile({
    required this.litter,
    required this.onTap,
    required this.onWean,
  });

  final LitterSummary litter;
  final VoidCallback onTap;
  final VoidCallback onWean;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: Icons.child_care,
      title: '${litter.identifier} - ${litter.doeIdentifier}',
      subtitle:
          '${litterStatusLabel(litter.status)} | ${litter.currentLiveCount} live | Wean ${litter.plannedWeaningOn}',
      trailing: IconButton(
        tooltip: 'Record weaning',
        onPressed: litter.status == 'weaned' ? null : onWean,
        icon: const Icon(Icons.check_circle_outline),
      ),
      onTap: onTap,
    );
  }
}
