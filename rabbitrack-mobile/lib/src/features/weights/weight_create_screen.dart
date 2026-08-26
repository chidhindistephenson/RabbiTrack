import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../rabbits/rabbit_controller.dart';
import '../rabbits/rabbit_models.dart';
import '../rabbits/rabbit_options.dart';
import 'weight_controller.dart';
import 'weight_repository.dart';

class WeightCreateScreen extends ConsumerStatefulWidget {
  const WeightCreateScreen({
    super.key,
    this.initialRabbitId,
    this.initialLitterId,
  });

  final String? initialRabbitId;
  final String? initialLitterId;

  @override
  ConsumerState<WeightCreateScreen> createState() => _WeightCreateScreenState();
}

class _WeightCreateScreenState extends ConsumerState<WeightCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _methodController = TextEditingController(text: 'Digital scale');
  final _notesController = TextEditingController();
  String? _rabbitId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rabbitId = widget.initialRabbitId;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _methodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    final weight = double.tryParse(_weightController.text);

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        weight == null) {
      return;
    }

    if (_rabbitId == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(weightRepositoryProvider)
          .recordRabbitWeight(
            farmId: farm.id,
            rabbitId: _rabbitId!,
            weightValue: weight,
            method: _optionalText(_methodController),
            notes: _optionalText(_notesController),
          );

      ref.invalidate(rabbitWeightListProvider(_rabbitId!));
      ref.invalidate(rabbitListProvider);
      ref.invalidate(rabbitDetailProvider(_rabbitId!));

      ref.invalidate(weightListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Weight recorded.');
        popOrGo(context, '/rabbits/$_rabbitId');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save weight. Try again.'),
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
    final lockedTerminalRabbit =
        lockedRabbit?.valueOrNull != null &&
        isTerminalRabbitStatus(lockedRabbit!.valueOrNull!.status);

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: widget.initialRabbitId != null
              ? '/rabbits/${widget.initialRabbitId}'
              : widget.initialLitterId == null
              ? '/weights'
              : '/litters/${widget.initialLitterId}',
        ),
        title: const Text('Record weight'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: widget.initialLitterId != null
          ? AppState(
              icon: Icons.monitor_weight_outlined,
              title: 'Litter weights are automatic',
              message:
                  'Record birth litter weight during kindling and weaning weight during weaning.',
              actionLabel: 'Back to litter',
              onAction: () =>
                  popOrGo(context, '/litters/${widget.initialLitterId}'),
            )
          : lockedTerminalRabbit
          ? AppState(
              icon: Icons.lock_outline,
              title: 'Rabbit is no longer active',
              message:
                  'Weights can only be recorded for rabbits currently on the farm.',
              actionLabel: 'Back to profile',
              onAction: () =>
                  popOrGo(context, '/rabbits/${widget.initialRabbitId}'),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  lockedRabbit?.when(
                        data: (item) => _TargetContextCard(
                          icon: Icons.manage_search,
                          title:
                              '${item.identifier}${item.name == null ? '' : ' - ${item.name}'}',
                          subtitle:
                              'Rabbit weight will be saved to this profile.',
                        ),
                        error: (error, stackTrace) => AppState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load rabbit',
                          message:
                              'Try again. Offline demo data should remain available.',
                          actionLabel: 'Retry',
                          onAction: () =>
                              ref.invalidate(rabbitDetailProvider(_rabbitId!)),
                          minHeight: 180,
                        ),
                        loading: () => const LinearProgressIndicator(),
                      ) ??
                      rabbits.when(
                        data: (items) {
                          final activeRabbits = items
                              .where(
                                (rabbit) =>
                                    !isTerminalRabbitStatus(rabbit.status),
                              )
                              .toList();

                          if (activeRabbits.isEmpty) {
                            return AppState(
                              icon: Icons.manage_search,
                              title: 'No active rabbits to weigh',
                              message:
                                  'Add an active rabbit before recording weights.',
                              actionLabel: 'Add rabbit',
                              actionIcon: Icons.add,
                              onAction: () => context.push('/rabbits/new'),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: _rabbitId,
                            decoration: const InputDecoration(
                              labelText: 'Rabbit',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            items: activeRabbits.map(_rabbitItem).toList(),
                            onChanged: (value) =>
                                setState(() => _rabbitId = value),
                            validator: (value) =>
                                value == null ? 'Select a rabbit' : null,
                          );
                        },
                        error: (error, stackTrace) => AppState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load rabbits',
                          message:
                              'Try again. Offline demo data should remain available.',
                          actionLabel: 'Retry',
                          onAction: () => ref.invalidate(rabbitListProvider),
                          minHeight: 180,
                        ),
                        loading: () => const LinearProgressIndicator(),
                      ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Weight kg',
                      border: const OutlineInputBorder(),
                    ),
                    validator: _weightValidator,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _methodController,
                    decoration: const InputDecoration(
                      labelText: 'Method',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _isSaving || !_hasTarget ? null : _save,
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save weight'),
                  ),
                ],
              ),
            ),
    );
  }

  bool get _hasTarget {
    return _rabbitId != null;
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

  String? _weightValidator(String? value) {
    final weight = double.tryParse(value?.trim() ?? '');
    if (weight == null) {
      return 'Enter a weight';
    }
    if (weight <= 0) {
      return 'Weight must be greater than zero';
    }

    return null;
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }
}

class _TargetContextCard extends StatelessWidget {
  const _TargetContextCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
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
          Icon(icon, color: RabbiTrackColors.forestGreen),
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
