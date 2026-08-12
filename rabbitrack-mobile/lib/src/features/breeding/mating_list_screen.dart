import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../rabbits/rabbit_controller.dart';
import 'breeding_options.dart';
import 'mating_controller.dart';
import 'mating_models.dart';
import 'mating_repository.dart';

class MatingListScreen extends ConsumerWidget {
  const MatingListScreen({super.key, this.rabbitId});

  final String? rabbitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRabbitProfileView = rabbitId != null;
    final matings = isRabbitProfileView
        ? ref.watch(rabbitMatingListProvider(rabbitId!))
        : ref.watch(matingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRabbitProfileView ? 'Rabbit breeding' : 'Breeding'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          isRabbitProfileView
              ? '/breeding/new?rabbitId=$rabbitId'
              : '/breeding/new',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Mating'),
      ),
      body: matings.when(
        data: (items) {
          if (items.isEmpty) {
            return AppState(
              icon: Icons.favorite,
              title: isRabbitProfileView
                  ? 'No breeding records for this rabbit'
                  : 'No breeding records yet',
              message:
                  'Create a mating record to calculate pregnancy check and expected kindling dates.',
              actionLabel: 'Add mating',
              actionIcon: Icons.add,
              onAction: () => context.push(
                isRabbitProfileView
                    ? '/breeding/new?rabbitId=$rabbitId'
                    : '/breeding/new',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => isRabbitProfileView
                ? ref.refresh(rabbitMatingListProvider(rabbitId!).future)
                : ref.refresh(matingListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => _MatingTile(
                mating: items[index],
                onTap: () => context.push('/breeding/${items[index].id}'),
                onCheck: () => context.push(
                  '/breeding/${items[index].id}/pregnancy-check',
                ),
                onEdit: canRevisePregnancyDecision(items[index].status)
                    ? () => context.push(
                        '/breeding/${items[index].id}/pregnancy-check?revise=1',
                      )
                    : null,
                onDelete: () => _confirmDelete(context, ref, items[index]),
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: items.length,
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load breeding',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => isRabbitProfileView
              ? ref.invalidate(rabbitMatingListProvider(rabbitId!))
              : ref.invalidate(matingListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MatingSummary mating,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete mating record?'),
        content: Text(
          '${mating.doeIdentifier} x ${mating.buckIdentifier} will be removed. Records with litters cannot be deleted from here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    try {
      await ref
          .read(matingRepositoryProvider)
          .delete(farmId: farm.id, matingId: mating.id);

      ref.invalidate(matingListProvider);
      ref.invalidate(rabbitListProvider);

      if (context.mounted) {
        showSuccessSnackBar(context, 'Mating record deleted.');
      }
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not delete mating record.'),
        );
      }
    }
  }
}

class _MatingTile extends StatelessWidget {
  const _MatingTile({
    required this.mating,
    required this.onTap,
    required this.onCheck,
    required this.onDelete,
    this.onEdit,
  });

  final MatingSummary mating;
  final VoidCallback onTap;
  final VoidCallback onCheck;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: Icons.favorite,
      title: '${mating.doeIdentifier} x ${mating.buckIdentifier}',
      subtitle:
          '${breedingStatusLabel(mating.status)} | Check ${mating.pregnancyCheckDueOn} | Kindling ${mating.expectedKindlingOn}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPregnancyCheckDue(
            status: mating.status,
            dueOn: mating.pregnancyCheckDueOn,
          ))
            IconButton(
              tooltip: 'Pregnancy check',
              onPressed: onCheck,
              icon: const Icon(Icons.fact_check_outlined),
            ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit pregnancy decision',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: 'Delete mating record',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
