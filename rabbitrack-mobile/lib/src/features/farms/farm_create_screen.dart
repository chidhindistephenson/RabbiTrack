import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'farm_currency_options.dart';
import 'farm_repository.dart';

class FarmCreateScreen extends ConsumerStatefulWidget {
  const FarmCreateScreen({super.key});

  @override
  ConsumerState<FarmCreateScreen> createState() => _FarmCreateScreenState();
}

class _FarmCreateScreenState extends ConsumerState<FarmCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _currency = defaultFarmCurrency;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    final name = _nameController.text.trim();

    if (_formKey.currentState?.validate() != true ||
        session == null ||
        name.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final farm = await ref
          .read(farmRepositoryProvider)
          .create(name: name, currency: _currency);

      await ref.read(authControllerProvider.notifier).addAndSelectFarm(farm);

      if (mounted) {
        showSuccessSnackBar(context, 'Farm created.');
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not create farm.'),
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
    final session = ref.watch(authControllerProvider).valueOrNull;

    if (session == null) {
      return const Scaffold(
        body: AppState(
          icon: Icons.lock_outline,
          title: 'Please sign in',
          message: 'Sign in before creating a farm.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create farm'),
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
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create farm'),
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
