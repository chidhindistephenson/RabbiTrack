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
import '../breeding/mating_controller.dart';
import '../breeding/mating_models.dart';
import '../rabbits/rabbit_controller.dart';
import '../rabbits/rabbit_models.dart';
import '../rabbits/rabbit_options.dart';
import 'litter_controller.dart';
import 'litter_repository.dart';

class KindlingCreateScreen extends ConsumerStatefulWidget {
  const KindlingCreateScreen({super.key, this.initialMatingId});

  final String? initialMatingId;

  @override
  ConsumerState<KindlingCreateScreen> createState() =>
      _KindlingCreateScreenState();
}

class _KindlingCreateScreenState extends ConsumerState<KindlingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliveController = TextEditingController(text: '0');
  final _stillbornController = TextEditingController(text: '0');
  final _weakController = TextEditingController(text: '0');
  final _birthWeightController = TextEditingController();
  final _nestConditionController = TextEditingController();
  final _doeConditionController = TextEditingController();
  final _notesController = TextEditingController();
  String? _matingId;
  String? _doeId;
  bool _isSaving = false;
  String? _initializedMatingId;

  @override
  void dispose() {
    _aliveController.dispose();
    _stillbornController.dispose();
    _weakController.dispose();
    _birthWeightController.dispose();
    _nestConditionController.dispose();
    _doeConditionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        (_matingId == null && _doeId == null)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(litterRepositoryProvider)
          .recordKindling(
            farmId: farm.id,
            matingId: _matingId,
            doeId: _matingId == null ? _doeId : null,
            kitsBornAlive: int.tryParse(_aliveController.text) ?? 0,
            kitsStillborn: int.tryParse(_stillbornController.text) ?? 0,
            kitsWeak: int.tryParse(_weakController.text) ?? 0,
            birthWeightValue: double.tryParse(_birthWeightController.text) ?? 0,
            nestCondition: _optionalText(_nestConditionController),
            doeCondition: _optionalText(_doeConditionController),
            notes: _optionalText(_notesController),
          );

      ref.invalidate(litterListProvider);
      ref.invalidate(matingListProvider);
      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Kindling recorded.');
        popOrGo(
          context,
          widget.initialMatingId == null
              ? '/litters'
              : '/breeding/${widget.initialMatingId}',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save kindling. Try again.'),
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
    final matings = ref.watch(matingListProvider);
    final rabbits = ref.watch(rabbitListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/litters'),
        title: const Text('Record kindling'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: matings.when(
        data: (items) {
          if (rabbits.isLoading && !rabbits.hasValue) {
            return const Center(child: CircularProgressIndicator());
          }

          final rabbitItems = rabbits.valueOrNull ?? const <RabbitSummary>[];
          final candidates = items
              .where(
                (mating) => [
                  'pregnant',
                  'awaiting_pregnancy_check',
                  'uncertain',
                ].contains(mating.status),
              )
              .toList();
          final initialMating = widget.initialMatingId == null
              ? null
              : candidates
                    .where((mating) => mating.id == widget.initialMatingId)
                    .firstOrNull;
          final locksMating = initialMating != null;
          final doeCandidates = rabbitItems
              .where(
                (rabbit) =>
                    rabbit.sex == 'female' &&
                    !isTerminalRabbitStatus(rabbit.status),
              )
              .toList();

          if (locksMating && _initializedMatingId != initialMating.id) {
            _initializedMatingId = initialMating.id;
            _matingId = initialMating.id;
            _doeId = null;
          }

          if (candidates.isEmpty && doeCandidates.isEmpty) {
            return AppState(
              icon: Icons.child_care,
              title: 'No doe ready for kindling',
              message:
                  'Add a female rabbit or create a mating record before recording kindling.',
              actionLabel: 'Add rabbit',
              actionIcon: Icons.add,
              onAction: () => context.push('/rabbits/new'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (candidates.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _matingId,
                    decoration: const InputDecoration(
                      labelText: 'Mating record',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: candidates.map(_matingItem).toList(),
                    onChanged: locksMating
                        ? null
                        : (value) => setState(() {
                            _matingId = value;
                            if (value != null) {
                              _doeId = null;
                            }
                          }),
                    validator: (value) {
                      if (value == null && _doeId == null) {
                        return 'Select a mating or doe';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                if (doeCandidates.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _doeId,
                    decoration: InputDecoration(
                      labelText: candidates.isEmpty
                          ? 'Doe'
                          : 'Doe without mating record',
                      border: const OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: doeCandidates.map(_doeItem).toList(),
                    onChanged: locksMating
                        ? null
                        : (value) => setState(() {
                            _doeId = value;
                            if (value != null) {
                              _matingId = null;
                            }
                          }),
                    validator: (value) {
                      if (value == null && _matingId == null) {
                        return 'Select a doe or mating';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                _NumberField(controller: _aliveController, label: 'Born alive'),
                const SizedBox(height: 14),
                _NumberField(
                  controller: _stillbornController,
                  label: 'Stillborn',
                ),
                const SizedBox(height: 14),
                _NumberField(controller: _weakController, label: 'Weak'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _birthWeightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Birth litter weight kg',
                    helperText:
                        'Enter the total litter weight; average per kit is calculated.',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requiredWeightValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nestConditionController,
                  decoration: const InputDecoration(
                    labelText: 'Nest condition',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _doeConditionController,
                  decoration: const InputDecoration(
                    labelText: 'Doe condition',
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
                  onPressed: _isSaving || (_matingId == null && _doeId == null)
                      ? null
                      : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save kindling'),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load kindling form',
          message: 'Try again. Offline demo data should remain available.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(matingListProvider);
            ref.invalidate(rabbitListProvider);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  DropdownMenuItem<String> _matingItem(MatingSummary mating) {
    return DropdownMenuItem(
      value: mating.id,
      child: Text(
        '${mating.doeIdentifier} x ${mating.buckIdentifier}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  DropdownMenuItem<String> _doeItem(RabbitSummary rabbit) {
    final label = rabbit.name == null
        ? rabbit.identifier
        : '${rabbit.identifier} - ${rabbit.name}';

    return DropdownMenuItem(
      value: rabbit.id,
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _requiredWeightValidator(String? value) {
    final weight = double.tryParse(value?.trim() ?? '');
    if (weight == null) {
      return 'Enter the litter weight';
    }
    if (weight <= 0) {
      return 'Weight must be greater than zero';
    }

    return null;
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final count = int.tryParse(value?.trim() ?? '');
        if (count == null) {
          return 'Enter a count';
        }

        return null;
      },
    );
  }
}
