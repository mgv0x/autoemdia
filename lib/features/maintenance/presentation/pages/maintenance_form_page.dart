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
import '../../../reminders/domain/reminder_entity.dart';
import '../../../reminders/presentation/controllers/reminder_controller.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../domain/maintenance_entity.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceFormPage extends ConsumerStatefulWidget {
  const MaintenanceFormPage({super.key, this.maintenance});

  final MaintenanceEntity? maintenance;

  @override
  ConsumerState<MaintenanceFormPage> createState() =>
      _MaintenanceFormPageState();
}

class _MaintenanceFormPageState extends ConsumerState<MaintenanceFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _description;
  late final TextEditingController _mileage;
  late final TextEditingController _cost;
  late final TextEditingController _notes;
  late final TextEditingController _nextMileage;

  String? _category;
  DateTime _serviceDate = DateTime.now();
  DateTime? _nextDate;

  bool _showMileageLowerWarning = false;
  bool get _isEditing => widget.maintenance != null;

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    _category = m?.category;
    _description = TextEditingController(text: m?.description ?? '');
    _mileage = TextEditingController(text: m?.mileage?.toString() ?? '');
    _cost = TextEditingController(
      text: m?.cost == null ? '' : m!.cost!.toStringAsFixed(2),
    );
    _notes = TextEditingController(text: m?.notes ?? '');
    _nextMileage = TextEditingController(
      text: m?.nextMileage?.toString() ?? '',
    );
    _serviceDate = m?.serviceDate ?? DateTime.now();
    _nextDate = m?.nextDate;
  }

  @override
  void dispose() {
    _description.dispose();
    _mileage.dispose();
    _cost.dispose();
    _notes.dispose();
    _nextMileage.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isNext}) async {
    final initial = isNext ? (_nextDate ?? DateTime.now()) : _serviceDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isNext ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        if (isNext) {
          _nextDate = picked;
        } else {
          _serviceDate = picked;
        }
      });
    }
  }

  Future<void> _submit({bool confirmedLowerKm = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final vehicleAsync = ref.read(activeVehicleProvider);
    final vehicle = vehicleAsync.value;
    if (vehicle == null) {
      showAppSnackBar(context, 'Nenhum veículo ativo.', isError: true);
      return;
    }

    final mileage = Validators.parseMileage(_mileage.text);
    // Regra: impedir quilometragem menor que a atual sem confirmação.
    if (mileage != null &&
        mileage < vehicle.currentMileage &&
        !confirmedLowerKm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quilometragem menor'),
          content: Text(
            'A quilometragem informada (${mileage} km) é menor que a atual '
            '(${vehicle.currentMileage} km). Deseja continuar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      return _submit(confirmedLowerKm: true);
    }

    final existing = widget.maintenance;
    final entity = MaintenanceEntity(
      id: existing?.id ?? const Uuid().v4(),
      vehicleId: vehicle.id,
      category: _category ?? 'Outros',
      description: _description.text.trim(),
      serviceDate: _serviceDate,
      mileage: mileage,
      cost: Validators.parseMoney(_cost.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      nextMileage: Validators.parseMileage(_nextMileage.text),
      nextDate: _nextDate,
    );

    final controller = ref.read(maintenanceFormControllerProvider.notifier);
    final saved = _isEditing
        ? await controller.update(entity)
        : await controller.create(entity);

    if (!mounted) return;

    if (saved != null) {
      // Se informou próxima manutenção (data ou km), gera lembrete automático.
      if (saved.nextMileage != null || saved.nextDate != null) {
        await _createAutoReminder(saved);
      }
      if (saved.mileage != null && saved.mileage! > vehicle.currentMileage) {
        await ref
            .read(vehicleFormControllerProvider.notifier)
            .updateMileage(vehicle.id, saved.mileage!);
      }
      ref.read(analyticsServiceProvider).maintenanceCreated();
      context.pop(saved);
    } else {
      final err = ref.read(maintenanceFormControllerProvider).error;
      showAppSnackBar(context, handleError(err ?? '').message, isError: true);
    }
  }

  Future<void> _createAutoReminder(MaintenanceEntity m) async {
    final reminder = ReminderEntity(
      id: const Uuid().v4(),
      vehicleId: m.vehicleId,
      title: '${m.category}: ${m.description}',
      category: m.category,
      dueDate: m.nextDate,
      dueMileage: m.nextMileage,
    );
    await ref.read(reminderControllerProvider.notifier).create(reminder);
    ref.read(analyticsServiceProvider).reminderCreated();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final loading = ref.watch(maintenanceFormControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar manutenção' : 'Nova manutenção'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: AppConstants.maintenanceCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) =>
                      v == null ? 'Selecione uma categoria.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => Validators.required(v, 'Descrição'),
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: Troca de óleo',
                    prefixIcon: Icon(Icons.build_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isNext: false),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          'Data: ${_formatDate(_serviceDate)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mileage,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => Validators.mileage(v, allowEmpty: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Quilometragem no serviço',
                    suffixText: 'km',
                    prefixIcon: Icon(Icons.speed_outlined),
                  ),
                ),
                if (_showMileageLowerWarning)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'A quilometragem é menor que a atual.',
                      style: text.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => Validators.money(v, allowEmpty: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Próxima manutenção',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nextMileage,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => Validators.mileage(v, allowEmpty: true),
                  decoration: const InputDecoration(
                    labelText: 'Por quilometragem',
                    hintText: 'Ex.: 100000',
                    suffixText: 'km',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(isNext: true),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: Text(
                    _nextDate == null
                        ? 'Escolher data da próxima manutenção'
                        : 'Data: ${_formatDate(_nextDate!)}',
                  ),
                ),
                if (_nextMileage.text.isNotEmpty || _nextDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Um lembrete será criado automaticamente.',
                      style: text.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: loading ? null : () => _submit(),
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar manutenção'),
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
