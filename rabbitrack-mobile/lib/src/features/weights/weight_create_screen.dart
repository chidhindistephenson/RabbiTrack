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
import '../litters/litter_controller.dart';
import '../litters/litter_models.dart';
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
  late String _targetType;
  String? _rabbitId;
  String? _litterId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rabbitId = widget.initialRabbitId;
    _litterId = widget.initialLitterId;
    _targetType = widget.initialLitterId == null ? 'rabbit' : 'litter';
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

    if (_targetType == 'rabbit' && _rabbitId == null) {
      return;
    }

    if (_targetType == 'litter' && _litterId == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_targetType == 'rabbit') {
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
      } else {
        await ref
            .read(weightRepositoryProvider)
            .recordLitterWeight(
              farmId: farm.id,
              litterId: _litterId!,
              weightValue: weight,
              method: _optionalText(_methodController),
              notes: _optionalText(_notesController),
            );

        ref.invalidate(litterWeightListProvider(_litterId!));
        ref.invalidate(litterListProvider);
        ref.invalidate(litterDetailProvider(_litterId!));
      }

      ref.invalidate(weightListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Weight recorded.');
        popOrGo(
          context,
          _targetType == 'rabbit' && _rabbitId != null
              ? '/rabbits/$_rabbitId'
              : _targetType == 'litter' && _litterId != null
              ? '/litters/$_litterId'
              : '/weights',
        );
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
    final litters = ref.watch(litterListProvider);
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
      body: lockedTerminalRabbit
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
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'rabbit',
                        icon: Icon(Icons.manage_search),
                        label: Text('Rabbit'),
                      ),
                      ButtonSegment(
                        value: 'litter',
                        icon: Icon(Icons.child_care),
                        label: Text('Litter'),
                      ),
                    ],
                    selected: {_targetType},
                    onSelectionChanged:
                        widget.initialRabbitId != null ||
                            widget.initialLitterId != null
                        ? null
                        : (value) {
                            setState(() {
                              _targetType = value.first;
                              if (_targetType == 'rabbit') {
                                _litterId = null;
                              } else {
                                _rabbitId = null;
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 14),
                  if (_targetType == 'rabbit')
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
                            message: 'Check the API server and try again.',
                            actionLabel: 'Retry',
                            onAction: () => ref.invalidate(
                              rabbitDetailProvider(_rabbitId!),
                            ),
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
                            message: 'Check the API server and try again.',
                            actionLabel: 'Retry',
                            onAction: () => ref.invalidate(rabbitListProvider),
                            minHeight: 180,
                          ),
                          loading: () => const LinearProgressIndicator(),
                        )
                  else
                    litters.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return AppState(
                            icon: Icons.child_care,
                            title: 'No litters to weigh',
                            message:
                                'Record a kindling before weighing a litter.',
                            actionLabel: 'Record kindling',
                            actionIcon: Icons.add,
                            onAction: () => context.push('/litters/new'),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _litterId,
                          decoration: const InputDecoration(
                            labelText: 'Litter',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: items.map(_litterItem).toList(),
                          onChanged: (value) =>
                              setState(() => _litterId = value),
                          validator: (value) =>
                              value == null ? 'Select a litter' : null,
                        );
                      },
                      error: (error, stackTrace) => AppState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load litters',
                        message: 'Check the API server and try again.',
                        actionLabel: 'Retry',
                        onAction: () => ref.invalidate(litterListProvider),
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
                    decoration: const InputDecoration(
                      labelText: 'Weight kg',
                      border: OutlineInputBorder(),
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
    return _targetType == 'rabbit' ? _rabbitId != null : _litterId != null;
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

  DropdownMenuItem<String> _litterItem(LitterSummary litter) {
    return DropdownMenuItem(
      value: litter.id,
      child: Text(
        '${litter.identifier} - ${litter.doeIdentifier}',
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
