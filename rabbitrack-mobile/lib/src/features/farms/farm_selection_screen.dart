import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import 'farm_selection_options.dart';

class FarmSelectionScreen extends ConsumerWidget {
  const FarmSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;

    if (session == null) {
      return const Scaffold(
        body: AppState(
          icon: Icons.lock_outline,
          title: 'Please sign in',
          message: 'Sign in before choosing a farm.',
        ),
      );
    }

    if (session.farms.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select farm'),
          backgroundColor: RabbiTrackColors.forestGreen,
          foregroundColor: RabbiTrackColors.cream,
        ),
        body: AppState(
          icon: Icons.home_work_outlined,
          title: 'No farms yet',
          message: 'Create your first farm to start using RabbiTrack.',
          actionLabel: 'Create farm',
          actionIcon: Icons.add,
          onAction: () => context.push('/farms/new'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select farm'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        actions: [
          IconButton(
            tooltip: 'Create farm',
            onPressed: () => context.push('/farms/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SelectionHeader(
              message: farmSelectionHeader(
                farmCount: session.farms.length,
                hasSelectedFarm: session.selectedFarm != null,
              ),
            );
          }

          final farm = session.farms[index - 1];
          final isSelected = session.selectedFarm?.id == farm.id;

          return _FarmSelectionTile(farm: farm, isSelected: isSelected);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: session.farms.length + 1,
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RabbiTrackColors.mintGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.home_work_outlined,
            color: RabbiTrackColors.forestGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: RabbiTrackColors.forestGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmSelectionTile extends ConsumerWidget {
  const _FarmSelectionTile({required this.farm, required this.isSelected});

  final FarmSummary farm;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftListTile(
      icon: isSelected ? Icons.check_circle : Icons.home_work_outlined,
      title: farm.name,
      subtitle: farmSelectionSubtitle(farm),
      trailing: isSelected
          ? const _SelectedBadge()
          : const Icon(Icons.chevron_right),
      borderColor: isSelected
          ? RabbiTrackColors.forestGreen
          : Colors.transparent,
      borderWidth: 1.5,
      onTap: () async {
        await ref.read(authControllerProvider.notifier).selectFarm(farm);

        if (context.mounted) {
          context.go('/home');
        }
      },
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Active',
        style: TextStyle(
          color: RabbiTrackColors.cream,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
