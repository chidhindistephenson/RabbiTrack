import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'rabbit_controller.dart';
import 'rabbit_models.dart';
import 'rabbit_options.dart';
import 'rabbit_repository.dart';

class RabbitEditScreen extends ConsumerStatefulWidget {
  const RabbitEditScreen({required this.rabbitId, super.key});

  final String rabbitId;

  @override
  ConsumerState<RabbitEditScreen> createState() => _RabbitEditScreenState();
}

class _RabbitEditScreenState extends ConsumerState<RabbitEditScreen> {
  static const _customBreedValue = '__custom__';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customBreedController = TextEditingController();
  final _colourController = TextEditingController();
  final _weightController = TextEditingController();
  final _tagController = TextEditingController();
  final _notesController = TextEditingController();
  String _sex = 'female';
  String _status = 'growing';
  String _weightUnit = 'kg';
  String? _breed;
  String? _motherId;
  String? _fatherId;
  DateTime? _dateOfBirth;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _customBreedController.dispose();
    _colourController.dispose();
    _weightController.dispose();
    _tagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initialize(RabbitDetail rabbit) {
    if (_initialized) {
      return;
    }

    _nameController.text = rabbit.name ?? '';
    _colourController.text = rabbit.colour ?? '';
    _weightController.text = rabbit.weightValue ?? '';
    _weightUnit = rabbit.weightUnit ?? 'kg';
    _tagController.text = rabbit.tagOrTattoo ?? '';
    _notesController.text = rabbit.notes ?? '';
    _sex = rabbit.sex;
    _status = rabbit.status;
    if (rabbit.breed != null &&
        !southernAfricaRabbitBreeds.contains(rabbit.breed)) {
      _breed = _customBreedValue;
      _customBreedController.text = rabbit.breed!;
    } else {
      _breed = rabbit.breed;
    }
    _dateOfBirth = _parseDate(rabbit.dateOfBirth);
    _motherId = rabbit.mother?.id;
    _fatherId = rabbit.father?.id;
    _initialized = true;
  }

  Future<void> _save(RabbitDetail rabbit) async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(rabbitRepositoryProvider)
          .updateProfile(
            farmId: farm.id,
            rabbitId: rabbit.id,
            name: _emptyToNull(_nameController.text),
            sex: _sex,
            status: _status,
            breed: _selectedBreed(),
            colour: _emptyToNull(_colourController.text),
            currentLocationId: rabbit.currentLocationId,
            dateOfBirth: _formattedDate(_dateOfBirth),
            weightValue: _emptyToNull(_weightController.text),
            weightUnit: _emptyToNull(_weightController.text) == null
                ? null
                : _weightUnit,
            tagOrTattoo: _emptyToNull(_tagController.text),
            notes: _emptyToNull(_notesController.text),
            motherId: _motherId,
            fatherId: _fatherId,
          );

      ref.invalidate(rabbitListProvider);
      ref.invalidate(rabbitDetailProvider(rabbit.id));

