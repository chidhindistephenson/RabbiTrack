import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../home/farm_summary_controller.dart';
import 'rabbit_controller.dart';
import 'rabbit_options.dart';
import 'rabbit_repository.dart';
import 'rabbit_status_options.dart';

class RabbitStatusScreen extends ConsumerStatefulWidget {
  const RabbitStatusScreen({required this.rabbitId, super.key});

  final String rabbitId;

  @override
  ConsumerState<RabbitStatusScreen> createState() => _RabbitStatusScreenState();
}

class _RabbitStatusScreenState extends ConsumerState<RabbitStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _status = 'growing';
  String? _initializedRabbitId;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(rabbitRepositoryProvider)
          .updateStatus(
            farmId: farm.id,
            rabbitId: widget.rabbitId,
            status: _status,
            notes: _optionalText(_notesController),
          );

      ref.invalidate(rabbitListProvider);
      ref.invalidate(rabbitDetailProvider(widget.rabbitId));
      ref.invalidate(farmSummaryProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Rabbit status updated.');
        popOrGo(context, '/rabbits/${widget.rabbitId}');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not update status. Try again.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final rabbit = ref.watch(rabbitDetailProvider(widget.rabbitId));

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: '/rabbits/${widget.rabbitId}',
        ),
        title: const Text('Update status'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: SafeArea(
        child: rabbit.when(
          data: (item) {
            if (_initializedRabbitId != item.id) {
              _initializedRabbitId = item.id;
              _status = item.status;
            }

            if (isTerminalRabbitStatus(item.status)) {
              return AppState(
                icon: Icons.lock_outline,
                title: 'Status is locked',
                message:
                    'This rabbit is ${rabbitStatusLabel(item.status).toLowerCase()}, so its profile is historical and the status cannot be changed here.',
                actionLabel: 'Back to profile',
                onAction: () => popOrGo(context, '/rabbits/${widget.rabbitId}'),
              );
            }

            final statusOptions = editableRabbitStatusesForSex(item.sex);
            if (!statusOptions.contains(_status)) {
              _status = 'growing';
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatusContextCard(
                    title: rabbitStatusScreenTitle(
                      identifier: item.identifier,
                      name: item.name,
                    ),
                    currentStatus: rabbitCurrentStatusText(item.status),
                    sexHint: rabbitStatusSexHint(item.sex),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: statusOptions
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              rabbitStatusLabel(status),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                  if (_status == 'ready_for_sale') ...[
                    const SizedBox(height: 12),
                    const _ReadinessNotice(),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save status'),
                  ),
                ],
              ),
            );
          },
          error: (error, stackTrace) => AppState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load rabbit',
            message: 'Try again. Offline demo data should remain available.',
            actionLabel: 'Retry',
            onAction: () =>
                ref.invalidate(rabbitDetailProvider(widget.rabbitId)),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ReadinessNotice extends StatelessWidget {
  const _ReadinessNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RabbiTrackColors.warmTan.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RabbiTrackColors.warmTan),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            color: RabbiTrackColors.forestGreen,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sale readiness is checked against active health events, quarantine, treatment and medicine withdrawal periods.',
              style: TextStyle(
                color: RabbiTrackColors.forestGreen,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusContextCard extends StatelessWidget {
  const _StatusContextCard({
    required this.title,
    required this.currentStatus,
    required this.sexHint,
  });

  final String title;
  final String currentStatus;
  final String sexHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RabbiTrackColors.mintGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_note, color: RabbiTrackColors.forestGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStatus,
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sexHint,
                  style: const TextStyle(color: RabbiTrackColors.forestGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
