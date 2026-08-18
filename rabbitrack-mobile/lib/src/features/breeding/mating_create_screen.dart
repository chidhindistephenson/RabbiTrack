import 'package:flutter/material.dart';
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
import 'breeding_options.dart';
import 'mating_controller.dart';
import 'mating_repository.dart';

class MatingCreateScreen extends ConsumerStatefulWidget {
  const MatingCreateScreen({super.key, this.initialRabbitId});

  final String? initialRabbitId;

  @override
  ConsumerState<MatingCreateScreen> createState() => _MatingCreateScreenState();
}

class _MatingCreateScreenState extends ConsumerState<MatingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _behaviorController = TextEditingController();
  final _notesController = TextEditingController();
  String? _doeId;
  String? _buckId;
  DateTime _matedAt = DateTime.now();
  String _outcome = 'observed';
  bool _confirmRelationshipRisk = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _behaviorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        _doeId == null ||
        _buckId == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(matingRepositoryProvider)
          .create(
            farmId: farm.id,
            doeId: _doeId!,
            buckId: _buckId!,
            matedAt: _dateValue(_matedAt),
            outcome: _outcome,
            behaviorObserved: _optionalText(_behaviorController),
            notes: _optionalText(_notesController),
            confirmRelationshipRisk: _confirmRelationshipRisk,
          );

      ref.invalidate(matingListProvider);
      ref.invalidate(rabbitMatingListProvider(_doeId!));
      ref.invalidate(rabbitMatingListProvider(_buckId!));
      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Mating recorded.');
        popOrGo(
          context,
          widget.initialRabbitId == null
              ? '/breeding'
              : '/breeding?rabbitId=${widget.initialRabbitId}',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(
            error,
            'Could not save mating. Check the selected rabbits.',
          ),
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

  Future<void> _pickMatedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _matedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _matedAt = picked);
    }
  }

  String _dateValue(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final rabbits = ref.watch(rabbitListProvider);
    final farm = ref.watch(authControllerProvider).valueOrNull?.selectedFarm;

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: widget.initialRabbitId == null
              ? '/breeding'
              : '/breeding?rabbitId=${widget.initialRabbitId}',
        ),
        title: const Text('Record mating'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: rabbits.when(
        data: (items) {
          final does = items
              .where(
                (rabbit) =>
                    rabbit.sex == 'female' &&
                    canSelectDoeForMating(rabbit.status) &&
                    _meetsBreedingAge(
                      rabbit,
                      farm?.breedingMinDoeAgeDays ?? 0,
                    ),
              )
              .toList();
          final bucks = items
              .where(
                (rabbit) =>
                    rabbit.sex == 'male' &&
                    canSelectBuckForMating(rabbit.status) &&
                    _meetsBreedingAge(
                      rabbit,
                      farm?.breedingMinBuckAgeDays ?? 0,
                    ),
              )
              .toList();
          final initialRabbit = widget.initialRabbitId == null
              ? null
              : items
                    .where((rabbit) => rabbit.id == widget.initialRabbitId)
                    .firstOrNull;
          final locksDoe =
              initialRabbit != null &&
              initialRabbit.sex == 'female' &&
              canSelectDoeForMating(initialRabbit.status) &&
              _meetsBreedingAge(
                initialRabbit,
                farm?.breedingMinDoeAgeDays ?? 0,
              );
          final locksBuck =
              initialRabbit != null &&
              initialRabbit.sex == 'male' &&
              canSelectBuckForMating(initialRabbit.status) &&
              _meetsBreedingAge(
                initialRabbit,
                farm?.breedingMinBuckAgeDays ?? 0,
              );

          if (locksDoe && _doeId == null) {
            _doeId = initialRabbit.id;
          }

          if (locksBuck && _buckId == null) {
            _buckId = initialRabbit.id;
          }

          if (does.isEmpty || bucks.isEmpty) {
            return AppState(
              icon: Icons.favorite_border,
              title: 'Available breeding pair needed',
              message:
                  'A doe and buck must be available and meet farm breeding rules before recording a new mating.',
              actionLabel: 'Add rabbit',
              actionIcon: Icons.add,
              onAction: () => context.push('/rabbits/new'),
            );
          }

          final relationshipWarning = _relationshipWarning(items);
          if (relationshipWarning == null && _confirmRelationshipRisk) {
            _confirmRelationshipRisk = false;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _doeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Doe',
                    border: OutlineInputBorder(),
                  ),
                  items: does.map(_rabbitItem).toList(),
                  onChanged: locksDoe
                      ? null
                      : (value) => setState(() => _doeId = value),
                  validator: (value) => value == null ? 'Select a doe' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _buckId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Buck',
                    border: OutlineInputBorder(),
                  ),
                  items: bucks.map(_rabbitItem).toList(),
                  onChanged: locksBuck
                      ? null
                      : (value) => setState(() => _buckId = value),
                  validator: (value) => value == null ? 'Select a buck' : null,
                ),
                const SizedBox(height: 14),
                if (relationshipWarning != null) ...[
                  _RelationshipWarning(
                    message: relationshipWarning,
                    confirmed: _confirmRelationshipRisk,
                    onChanged: (value) => setState(
                      () => _confirmRelationshipRisk = value ?? false,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _DateField(
                  label: 'Mating date',
                  value: _dateValue(_matedAt),
                  onTap: _pickMatedAt,
                ),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'observed', label: Text('Observed')),
                    ButtonSegment(value: 'attempted', label: Text('Attempted')),
                    ButtonSegment(value: 'uncertain', label: Text('Uncertain')),
                  ],
                  selected: {_outcome},
                  onSelectionChanged: (value) {
                    setState(() => _outcome = value.single);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _behaviorController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Behavior observed',
                    border: OutlineInputBorder(),
                  ),
                ),
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
                  onPressed:
                      _isSaving ||
                          _doeId == null ||
                          _buckId == null ||
                          (relationshipWarning != null &&
                              !_confirmRelationshipRisk)
                      ? null
                      : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save mating'),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load rabbits',
          message: 'Check that the API server is running, then try again.',
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

  String? _relationshipWarning(List<RabbitSummary> rabbits) {
    if (_doeId == null || _buckId == null) {
      return null;
    }

    final doe = rabbits.where((rabbit) => rabbit.id == _doeId).firstOrNull;
    final buck = rabbits.where((rabbit) => rabbit.id == _buckId).firstOrNull;
    if (doe == null || buck == null) {
      return null;
    }

    if (doe.motherId == buck.id ||
        doe.fatherId == buck.id ||
        buck.motherId == doe.id ||
        buck.fatherId == doe.id) {
      return 'These rabbits have a direct parent-child relationship in their records.';
    }

    final sharedMother = doe.motherId != null && doe.motherId == buck.motherId;
    final sharedFather = doe.fatherId != null && doe.fatherId == buck.fatherId;

    if (sharedMother && sharedFather) {
      return 'These rabbits share both recorded parents.';
    }
    if (sharedMother) {
      return 'These rabbits share the same recorded mother.';
    }
    if (sharedFather) {
      return 'These rabbits share the same recorded father.';
    }

    return null;
  }

  bool _meetsBreedingAge(RabbitSummary rabbit, int minAgeDays) {
    if (minAgeDays <= 0) {
      return true;
    }

    final birthDate = DateTime.tryParse(rabbit.dateOfBirth ?? '');
    if (birthDate == null) {
      return false;
    }

    final birthDateOnly = DateTime(
      birthDate.year,
      birthDate.month,
      birthDate.day,
    );
    final matedDateOnly = DateTime(
      _matedAt.year,
      _matedAt.month,
      _matedAt.day,
    );

    return matedDateOnly.difference(birthDateOnly).inDays >= minAgeDays;
  }
}

class _RelationshipWarning extends StatelessWidget {
  const _RelationshipWarning({
    required this.message,
    required this.confirmed,
    required this.onChanged,
  });

  final String message;
  final bool confirmed;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RabbiTrackColors.warmTan.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RabbiTrackColors.warmTan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: RabbiTrackColors.forestGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: confirmed,
              onChanged: onChanged,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Confirm relationship risk',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value),
      ),
    );
  }
}
