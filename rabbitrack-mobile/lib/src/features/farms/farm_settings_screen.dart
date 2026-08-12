import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'farm_currency_options.dart';
import 'farm_repository.dart';

class FarmSettingsScreen extends ConsumerStatefulWidget {
  const FarmSettingsScreen({super.key});

  @override
  ConsumerState<FarmSettingsScreen> createState() => _FarmSettingsScreenState();
}

class _FarmSettingsScreenState extends ConsumerState<FarmSettingsScreen> {
  static const _timezones = [
    'Africa/Johannesburg',
    'Africa/Harare',
    'Africa/Lusaka',
    'Africa/Maputo',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _currency = defaultFarmCurrency;
  String _timezone = 'Africa/Johannesburg';
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    final name = _nameController.text.trim();

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        name.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedFarm = await ref
          .read(farmRepositoryProvider)
          .update(
            farmId: farm.id,
            name: name,
            currency: _currency,
            timezone: _timezone,
          );

      ref.read(authControllerProvider.notifier).replaceFarm(updatedFarm);

      if (mounted) {
        showSuccessSnackBar(context, 'Farm settings saved.');
        popOrGo(context, '/more');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save farm settings.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _initializeFields() {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (_initialized || farm == null) {
      return;
    }

    _nameController.text = farm.name;
    _currency = supportedFarmCurrencyOrDefault(farm.currency);
    _timezone = _timezones.contains(farm.timezone)
        ? farm.timezone
        : 'Africa/Johannesburg';
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initializeFields();
    final farm = ref.watch(authControllerProvider).valueOrNull?.selectedFarm;

    if (farm == null) {
      return const Scaffold(
        body: AppState(
          icon: Icons.home_work_outlined,
          title: 'Select a farm first',
          message: 'Choose a farm before editing farm settings.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/more'),
        title: const Text('Farm settings'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Farm name',
                border: OutlineInputBorder(),
              ),
              validator: _farmNameValidator,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                helperText: 'All money amounts display with the dollar symbol.',
                border: OutlineInputBorder(),
              ),
              items: supportedFarmCurrencies
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(farmCurrencyLabel(currency)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currency = value);
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _timezone,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(),
              ),
              items: _timezones
                  .map(
                    (timezone) => DropdownMenuItem(
                      value: timezone,
                      child: Text(timezone),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _timezone = value!),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save settings'),
            ),
          ],
        ),
      ),
    );
  }

  String? _farmNameValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Enter a farm name' : null;
  }
}