      if (mounted) {
        showSuccessSnackBar(context, 'Rabbit profile saved.');
        popOrGo(context, '/rabbits/${rabbit.id}');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save rabbit profile.'),
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
    final rabbit = ref.watch(rabbitDetailProvider(widget.rabbitId));
    final parentOptions = ref.watch(rabbitParentOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: '/rabbits/${widget.rabbitId}',
        ),
        title: const Text('Edit rabbit'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: rabbit.when(
        data: (item) {
          _initialize(item);
          final statusOptions = editableRabbitStatusesForSex(_sex);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  item.identifier,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: RabbiTrackColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _formattedDate(_dateOfBirth) ?? '',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Date of birth',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Select date',
                      onPressed: _pickDateOfBirth,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  onTap: _pickDateOfBirth,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sex',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sex = value!;
                      if (!editableRabbitStatusesForSex(
                        _sex,
                      ).contains(_status)) {
                        _status = 'growing';
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final status in statusOptions)
                      DropdownMenuItem(
                        value: status,
                        child: Text(
                          rabbitStatusLabel(status),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _breed,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No breed selected'),
                    ),
                    for (final breed in southernAfricaRabbitBreeds)
                      DropdownMenuItem(
                        value: breed,
                        child: Text(breed, overflow: TextOverflow.ellipsis),
                      ),
                    const DropdownMenuItem(
                      value: _customBreedValue,
                      child: Text('Custom'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _breed = value),
                ),
                if (_breed == _customBreedValue) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customBreedController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Custom breed',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => _emptyToNull(value ?? '') == null
                        ? 'Enter a breed'
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                parentOptions.when(
                  data: (items) => _ParentFields(
                    rabbitId: item.id,
                    rabbits: items,
                    motherId: _motherId,
                    fatherId: _fatherId,
                    onMotherChanged: (value) =>
                        setState(() => _motherId = value),
                    onFatherChanged: (value) =>
                        setState(() => _fatherId = value),
                  ),
                  error: (error, stackTrace) =>
                      const Text('Parent options could not be loaded.'),
                  loading: () => const LinearProgressIndicator(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _colourController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Colour',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final trimmed = _emptyToNull(value ?? '');
                          if (trimmed == null) {
                            return null;
                          }

                          final parsed = num.tryParse(trimmed);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid weight';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _weightUnit,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'g', child: Text('g')),
                        ],
                        onChanged: (value) =>
                            setState(() => _weightUnit = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Physical mark',
                    helperText:
                        'Usually matches the Rabbit ID unless an older mark exists.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
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
                  onPressed: _isSaving ? null : () => _save(item),
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load rabbit profile',
          message: 'Try again. Offline demo data should remain available.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(rabbitDetailProvider(widget.rabbitId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _selectedBreed() {
    if (_breed == _customBreedValue) {
      return _emptyToNull(_customBreedController.text);
    }

    return _breed;
  }

  DateTime? _parseDate(String? value) {
    return value == null ? null : DateTime.tryParse(value);
  }

  String? _formattedDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );

    if (picked == null) {
      return;
    }

    setState(() => _dateOfBirth = picked);
  }
}

class _ParentFields extends StatelessWidget {
  const _ParentFields({
    required this.rabbitId,
    required this.rabbits,
    required this.motherId,
    required this.fatherId,
    required this.onMotherChanged,
    required this.onFatherChanged,
  });

  final String rabbitId;
  final List<RabbitSummary> rabbits;
  final String? motherId;
  final String? fatherId;
  final ValueChanged<String?> onMotherChanged;
  final ValueChanged<String?> onFatherChanged;

  @override
  Widget build(BuildContext context) {
    final possibleParents = rabbits
        .where((rabbit) => rabbit.id != rabbitId)
        .where(
          (rabbit) =>
              !isTerminalRabbitStatus(rabbit.status) ||
              rabbit.id == motherId ||
              rabbit.id == fatherId,
        )
        .toList();
    final does = possibleParents
        .where((rabbit) => rabbit.sex == 'female')
        .toList();
    final bucks = possibleParents
        .where((rabbit) => rabbit.sex == 'male')
        .toList();

    return Column(
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _selectedParentId(motherId, does),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Mother',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('No mother selected'),
            ),
            for (final rabbit in does) _parentItem(rabbit),
          ],
          onChanged: onMotherChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _selectedParentId(fatherId, bucks),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Father',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('No father selected'),
            ),
            for (final rabbit in bucks) _parentItem(rabbit),
          ],
          onChanged: onFatherChanged,
        ),
      ],
    );
  }

  String? _selectedParentId(String? selectedId, List<RabbitSummary> parents) {
    if (selectedId == null) {
      return null;
    }

    return parents.any((rabbit) => rabbit.id == selectedId) ? selectedId : null;
  }

  DropdownMenuItem<String?> _parentItem(RabbitSummary rabbit) {
    final label =
        '${rabbit.identifier}${rabbit.name == null ? '' : ' - ${rabbit.name}'}';

    return DropdownMenuItem(
      value: rabbit.id,
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
