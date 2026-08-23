import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/providers/analytics_provider.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../domain/reminder_entity.dart';
import '../controllers/reminder_controller.dart';

class ReminderFormPage extends ConsumerStatefulWidget {
  const ReminderFormPage({super.key, this.reminder});

  final ReminderEntity? reminder;

  @override
  ConsumerState<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends ConsumerState<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _dueMileage;
  String? _category;
  DateTime? _dueDate;
  bool _notificationEnabled = true;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _title = TextEditingController(text: r?.title ?? '');
    _dueMileage = TextEditingController(text: r?.dueMileage?.toString() ?? '');
    _category = r?.category;
    _dueDate = r?.dueDate;
    _notificationEnabled = r?.notificationEnabled ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _dueMileage.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null && _dueMileage.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        'Informe uma data ou uma quilometragem.',
        isError: true,
      );
      return;
    }

    final vehicle = ref.read(activeVehicleProvider).value;
    if (vehicle == null) {
      showAppSnackBar(context, 'Nenhum veículo ativo.', isError: true);
      return;
    }

    final existing = widget.reminder;
    final entity = ReminderEntity(
      id: existing?.id ?? const Uuid().v4(),
      vehicleId: vehicle.id,
      title: _title.text.trim(),
      category: _category,
      dueDate: _dueDate,
      dueMileage: Validators.parseMileage(_dueMileage.text),
      completed: existing?.completed ?? false,
      notificationEnabled: _notificationEnabled,
    );

    final controller = ref.read(reminderControllerProvider.notifier);
    final saved = _isEditing
        ? await controller.update(entity)
        : await controller.create(entity);

    if (!mounted) return;
    if (saved != null) {
      if (!_isEditing) {
        ref.read(analyticsServiceProvider).reminderCreated();
      }
      context.pop(saved);
    } else {
      final err = ref.read(reminderControllerProvider).error;
      showAppSnackBar(context, handleError(err ?? '').message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(reminderControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar lembrete' : 'Novo lembrete'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => Validators.required(v, 'Título'),
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ex.: Troca de óleo',
                    prefixIcon: Icon(Icons.notifications_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria (opcional)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: AppConstants.maintenanceCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dueMileage,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => Validators.mileage(v, allowEmpty: true),
                  decoration: const InputDecoration(
                    labelText: 'Vencimento por quilometragem',
                    suffixText: 'km',
                    prefixIcon: Icon(Icons.speed_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _dueDate == null
                        ? 'Escolher data de vencimento'
                        : 'Data: ${_formatDate(_dueDate!)}',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _notificationEnabled,
                  onChanged: (v) => setState(() => _notificationEnabled = v),
                  title: const Text('Receber notificações'),
                  subtitle: const Text(
                    'Avisos 30 dias, 7 dias e no dia do vencimento por data.',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar lembrete'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
