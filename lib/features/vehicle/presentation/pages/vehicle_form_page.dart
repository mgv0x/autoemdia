import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/providers/analytics_provider.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../domain/vehicle_entity.dart';
import '../../domain/vehicle_type.dart';
import '../../domain/vehicle_type_config.dart';
import '../controllers/vehicle_controller.dart';

/// Formulário de cadastro/edição de veículo (Carro ou Moto).
/// Orientado por [VehicleTypeConfig] e seguindo divulgação progressiva.
class VehicleFormPage extends ConsumerStatefulWidget {
  const VehicleFormPage({super.key, this.vehicle, this.isFirstVehicle = false});

  final VehicleEntity? vehicle;
  final bool isFirstVehicle;

  @override
  ConsumerState<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends ConsumerState<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();

  late VehicleType _type;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _version;
  late final TextEditingController _year;
  late final TextEditingController _mileage;
  late final TextEditingController _initialMileage;
  late final TextEditingController _plate;
  late final TextEditingController _engine;
  late final TextEditingController _displacement;
  late final TextEditingController _notes;

  String? _fuel;
  bool _showMoreDetails = false;

  String? _photoTempPath;
  File? _photoPreview;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _type = v?.type ?? VehicleType.car;
    _brand = TextEditingController(text: v?.brand ?? '');
    _model = TextEditingController(text: v?.model ?? '');
    _version = TextEditingController(text: v?.version ?? '');
    _year = TextEditingController(text: v?.year.toString() ?? '');
    _mileage = TextEditingController(
      text: v == null ? '' : v.currentMileage.toString(),
    );
    _initialMileage = TextEditingController(
      text: v == null ? '' : v.initialMileage.toString(),
    );
    _plate = TextEditingController(text: v?.plate ?? '');
    _engine = TextEditingController(text: v?.engine ?? '');
    _displacement = TextEditingController(
      text: v?.displacement?.toString() ?? '',
    );
    _notes = TextEditingController(text: v?.notes ?? '');

    _fuel = v?.fuel;
    if (_fuel == '') _fuel = null;

    // Se estiver editando e já tiver campos adicionais preenchidos, abre detalhes
    if (v != null &&
        (v.version != null ||
            v.engine != null ||
            v.displacement != null ||
            v.notes != null ||
            v.plate != null)) {
      _showMoreDetails = true;
    }

