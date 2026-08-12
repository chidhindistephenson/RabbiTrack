import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/money_format.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../home/farm_summary_controller.dart';
import 'expense_controller.dart';
import 'expense_options.dart';
import 'expense_repository.dart';

class ExpenseCreateScreen extends ConsumerStatefulWidget {
  const ExpenseCreateScreen({super.key});

  @override
  ConsumerState<ExpenseCreateScreen> createState() =>
      _ExpenseCreateScreenState();
}

class _ExpenseCreateScreenState extends ConsumerState<ExpenseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'feed';
  DateTime _spentOn = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    final amount = double.tryParse(_amountController.text);

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        amount == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(expenseRepositoryProvider)
          .create(
            farmId: farm.id,
            category: _category,
            amount: amount,
            spentOn: _dateValue(_spentOn),
            vendor: _optionalText(_vendorController),
            notes: _optionalText(_notesController),
          );

      ref.invalidate(expenseListProvider);
      ref.invalidate(expenseReportProvider);
      ref.invalidate(farmSummaryProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Expense recorded.');
        popOrGo(context, '/expenses');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save expense. Check the amount.'),
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

  Future<void> _pickSpentOn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _spentOn = picked);
    }
  }

  String _dateValue(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        ref.watch(authControllerProvider).valueOrNull?.selectedFarm?.currency ??
        'USD';

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/expenses'),
        title: const Text('Record expense'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: expenseCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(expenseCategoryLabel(category)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${currencySymbol(currency)} ',
                border: const OutlineInputBorder(),
              ),
              validator: _moneyValidator,
            ),
            const SizedBox(height: 14),
            _DateField(
              label: 'Expense date',
              value: _dateValue(_spentOn),
              onTap: _pickSpentOn,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _vendorController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Vendor',
                border: OutlineInputBorder(),
              ),
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
                  : const Text('Save expense'),
            ),
          ],
        ),
      ),
    );
  }

  String? _moneyValidator(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null) {
      return 'Enter an amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    return null;
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
