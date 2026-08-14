import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../locations/location_controller.dart';
import '../locations/location_models.dart';
import '../litters/litter_controller.dart';
import '../litters/litter_models.dart';
import 'rabbit_controller.dart';
import 'rabbit_models.dart';
import 'rabbit_options.dart';
import 'rabbit_repository.dart';

class RabbitCreateScreen extends ConsumerStatefulWidget {
  const RabbitCreateScreen({super.key});

  @override
  ConsumerState<RabbitCreateScreen> createState() => _RabbitCreateScreenState();
}

class _RabbitCreateScreenState extends ConsumerState<RabbitCreateScreen> {
  static const _customBreedValue = '__custom__';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customBreedController = TextEditingController();
  final _colourController = TextEditingController();
  final _weightController = TextEditingController();
  final _tagController = TextEditingController();
  final _supplierController = TextEditingController();
  final _acquisitionCostController = TextEditingController();
  final _notesController = TextEditingController();
  String _originType = 'existing_stock';
  String _sex = 'female';
  String _status = 'growing';
  String _weightUnit = 'kg';
  String? _breed;
  String? _locationId;
  String? _originLitterId;
  String? _motherId;
  String? _fatherId;
  DateTime? _dateOfBirth;
  DateTime? _acquiredAt;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _customBreedController.dispose();
    _colourController.dispose();
    _weightController.dispose();
    _tagController.dispose();
    _supplierController.dispose();
    _acquisitionCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final originLitter = _selectedOriginLitter();
      final rabbit = await ref
          .read(rabbitRepositoryProvider)
          .create(
            farmId: farm.id,
            name: _emptyToNull(_nameController.text),
            sex: _sex,
            status: _status,
            breed: _selectedBreed(),
            colour: _emptyToNull(_colourController.text),
            currentLocationId: _locationId,
            dateOfBirth: _originType == 'born_on_farm'
                ? originLitter?.kindledOn
                : _formattedDate(_dateOfBirth),
            weightValue: _emptyToNull(_weightController.text),
            weightUnit: _emptyToNull(_weightController.text) == null
                ? null
                : _weightUnit,
            tagOrTattoo: _emptyToNull(_tagController.text),
            notes: _emptyToNull(_notesController.text),
            motherId: _originType == 'born_on_farm'
                ? originLitter?.doeId
                : _motherId,
            fatherId: _originType == 'born_on_farm'
                ? originLitter?.buckId
                : _fatherId,
            originType: _originType,
            originLitterId: _originType == 'born_on_farm'
                ? _originLitterId
                : null,
            supplier: _showsSourceFields
                ? _emptyToNull(_supplierController.text)
                : null,
            acquiredAt: _showsSourceFields ? _formattedDate(_acquiredAt) : null,
            acquisitionCost: _originType == 'purchased'
                ? _emptyToNull(_acquisitionCostController.text)
                : null,
          );

      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Rabbit ${rabbit.identifier} created.');
        popOrGo(context, '/rabbits');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save rabbit. Try again.'),
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
    final locations = ref.watch(locationListProvider);
    final rabbits = ref.watch(rabbitParentOptionsProvider);
    final litters = ref.watch(litterListProvider);
    final statusOptions = editableRabbitStatusesForSex(_sex);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/rabbits'),
        title: const Text('Register rabbit'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RabbiTrackColors.mintGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: RabbiTrackColors.forestGreen,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rabbit ID will be assigned automatically after saving.',
                        style: TextStyle(
                          color: RabbiTrackColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _originType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Origin',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'existing_stock',
                    child: Text('Existing stock'),
                  ),
                  DropdownMenuItem(
                    value: 'born_on_farm',
                    child: Text('Born on this farm'),
                  ),
                  DropdownMenuItem(
                    value: 'purchased',
                    child: Text('Purchased'),
                  ),
                  DropdownMenuItem(
                    value: 'transferred_in',
                    child: Text('Transferred in'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _originType = value!;
                    _originLitterId = null;
                    if (_originType != 'existing_stock') {
                      _motherId = null;
                      _fatherId = null;
                    }
                    if (!_showsSourceFields) {
                      _supplierController.clear();
                      _acquisitionCostController.clear();
                      _acquiredAt = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_originType == 'born_on_farm') ...[
                litters.when(
                  data: (items) => _LitterOriginField(
                    litters: items,
                    selectedLitterId: _originLitterId,
                    onChanged: (value) =>
                        setState(() => _originLitterId = value),
                  ),
                  error: (error, stackTrace) =>
                      const Text('Litters could not be loaded.'),
                  loading: () => const LinearProgressIndicator(),
                ),
                const SizedBox(height: 12),
              ],
              if (_showsSourceFields) ...[
                TextFormField(
                  controller: _supplierController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _originType == 'purchased'
                        ? 'Seller or supplier'
                        : 'Previous farm or source',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_emptyToNull(value ?? '') == null) {
                      return _originType == 'purchased'
                          ? 'Enter the seller or supplier'
                          : 'Enter the previous farm or source';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _formattedDate(_acquiredAt) ?? '',
                  ),
                  decoration: InputDecoration(
                    labelText: _originType == 'purchased'
                        ? 'Purchase date'
                        : 'Transfer date',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Select date',
                      onPressed: _pickAcquiredAt,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  onTap: _pickAcquiredAt,
                ),
                const SizedBox(height: 12),
                if (_originType == 'purchased') ...[
                  TextFormField(
                    controller: _acquisitionCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Purchase price',
                      prefixText: r'$ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final trimmed = _emptyToNull(value ?? '');
                      if (trimmed == null) {
                        return null;
                      }

                      final parsed = num.tryParse(trimmed);
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid price';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_originType != 'born_on_farm') ...[
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
              ],
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
                    if (!editableRabbitStatusesForSex(_sex).contains(_status)) {
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
              locations.when(
                data: (items) => DropdownButtonFormField<String?>(
                  initialValue: _locationId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No location'),
                    ),
                    ...items.map(_locationItem),
                  ],
                  onChanged: (value) => setState(() => _locationId = value),
                ),
                error: (error, stackTrace) =>
                    const Text('Locations could not be loaded.'),
                loading: () => const LinearProgressIndicator(),
              ),
              const SizedBox(height: 12),
              if (_originType == 'existing_stock') ...[
                rabbits.when(
                  data: (items) => _ParentFields(
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
              ],
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
                  labelText: 'Existing physical mark',
                  helperText:
                      'Leave blank to use the assigned Rabbit ID on the animal.',
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
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save rabbit'),
              ),
            ],
          ),
        ),
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

  bool get _showsSourceFields {
    return _originType == 'purchased' || _originType == 'transferred_in';
  }

  LitterSummary? _selectedOriginLitter() {
    final litters = ref.read(litterListProvider).valueOrNull;
    if (litters == null || _originLitterId == null) {
      return null;
    }

    for (final litter in litters) {
      if (litter.id == _originLitterId) {
        return litter;
      }
    }

    return null;
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

  Future<void> _pickAcquiredAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _acquiredAt ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );

    if (picked == null) {
      return;
    }

    setState(() => _acquiredAt = picked);
  }

  DropdownMenuItem<String?> _locationItem(FarmLocationSummary location) {
    return DropdownMenuItem(
      value: location.id,
      child: Text(
        '${location.name}${location.code == null ? '' : ' - ${location.code}'}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _LitterOriginField extends StatelessWidget {
  const _LitterOriginField({
    required this.litters,
    required this.selectedLitterId,
    required this.onChanged,
  });

  final List<LitterSummary> litters;
  final String? selectedLitterId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final convertibleLitters = litters
        .where(
          (litter) =>
              litter.status == 'weaned' || litter.status == 'partially_weaned',
        )
        .toList();

    return DropdownButtonFormField<String?>(
      initialValue: selectedLitterId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Litter / kindling record',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Select weaned litter'),
        ),
        for (final litter in convertibleLitters)
          DropdownMenuItem(
            value: litter.id,
            child: Text(_litterLabel(litter), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: (value) =>
          value == null ? 'Select the litter this rabbit came from' : null,
    );
  }

  String _litterLabel(LitterSummary litter) {
    final buck = litter.buckIdentifier == null
        ? ''
        : ' x ${litter.buckIdentifier}';

    return '${litter.identifier} - ${litter.doeIdentifier}$buck';
  }
}

class _ParentFields extends StatelessWidget {
  const _ParentFields({
    required this.rabbits,
    required this.motherId,
    required this.fatherId,
    required this.onMotherChanged,
    required this.onFatherChanged,
  });

  final List<RabbitSummary> rabbits;
  final String? motherId;
  final String? fatherId;
  final ValueChanged<String?> onMotherChanged;
  final ValueChanged<String?> onFatherChanged;

  @override
  Widget build(BuildContext context) {
    final activeRabbits = rabbits
        .where((rabbit) => !isTerminalRabbitStatus(rabbit.status))
        .toList();
    final does = activeRabbits
        .where((rabbit) => rabbit.sex == 'female')
        .toList();
    final bucks = activeRabbits
        .where((rabbit) => rabbit.sex == 'male')
        .toList();

    return Column(
      children: [
        DropdownButtonFormField<String?>(
          initialValue: motherId,
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
          initialValue: fatherId,
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

  DropdownMenuItem<String?> _parentItem(RabbitSummary rabbit) {
    final label =
        '${rabbit.identifier}${rabbit.name == null ? '' : ' - ${rabbit.name}'}';

    return DropdownMenuItem(
      value: rabbit.id,
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
