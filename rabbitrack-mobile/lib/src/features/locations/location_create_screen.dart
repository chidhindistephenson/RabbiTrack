import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../rabbits/rabbit_controller.dart';
import 'location_controller.dart';
import 'location_options.dart';
import 'location_repository.dart';

class LocationCreateScreen extends ConsumerStatefulWidget {
  const LocationCreateScreen({super.key});

  @override
  ConsumerState<LocationCreateScreen> createState() =>
      _LocationCreateScreenState();
}

class _LocationCreateScreenState extends ConsumerState<LocationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'cage';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    final name = _nameController.text.trim();
    final capacity = int.tryParse(_capacityController.text);

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        name.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(locationRepositoryProvider)
          .create(
            farmId: farm.id,
            type: _type,
            name: name,
            code: _optionalText(_codeController),
            capacity: capacity,
            notes: _optionalText(_notesController),
          );

      ref.invalidate(locationListProvider);
      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Location created.');
        popOrGo(context, '/locations');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save location. Try again.'),
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
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/locations'),
        title: const Text('Create location'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LocationCreateGuidance(type: _type),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in locationTypes)
                    DropdownMenuItem(
                      value: type,
                      child: Text(locationTypeLabel(type)),
                    ),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a location name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  helperText: 'Optional',
                  border: OutlineInputBorder(),
                ),
                validator: _capacityValidator,
              ),
              const SizedBox(height: 4),
              Text(
                locationCapacityGuidance(_type),
                style: const TextStyle(color: RabbiTrackColors.sageGreen),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
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
                    : const Text('Save location'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _capacityValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final capacity = int.tryParse(trimmed);
    if (capacity == null || capacity <= 0) {
      return 'Capacity must be greater than zero';
    }

    return null;
  }
}

class _LocationCreateGuidance extends StatelessWidget {
  const _LocationCreateGuidance({required this.type});

  final String type;

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
            Icons.meeting_room_outlined,
            color: RabbiTrackColors.forestGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${locationTypeLabel(type)} setup',
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  locationTypeGuidance(type),
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