    if (v?.photoPath != null && v!.photoPath!.isNotEmpty) {
      final file = File(v.photoPath!);
      if (file.existsSync()) {
        _photoPreview = file;
        _photoTempPath = v.photoPath;
      }
    }
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _version.dispose();
    _year.dispose();
    _mileage.dispose();
    _initialMileage.dispose();
    _plate.dispose();
    _engine.dispose();
    _displacement.dispose();
    _notes.dispose();
    super.dispose();
  }

  VehicleTypeConfig get _config => VehicleTypeConfig.of(_type);

  void _onTypeChanged(VehicleType newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      // Valida se o combustível atual existe no novo tipo, senão reseta
      if (_fuel != null && !_config.fuelTypes.contains(_fuel)) {
        _fuel = null;
      }
    });
  }

  Future<void> _submit({bool confirmedLowerKm = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_fuel == null) {
      showAppSnackBar(
        context,
        'Selecione o tipo de combustível.',
        isError: true,
      );
      return;
    }

    // Bloqueio de múltiplos veículos no plano Gratuito
    if (!_isEditing && !widget.isFirstVehicle) {
      final isPremium = ref.read(isPremiumProvider).value ?? false;
      final existingVehicles = await ref
          .read(vehiclesProvider.future)
          .catchError((_) => <VehicleEntity>[]);
      if (!isPremium && existingVehicles.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.garage_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Múltiplos Veículos'),
              ],
            ),
            content: const Text(
              'No plano gratuito você pode gerenciar 1 veículo com prontuário completo.\n\n'
              'Faça o upgrade para o Premium para adicionar múltiplos veículos na sua garagem.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/premium');
                },
                child: const Text('Conhecer o Premium'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final newMileage = Validators.parseMileage(_mileage.text) ?? 0;

    // Regra: se a km informada for menor que a km registrada anteriormente, pede confirmação
    if (_isEditing &&
        newMileage < widget.vehicle!.currentMileage &&
        !confirmedLowerKm) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quilometragem menor'),
          content: Text(
            'A quilometragem informada ($newMileage km) é menor que a anterior '
            '(${widget.vehicle!.currentMileage} km). Deseja continuar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Corrigir'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      return _submit(confirmedLowerKm: true);
    }

    final controller = ref.read(vehicleFormControllerProvider.notifier);
    final existing = widget.vehicle;

    final initialKm = Validators.parseMileage(_initialMileage.text) ??
        (existing?.initialMileage ?? newMileage);

    final vehicle = VehicleEntity(
      id: existing?.id ?? '',
      userId: existing?.userId ?? '',
      type: _type,
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      version: _version.text.trim().isEmpty ? null : _version.text.trim(),
      year: int.parse(_year.text.trim()),
      fuel: _fuel!,
      plate: _plate.text.trim().isEmpty
          ? null
          : _plate.text.trim().toUpperCase(),
      currentMileage: newMileage,
      initialMileage: initialKm,
      engine: _engine.text.trim().isEmpty ? null : _engine.text.trim(),
      displacement: _config.showDisplacement
          ? int.tryParse(_displacement.text.trim())
          : null,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      photoPath: _photoTempPath,
    );

    final saved = _isEditing
        ? await controller.update(vehicle)
        : await controller.create(vehicle);

    if (!mounted) return;
    if (saved != null) {
      if (_photoTempPath != null && saved.id.isNotEmpty) {
        await controller.saveVehiclePhoto(
          vehicleId: saved.id,
          tempFilePath: _photoTempPath!,
          currentVehicle: saved,
        );
      }
      if (!_isEditing) {
        ref.read(analyticsServiceProvider).vehicleCreated();
      }
      if (!mounted) return;
      if (widget.isFirstVehicle) {
        context.go('/');
      } else {
        context.pop(saved);
      }
    } else {
      final err = ref.read(vehicleFormControllerProvider).error;
      showAppSnackBar(context, handleError(err ?? '').message, isError: true);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() {
        _photoTempPath = picked.path;
        _photoPreview = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final existingVehicles = ref.watch(vehiclesProvider).value ?? [];
    if (!_isEditing &&
        !widget.isFirstVehicle &&
        !isPremium &&
        existingVehicles.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Novo veículo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.garage_rounded,
                    size: 44,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Múltiplos Veículos',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No plano gratuito você pode gerenciar 1 veículo com prontuário e lembretes completos.\n\n'
                  'Faça o upgrade para o Premium e acompanhe toda a sua garagem (carros e motos ilimitados).',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textMutedColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/premium'),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Conhecer o Premium'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Voltar para Meus Veículos'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final text = Theme.of(context).textTheme;
    final loading = ref.watch(vehicleFormControllerProvider).isLoading;
    final plateText = _plate.text.trim();
    final isPlateWarning = plateText.isNotEmpty && !Validators.isBrazilianPlate(plateText);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isFirstVehicle
              ? 'Cadastre seu veículo'
              : (_isEditing ? 'Editar veículo' : 'Novo veículo'),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
              ),
              tooltip: 'Excluir veículo',
              onPressed: loading ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isFirstVehicle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Cadastre seu primeiro veículo para acompanhar o prontuário completo.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ),

                // ─── 1. Seletor de Tipo (Carro vs Moto) ───────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      for (final t in VehicleType.values)
                        Expanded(
                          child: InkWell(
                            onTap: () => _onTypeChanged(t),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _type == t ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _type == t
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    t == _type ? t.icon : t.outlineIcon,
                                    size: 20,
                                    color: _type == t
                                        ? AppTheme.primaryColor
                                        : AppTheme.textMutedColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: _type == t
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _type == t
                                          ? AppTheme.primaryColor
                                          : AppTheme.textMutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── 2. Campos Essenciais ─────────────────────────────────
                TextFormField(
                  controller: _brand,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'Marca'),
                  decoration: InputDecoration(
                    labelText: 'Marca',
                    hintText: _type == VehicleType.motorcycle
                        ? 'Ex.: Honda, Yamaha, BMW'
                        : 'Ex.: Toyota, Honda, Volkswagen',
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _model,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'Modelo'),
                  decoration: InputDecoration(
                    labelText: 'Modelo',
                    hintText: _type == VehicleType.motorcycle
                        ? 'Ex.: CG 160 Titan, CB 500X'
                        : 'Ex.: Civic, Corolla, Polo',
                    prefixIcon: Icon(_config.outlineIcon),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _year,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: Validators.vehicleYear,
                        decoration: const InputDecoration(
                          labelText: 'Ano',
                          hintText: '2022',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _fuel,
                        decoration: const InputDecoration(
                          labelText: 'Combustível',
                        ),
                        items: _config.fuelTypes
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (v) => setState(() => _fuel = v),
                        validator: (v) =>
                            v == null ? 'Selecione o combustível.' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _mileage,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.mileage,
                  decoration: InputDecoration(
                    labelText: _config.mileageLabel,
                    suffixText: 'km',
                    prefixIcon: const Icon(Icons.speed_outlined),
                  ),
                ),
                const SizedBox(height: 18),

                // ─── 3. Divulgação Progressiva: "Mais detalhes" ───────────
                InkWell(
                  onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _showMoreDetails
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showMoreDetails
                              ? 'Ocultar detalhes adicionais'
                              : 'Mais detalhes (placa, versão, motor, foto)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showMoreDetails) ...[
                  const SizedBox(height: 12),

                  // Versão
                  TextFormField(
                    controller: _version,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Versão (opcional)',
                      hintText: 'Ex.: Touring, EXL, Sport',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Motor / Cilindrada
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _engine,
                          decoration: InputDecoration(
                            labelText: 'Motor (opcional)',
                            hintText: _type == VehicleType.motorcycle
                                ? 'Ex.: Monocilíndrico'
                                : 'Ex.: 1.5 Turbo, 2.0',
                          ),
                        ),
                      ),
                      if (_config.showDisplacement) ...[
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _displacement,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Cilindrada',
                              suffixText: 'cc',
                              hintText: '160',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Placa com aviso não-bloqueante
                  TextFormField(
                    controller: _plate,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                      LengthLimitingTextInputFormatter(8),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Placa (opcional)',
                      hintText: 'ABC1D23',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      helperText: isPlateWarning
                          ? 'Aviso: Formato fora do padrão brasileiro (ABC-1234 ou ABC1D23)'
                          : null,
                      helperStyle: isPlateWarning
                          ? const TextStyle(color: AppTheme.warningColor)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Observações
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      hintText: 'Detalhes, histórico anterior ou particularidades',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Foto do veículo
                  if (_photoPreview != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _photoPreview!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                              onPressed: () => setState(() {
                                _photoPreview = null;
                                _photoTempPath = null;
                              }),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Adicionar foto do veículo'),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'A foto fica salva localmente no seu aparelho.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ─── Botão de Submit ─────────────────────────────────────
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
                      : Text(
                          widget.isFirstVehicle
                              ? 'Continuar'
                              : (_isEditing
                                  ? 'Salvar alterações'
                                  : 'Cadastrar veículo'),
                        ),
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: loading ? null : _confirmDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.errorColor,
                    ),
                    label: const Text(
                      'Excluir este veículo',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final v = widget.vehicle;
    if (v == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Excluir veículo'),
          ],
        ),
        content: Text(
          'Deseja realmente excluir "${v.displayName}"?\n\n'
          '⚠️ Atenção: Esta ação é irreversível. Todas as manutenções, gastos '
          'e lembretes associados a este veículo serão removidos permanentemente.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(vehicleFormControllerProvider.notifier)
          .delete(v.id);
      if (mounted) {
        if (success) {
          showAppSnackBar(context, 'Veículo excluído com sucesso.');
          context.pop();
        } else {
          showAppSnackBar(
            context,
            'Não foi possível excluir o veículo.',
            isError: true,
          );
        }
      }
    }
  }
}
