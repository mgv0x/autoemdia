import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../../../../core/services/ad_manager.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/providers/analytics_provider.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../../vehicle/domain/vehicle_type_config.dart';
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
  late final TextEditingController _recurrenceKm;
  String? _category;
  DateTime? _dueDate;
  bool _notificationEnabled = true;
  bool _isRecurring = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _title = TextEditingController(text: r?.title ?? '');
    _dueMileage = TextEditingController(text: r?.dueMileage?.toString() ?? '');
    _recurrenceKm = TextEditingController(
      text: r?.recurrenceKm?.toString() ?? '',
    );
    _category = r?.category;
    _dueDate = r?.dueDate;
    _notificationEnabled = r?.notificationEnabled ?? true;
    _isRecurring = r?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _dueMileage.dispose();
    _recurrenceKm.dispose();
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

  void _applySuggestion(
    MaintenanceIntervalSuggestion s,
    int currentMileage,
  ) {
    setState(() {
      _title.text = s.title;
      _category = s.category;
      if (s.intervalKm != null) {
        _dueMileage.text = (currentMileage + s.intervalKm!).toString();
        _recurrenceKm.text = s.intervalKm.toString();
        _isRecurring = true;
      }
      if (s.intervalMonths != null) {
        _dueDate = DateTime.now().add(Duration(days: s.intervalMonths! * 30));
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null && _dueMileage.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        'Informe uma data ou uma quilometragem de vencimento.',
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
    final recurrenceKmVal = _isRecurring
        ? Validators.parseMileage(_recurrenceKm.text)
        : null;

    final entity = ReminderEntity(
      id: existing?.id ?? const Uuid().v4(),
      vehicleId: vehicle.id,
      title: _title.text.trim(),
      category: _category,
      type: _isRecurring ? ReminderType.recurring : ReminderType.mileage,
      dueDate: _dueDate,
      dueMileage: Validators.parseMileage(_dueMileage.text),
      recurrenceKm: recurrenceKmVal,
      completed: existing?.completed ?? false,
      notificationEnabled: _notificationEnabled,
      sourceMaintenanceId: existing?.sourceMaintenanceId,
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
      final isPremium = ref.read(isPremiumProvider).value ?? false;
      context.pop(saved);
      AdManager.showInterstitialOnActionCompleted(
        origin: 'reminder_form_saved',
        isPremium: isPremium,
      );
    } else {
      final err = ref.read(reminderControllerProvider).error;
      showAppSnackBar(context, handleError(err ?? '').message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(activeVehicleProvider).value;
    final config = vehicle != null
        ? VehicleTypeConfig.of(vehicle.type)
        : VehicleTypeConfig.carConfig;
    final currentKm = vehicle?.currentMileage ?? 0;

    final loading = ref.watch(reminderControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar cuidado' : 'Novo cuidado'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carrossel de Sugestões Contextuais (Moto / Carro)
                if (!_isEditing && config.intervalSuggestions.isNotEmpty) ...[
                  Text(
                    'Sugestões para ${config.label.toLowerCase()}:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: config.intervalSuggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final s = config.intervalSuggestions[i];
                        return ActionChip(
                          avatar: Icon(
                            config.icon,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          label: Text('${s.title} (${s.summary})'),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppTheme.borderSubtleColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () => _applySuggestion(s, currentKm),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 1. Título
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => Validators.required(v, 'Título'),
                  decoration: InputDecoration(
                    labelText: 'Título do cuidado',
                    hintText: config.serviceDescriptionHint,
                    prefixIcon: const Icon(Icons.notifications_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Categoria (específica de Carro ou Moto)
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: config.maintenanceCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 16),

                // 3. Vencimento por Km
                TextFormField(
                  controller: _dueMileage,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => Validators.mileage(v, allowEmpty: true),
                  decoration: InputDecoration(
                    labelText: 'Vencimento por quilometragem',
                    hintText: currentKm > 0
                        ? 'Atual: $currentKm km'
                        : 'Ex.: 50000',
                    suffixText: 'km',
                    prefixIcon: const Icon(Icons.speed_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Vencimento por Data
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _dueDate == null
                        ? 'Definir data limite de vencimento'
                        : 'Data: ${_formatDate(_dueDate!)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Opção de Recorrência
                SwitchListTile(
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                  title: const Text('Cuidado recorrente'),
                  subtitle: const Text(
                    'Gera automaticamente o próximo ciclo ao concluir este cuidado.',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _recurrenceKm,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => Validators.mileage(v, allowEmpty: true),
                    decoration: const InputDecoration(
                      labelText: 'Repetir a cada (km)',
                      hintText: 'Ex.: 500, 3000, 10000',
                      suffixText: 'km',
                      prefixIcon: Icon(Icons.replay_rounded),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 6. Notificações
                SwitchListTile(
                  value: _notificationEnabled,
                  onChanged: (v) => setState(() => _notificationEnabled = v),
                  title: const Text('Receber notificações'),
                  subtitle: const Text(
                    'Avisos prévios antes do vencimento por data ou quilometragem.',
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
                      : Text(_isEditing ? 'Atualizar cuidado' : 'Salvar cuidado'),
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
