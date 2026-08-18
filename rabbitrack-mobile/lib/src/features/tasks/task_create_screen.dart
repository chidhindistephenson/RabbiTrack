import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../home/farm_summary_controller.dart';
import '../locations/location_controller.dart';
import '../locations/location_models.dart';
import '../rabbits/rabbit_controller.dart';
import '../rabbits/rabbit_models.dart';
import '../rabbits/rabbit_options.dart';
import 'task_controller.dart';
import 'task_repository.dart';

class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueOn = DateTime.now();
  TimeOfDay? _dueTime;
  String _priority = 'normal';
  String? _rabbitId;
  String? _locationId;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueOn,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() => _dueOn = picked);
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    final title = _titleController.text.trim();

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        title.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(taskRepositoryProvider)
          .create(
            farmId: farm.id,
            title: title,
            description: _optionalText(_descriptionController),
            dueOn: _dateString(_dueOn),
            dueTime: _timeString(_dueTime),
            priority: _priority,
            rabbitId: _rabbitId,
            locationId: _locationId,
          );

      ref.invalidate(taskListProvider);
      ref.invalidate(taskSummaryProvider);
      ref.invalidate(farmSummaryProvider);
      await syncTaskRemindersForFarm(ref, farm.id);

      if (mounted) {
        showSuccessSnackBar(context, 'Task created.');
        popOrGo(context, '/tasks');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save task. Try again.'),
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

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String? _timeString(TimeOfDay? time) {
    if (time == null) {
      return null;
    }

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final rabbits = ref.watch(rabbitListProvider);
    final locations = ref.watch(locationListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/tasks'),
        title: const Text('Create task'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a task title'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: const Icon(
                  Icons.event,
                  color: RabbiTrackColors.forestGreen,
                ),
                title: const Text('Due date'),
                subtitle: Text(_dateString(_dueOn)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDueDate,
              ),
              const SizedBox(height: 14),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: const Icon(
                  Icons.schedule,
                  color: RabbiTrackColors.forestGreen,
                ),
                title: const Text('Due time'),
                subtitle: Text(_timeString(_dueTime) ?? 'Any time'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (_dueTime != null)
                      IconButton(
                        tooltip: 'Clear time',
                        onPressed: () => setState(() => _dueTime = null),
                        icon: const Icon(Icons.close),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _pickDueTime,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: (value) => setState(() => _priority = value!),
                selectedItemBuilder: (context) => const [
                  Text('Low'),
                  Text('Normal'),
                  Text('High'),
                  Text('Critical'),
                ],
              ),
              const SizedBox(height: 14),
              rabbits.when(
                data: (items) {
                  final activeRabbits = items
                      .where((rabbit) => !isTerminalRabbitStatus(rabbit.status))
                      .toList();

                  return DropdownButtonFormField<String>(
                    initialValue: _rabbitId,
                    decoration: const InputDecoration(
                      labelText: 'Rabbit',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('No rabbit'),
                      ),
                      ...activeRabbits.map(_rabbitItem),
                    ],
                    onChanged: (value) =>
                        setState(() => _rabbitId = value == '' ? null : value),
                  );
                },
                error: (error, stackTrace) => AppState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load rabbits',
                  message: 'You can still save the task without a rabbit.',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(rabbitListProvider),
                  minHeight: 180,
                ),
                loading: () => const LinearProgressIndicator(),
              ),
              const SizedBox(height: 14),
              locations.when(
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _locationId,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('No location'),
                    ),
                    ...items.map(_locationItem),
                  ],
                  onChanged: (value) =>
                      setState(() => _locationId = value == '' ? null : value),
                ),
                error: (error, stackTrace) => AppState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load locations',
                  message: 'You can still save the task without a location.',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(locationListProvider),
                  minHeight: 180,
                ),
                loading: () => const LinearProgressIndicator(),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save task'),
              ),
            ],
          ),
        ),
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

  DropdownMenuItem<String> _locationItem(FarmLocationSummary location) {
    return DropdownMenuItem(
      value: location.id,
      child: Text(
        '${location.name}${location.code == null ? '' : ' - ${location.code}'}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
