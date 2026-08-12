import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../home/farm_summary_controller.dart';
import '../rabbits/rabbit_controller.dart';
import 'health_controller.dart';
import 'health_models.dart';
import 'health_options.dart';
import 'health_repository.dart';

class HealthListScreen extends ConsumerWidget {
  const HealthListScreen({super.key, this.rabbitId});

  final String? rabbitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRabbitProfileView = rabbitId != null;
    final events = isRabbitProfileView
        ? ref.watch(rabbitHealthEventListProvider(rabbitId!))
        : ref.watch(healthEventListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRabbitProfileView ? 'Rabbit health' : 'Health'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          isRabbitProfileView
              ? '/health/new?rabbitId=$rabbitId'
              : '/health/new',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Event'),
      ),
      body: events.when(
        data: (items) {
          if (items.isEmpty) {
            return AppState(
              icon: Icons.medical_services_outlined,
              title: isRabbitProfileView
                  ? 'No health records for this rabbit'
                  : 'No health events yet',
              message:
                  'Record symptoms, diagnosis, isolation needs, and treatment follow-up from one place.',
              actionLabel: 'Add event',
              actionIcon: Icons.add,
              onAction: () => context.push(
                isRabbitProfileView
                    ? '/health/new?rabbitId=$rabbitId'
                    : '/health/new',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => isRabbitProfileView
                ? ref.refresh(rabbitHealthEventListProvider(rabbitId!).future)
                : ref.refresh(healthEventListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => _HealthTile(event: items[index]),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: items.length,
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load health',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => isRabbitProfileView
              ? ref.invalidate(rabbitHealthEventListProvider(rabbitId!))
              : ref.invalidate(healthEventListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HealthTile extends ConsumerWidget {
  const _HealthTile({required this.event});

  final HealthEventSummary event;

  Future<void> _updateStatus(WidgetRef ref, String action) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    await ref
        .read(healthRepositoryProvider)
        .updateStatus(farmId: farm.id, healthEventId: event.id, action: action);

    ref.invalidate(healthEventListProvider);
    ref.invalidate(farmSummaryProvider);
    ref.invalidate(rabbitListProvider);
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add treatment'),
                onTap: () => Navigator.of(context).pop('treatment'),
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Mark monitoring'),
                onTap: () => Navigator.of(context).pop('monitor'),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Resolve event'),
                onTap: () => Navigator.of(context).pop('resolve'),
              ),
            ],
          ),
        );
      },
    );

    try {
      if (action == 'treatment' && context.mounted) {
        context.push('/health/${event.id}/treatments/new');
      } else if (action == 'monitor') {
        await _updateStatus(ref, 'monitor');
        if (context.mounted) {
          showSuccessSnackBar(context, 'Health event marked for monitoring.');
        }
      } else if (action == 'resolve') {
        await _updateStatus(ref, 'resolve');
        if (context.mounted) {
          showSuccessSnackBar(context, 'Health event resolved.');
        }
      }
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, _errorMessageFor(action));
      }
    }
  }

  String _errorMessageFor(String? action) {
    return switch (action) {
      'monitor' => 'Could not mark event for monitoring. Try again.',
      'resolve' => 'Could not resolve health event. Try again.',
      _ => 'Could not update health event. Try again.',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftListTile(
      icon: event.isolationRequired
          ? Icons.warning_amber
          : Icons.medical_services_outlined,
      title: '${event.rabbitIdentifier} - ${event.symptoms}',
      subtitle: [
        healthBodySystemLabel(event.bodySystem),
        healthSeverityLabel(event.severity),
        healthStatusLabel(event.status),
        event.isolationRequired ? 'Isolation' : null,
        '${event.treatmentsCount} treatment${event.treatmentsCount == 1 ? '' : 's'}',
      ].whereType<String>().join(' | '),
      trailing: IconButton(
        tooltip: 'Health actions',
        onPressed: () => _showActions(context, ref),
        icon: const Icon(Icons.more_vert),
      ),
    );
  }
}
