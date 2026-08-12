import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/money_format.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../home/farm_summary_controller.dart';
import '../rabbits/rabbit_controller.dart';
import '../rabbits/rabbit_models.dart';
import '../rabbits/rabbit_options.dart';
import 'sale_controller.dart';
import 'sale_repository.dart';

class SaleCreateScreen extends ConsumerStatefulWidget {
  const SaleCreateScreen({super.key, this.initialRabbitId});

  final String? initialRabbitId;

  @override
  ConsumerState<SaleCreateScreen> createState() => _SaleCreateScreenState();
}

class _SaleCreateScreenState extends ConsumerState<SaleCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  String? _rabbitId;
  DateTime _soldOn = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rabbitId = widget.initialRabbitId;
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    final price = double.tryParse(_priceController.text);

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        _rabbitId == null ||
        price == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(saleRepositoryProvider)
          .create(
            farmId: farm.id,
            rabbitId: _rabbitId!,
            salePrice: price,
            soldOn: _dateValue(_soldOn),
            buyerName: _optionalText(_buyerNameController),
            buyerPhone: _optionalText(_buyerPhoneController),
            notes: _optionalText(_notesController),
          );

      ref.invalidate(saleListProvider);
      ref.invalidate(rabbitSaleListProvider(_rabbitId!));
      ref.invalidate(saleReportProvider);
      ref.invalidate(rabbitListProvider);
      ref.invalidate(rabbitDetailProvider(_rabbitId!));
      ref.invalidate(farmSummaryProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Sale recorded.');
        popOrGo(
          context,
          widget.initialRabbitId == null ? '/sales' : '/rabbits/$_rabbitId',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(
            error,
            'Could not save sale. Check the rabbit and price.',
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

  Future<void> _pickSoldOn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _soldOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _soldOn = picked);
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
    final lockedRabbit = widget.initialRabbitId == null
        ? null
        : ref.watch(rabbitDetailProvider(widget.initialRabbitId!));
    final currency =
        ref.watch(authControllerProvider).valueOrNull?.selectedFarm?.currency ??
        'USD';

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: widget.initialRabbitId == null
              ? '/sales'
              : '/rabbits/${widget.initialRabbitId}',
        ),
        title: const Text('Record sale'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: rabbits.when(
        data: (items) {
          final saleableRabbits = items.where(_isSaleEligible).toList();
          final selectedIsSaleable =
              _rabbitId != null &&
              saleableRabbits.any((rabbit) => rabbit.id == _rabbitId);
          final dropdownRabbits = [
            ...saleableRabbits,
            if (_rabbitId != null && !selectedIsSaleable)
              ...items.where((rabbit) => rabbit.id == _rabbitId),
          ];

          if (dropdownRabbits.isEmpty) {
            return AppState(
              icon: Icons.sell_outlined,
              title: 'No rabbits available for sale',
              message:
                  'Add a rabbit or update an existing rabbit to a saleable status before recording a sale.',
              actionLabel: 'Add rabbit',
              actionIcon: Icons.add,
              onAction: () => popOrGo(context, '/rabbits/new'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                lockedRabbit?.when(
                      data: (item) => _SaleTargetCard(
                        title:
                            '${item.identifier}${item.name == null ? '' : ' - ${item.name}'}',
                        isSaleable: selectedIsSaleable,
                      ),
                      error: (error, stackTrace) => AppState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load rabbit',
                        message: 'Check the API server and try again.',
                        actionLabel: 'Retry',
                        onAction: () =>
                            ref.invalidate(rabbitDetailProvider(_rabbitId!)),
                        minHeight: 180,
                      ),
                      loading: () => const LinearProgressIndicator(),
                    ) ??
                    DropdownButtonFormField<String>(
                      initialValue: _rabbitId,
                      decoration: const InputDecoration(
                        labelText: 'Rabbit',
                        border: OutlineInputBorder(),
                        helperText: 'Sold and closed rabbits are hidden.',
                      ),
                      isExpanded: true,
                      items: dropdownRabbits.map(_rabbitItem).toList(),
                      onChanged: (value) => setState(() => _rabbitId = value),
                      validator: (value) {
                        if (value == null) {
                          return 'Select a rabbit';
                        }
                        if (!saleableRabbits.any(
                          (rabbit) => rabbit.id == value,
                        )) {
                          return 'Choose a rabbit that can be sold';
                        }

                        return null;
                      },
                    ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Sale price',
                    prefixText: '${currencySymbol(currency)} ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: _moneyValidator,
                ),
                const SizedBox(height: 14),
                _DateField(
                  label: 'Sale date',
                  value: _dateValue(_soldOn),
                  onTap: _pickSoldOn,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _buyerNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Buyer name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _buyerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Buyer phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed:
                      _isSaving || _rabbitId == null || !selectedIsSaleable
                      ? null
                      : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save sale'),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load rabbits',
          message: 'Check the API server and try again.',
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
        [
          '${rabbit.identifier}${rabbit.name == null ? '' : ' - ${rabbit.name}'}',
          if (!_isSaleEligible(rabbit)) rabbitStatusLabel(rabbit.status),
        ].join(' | '),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  bool _isSaleEligible(RabbitSummary rabbit) {
    return !{'sold', 'retired', 'deceased', 'culled'}.contains(rabbit.status);
  }

  String? _moneyValidator(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null) {
      return 'Enter a sale price';
    }
    if (amount <= 0) {
      return 'Sale price must be greater than zero';
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

class _SaleTargetCard extends StatelessWidget {
  const _SaleTargetCard({required this.title, required this.isSaleable});

  final String title;
  final bool isSaleable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSaleable ? RabbiTrackColors.mintGreen : RabbiTrackColors.cream,
        borderRadius: BorderRadius.circular(8),
        border: isSaleable ? null : Border.all(color: RabbiTrackColors.warmTan),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSaleable ? Icons.sell_outlined : Icons.info_outline,
            color: RabbiTrackColors.forestGreen,
          ),
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
                  isSaleable
                      ? 'Sale will be recorded for this rabbit.'
                      : 'This rabbit cannot be sold from its current status.',
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
