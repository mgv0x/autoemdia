import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/services/ad_manager.dart';
import '../../../../../shared/providers/analytics_provider.dart';
import '../../../reminders/domain/reminder_entity.dart';
import '../../../reminders/presentation/controllers/reminder_controller.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../../vehicle/domain/vehicle_type_config.dart';
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
  late final TextEditingController _part;
  late final TextEditingController _workshop;
  late final TextEditingController _notes;
  late final TextEditingController _nextMileage;

  String? _category;
  DateTime _serviceDate = DateTime.now();
  DateTime? _nextDate;
  bool _detailsExpanded = false;

  bool get _isEditing => widget.maintenance != null;
  bool get _showMileageLowerWarning {
    final vehicle = ref.watch(activeVehicleProvider).value;
    if (vehicle == null) return false;
    final km = Validators.parseMileage(_mileage.text);
    return km != null && km < vehicle.currentMileage;
  }

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
    _part = TextEditingController(text: m?.part ?? '');
    _workshop = TextEditingController(text: m?.workshop ?? '');
    _notes = TextEditingController(text: m?.notes ?? '');
    _nextMileage = TextEditingController(
      text: m?.nextMileage?.toString() ?? '',
    );
    _serviceDate = m?.serviceDate ?? DateTime.now();
    _nextDate = m?.nextDate;

    // Se já havia dados em detalhes, iniciar expandido na edição
    if (m != null &&
        ((m.part != null && m.part!.isNotEmpty) ||
            (m.workshop != null && m.workshop!.isNotEmpty) ||
            (m.notes != null && m.notes!.isNotEmpty) ||
            m.nextMileage != null ||
            m.nextDate != null)) {
      _detailsExpanded = true;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _mileage.dispose();
    _cost.dispose();
    _part.dispose();
    _workshop.dispose();
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
    // Regra: impedir quilometragem menor que a atual sem confirmação explícita
    if (mileage != null &&
        mileage < vehicle.currentMileage &&
        !confirmedLowerKm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quilometragem menor'),
          content: Text(
            'A quilometragem informada ($mileage km) é menor que a atual '
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
      part: _part.text.trim().isEmpty ? null : _part.text.trim(),
      workshop: _workshop.text.trim().isEmpty ? null : _workshop.text.trim(),
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
      // Se informou próxima manutenção (data ou km), gera lembrete automático vinculado
      if (saved.nextMileage != null || saved.nextDate != null) {
        await _createAutoReminder(saved);
      }
      if (saved.mileage != null && saved.mileage! > vehicle.currentMileage) {
        await ref
            .read(vehicleFormControllerProvider.notifier)
            .updateMileage(vehicle.id, saved.mileage!);
      }
      ref.read(analyticsServiceProvider).maintenanceCreated();
      if (!mounted) return;
      final isPremium = ref.read(isPremiumProvider).value ?? false;
      context.pop(saved);
      AdManager.showInterstitialOnActionCompleted(
        origin: 'maintenance_form_saved',
        isPremium: isPremium,
      );
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
      sourceMaintenanceId: m.id,
    );
    await ref.read(reminderControllerProvider.notifier).create(reminder);
    ref.read(analyticsServiceProvider).reminderCreated();
  }

  void _applySuggestion(
    MaintenanceIntervalSuggestion s,
    int currentMileage,
  ) {
    setState(() {
      _description.text = s.title;
      _category = s.category;
      if (s.intervalKm != null) {
        _nextMileage.text = (currentMileage + s.intervalKm!).toString();
        _detailsExpanded = true;
      }
      if (s.intervalMonths != null) {
        _nextDate = DateTime.now().add(Duration(days: s.intervalMonths! * 30));
        _detailsExpanded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final loading = ref.watch(maintenanceFormControllerProvider).isLoading;
    final vehicle = ref.watch(activeVehicleProvider).value;
    final config = vehicle != null
        ? VehicleTypeConfig.of(vehicle.type)
        : VehicleTypeConfig.carConfig;
    final currentKm = vehicle?.currentMileage ?? 0;
    final availableCategories =
        config.maintenanceCategories.contains(_category) || _category == null
            ? config.maintenanceCategories
            : [_category!, ...config.maintenanceCategories];

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
                // Sugestões Contextuais (Moto / Carro)
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

                // 1. Categoria
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: availableCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) =>
                      v == null ? 'Selecione uma categoria.' : null,
                ),
                const SizedBox(height: 16),

                // 2. Descrição
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => Validators.required(v, 'Descrição'),
                  decoration: InputDecoration(
                    labelText: 'Descrição do serviço',
                    hintText: config.serviceDescriptionHint,
                    prefixIcon: const Icon(Icons.build_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Data do serviço
                OutlinedButton.icon(
                  onPressed: () => _pickDate(isNext: false),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    'Data: ${_formatDate(_serviceDate)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Quilometragem no serviço
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
                      'Atenção: quilometragem menor que a atual registrada.',
                      style: text.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // 5. Valor
                TextFormField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => Validators.money(v, allowEmpty: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor total (R\$)',
                    hintText: '0,00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 20),

                // Divisor com Progressive Disclosure: Mais detalhes
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: _detailsExpanded,
                    onExpansionChanged: (expanded) =>
                        setState(() => _detailsExpanded = expanded),
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Mais detalhes (opcional)',
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 8),

                      // Peça / Marca / Componente
                      TextFormField(
                        controller: _part,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Marca / Peça utilizada',
                          hintText: config.partHint,
                          prefixIcon: const Icon(Icons.settings_suggest_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Oficina / Prestador
                      TextFormField(
                        controller: _workshop,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Oficina / Estabelecimento',
                          hintText: config.workshopHint,
                          prefixIcon: const Icon(Icons.storefront_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Observações
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Observações adicionais',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Seção Próxima manutenção
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Agendar próxima manutenção',
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nextMileage,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            Validators.mileage(v, allowEmpty: true),
                        decoration: const InputDecoration(
                          labelText: 'Próxima km',
                          hintText: 'Ex.: 100000',
                          suffixText: 'km',
                          prefixIcon: Icon(Icons.trending_up_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(isNext: true),
                        icon: const Icon(
                          Icons.event_available_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _nextDate == null
                              ? 'Definir próxima data limite'
                              : 'Próxima data: ${_formatDate(_nextDate!)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      if (_nextMileage.text.isNotEmpty || _nextDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Um lembrete será criado automaticamente vinculado a este serviço.',
                            style: text.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
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
                      : Text(
                          _isEditing
                              ? 'Atualizar manutenção'
                              : 'Salvar manutenção',
                        ),
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
