import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../rabbits/rabbit_controller.dart';
import '../rabbits/rabbit_models.dart';
import '../rabbits/rabbit_options.dart';
import 'health_controller.dart';
import 'health_options.dart';
import 'health_repository.dart';

class HealthCreateScreen extends ConsumerStatefulWidget {
  const HealthCreateScreen({super.key, this.initialRabbitId});

  final String? initialRabbitId;

  @override
  ConsumerState<HealthCreateScreen> createState() => _HealthCreateScreenState();
}

class _HealthCreateScreenState extends ConsumerState<HealthCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  String? _rabbitId;
  String _severity = 'moderate';
  String _bodySystem = healthBodySystemValue('General');
  bool _isolationRequired = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rabbitId = widget.initialRabbitId;
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        _rabbitId == null ||
        _symptomsController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(healthRepositoryProvider)
          .create(
            farmId: farm.id,
            rabbitId: _rabbitId!,
            symptoms: _symptomsController.text.trim(),
            diagnosis: _diagnosisController.text.trim().isEmpty
                ? null
                : _diagnosisController.text.trim(),
            severity: _severity,
            bodySystem: _bodySystem,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            isolationRequired: _isolationRequired,
          );

      ref.invalidate(healthEventListProvider);
      if (_rabbitId != null) {
        ref.invalidate(rabbitHealthEventListProvider(_rabbitId!));
        ref.invalidate(rabbitDetailProvider(_rabbitId!));
      }
      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Health event recorded.');
        popOrGo(
          context,
          widget.initialRabbitId == null
              ? '/health'
              : '/health?rabbitId=${widget.initialRabbitId}',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save health event. Try again.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rabbits = ref.watch(rabbitListProvider);
    final lockedRabbit = widget.initialRabbitId == null
        ? null
        : ref.watch(rabbitDetailProvider(widget.initialRabbitId!));

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: widget.initialRabbitId == null
              ? '/health'
              : '/health?rabbitId=${widget.initialRabbitId}',
        ),
        title: const Text('Record health event'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: rabbits.when(
        data: (items) {
          final activeRabbits = items
              .where((rabbit) => !isTerminalRabbitStatus(rabbit.status))
              .toList();
          final selectedIsActive =
              _rabbitId != null &&
              activeRabbits.any((rabbit) => rabbit.id == _rabbitId);

          if (widget.initialRabbitId != null && !selectedIsActive) {
            return AppState(
              icon: Icons.lock_outline,
              title: 'Rabbit is no longer active',
              message:
                  'Health events can only be recorded for rabbits currently on the farm.',
              actionLabel: 'Back to records',
              onAction: () => popOrGo(
                context,
                '/health?rabbitId=${widget.initialRabbitId}',
              ),
            );
          }

          if (activeRabbits.isEmpty) {
            return AppState(
              icon: Icons.manage_search,
              title: 'No active rabbits available',
              message: 'Add an active rabbit before recording a health event.',
              actionLabel: 'Add rabbit',
              actionIcon: Icons.add,
              onAction: () => popOrGo(context, '/rabbits/new'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                lockedRabbit?.when(
                      data: (item) => _TargetContextCard(
                        title:
                            '${item.identifier}${item.name == null ? '' : ' - ${item.name}'}',
                        subtitle:
                            'Health event will be saved to this rabbit profile.',
                      ),
                      error: (error, stackTrace) => AppState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load rabbit',
                        message: 'Check the API server and try again.',
                        actionLabel: 'Retry',
                        onAction: () =>
                            ref.invalidate(rabbitDetailProvider(_rabbitId!)),
                        minHeight: 180,
                      ),
                      loading: () => const LinearProgressIndicator(),
                    ) ??
                    DropdownButtonFormField<String>(
                      initialValue: _rabbitId,
                      decoration: const InputDecoration(
                        labelText: 'Rabbit',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: activeRabbits.map(_rabbitItem).toList(),
                      onChanged: (value) => setState(() => _rabbitId = value),
                      validator: (value) =>
                          value == null ? 'Select a rabbit' : null,
                    ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _bodySystem,
                  decoration: const InputDecoration(
                    labelText: 'Body system',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final label in healthBodySystems)
                      DropdownMenuItem(
                        value: healthBodySystemValue(label),
                        child: Text(label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _bodySystem = value!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _symptomsController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Symptoms',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter symptoms'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _diagnosisController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mild', child: Text('Mild')),
                    DropdownMenuItem(
                      value: 'moderate',
                      child: Text('Moderate'),
                    ),
                    DropdownMenuItem(value: 'severe', child: Text('Severe')),
                    DropdownMenuItem(
                      value: 'critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _severity = value!),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isolationRequired,
                  onChanged: (value) =>
                      setState(() => _isolationRequired = value),
                  title: const Text('Isolation required'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _isSaving || !selectedIsActive ? null : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save health event'),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load rabbits',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(rabbitListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  DropdownMenuItem<String> _rabbitItem(RabbitSummary rabbit) {
    return DropdownMenuItem(
      value: rabbit.id,
      child: Text(
        '${rabbit.identifier}${rabbit.name == null ? '' : ' - ${rabbit.name}'}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TargetContextCard extends StatelessWidget {
  const _TargetContextCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
          const Icon(
            Icons.medical_services_outlined,
            color: RabbiTrackColors.forestGreen,
          ),
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
                const SizedBox(height: 6),
                Text(
                  subtitle,
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
