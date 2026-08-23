import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/providers/analytics_provider.dart';
import '../../domain/vehicle_entity.dart';
import '../controllers/vehicle_controller.dart';

/// Formulário de cadastro/edição de veículo.
class VehicleFormPage extends ConsumerStatefulWidget {
  const VehicleFormPage({super.key, this.vehicle, this.isFirstVehicle = false});

  final VehicleEntity? vehicle;
  final bool isFirstVehicle;

  @override
  ConsumerState<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends ConsumerState<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _mileage;
  late final TextEditingController _plate;
  String? _fuel;

  String? _photoTempPath; // foto escolhida (temporário) ou salva
  File? _photoPreview;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brand = TextEditingController(text: v?.brand ?? '');
    _model = TextEditingController(text: v?.model ?? '');
    _year = TextEditingController(text: v?.year.toString() ?? '');
    _mileage = TextEditingController(
      text: v == null ? '' : v.currentMileage.toString(),
    );
    _plate = TextEditingController(text: v?.plate ?? '');
    _fuel = v?.fuel;
    if (_fuel == '') _fuel = null;

    // Se estiver editando e já houver foto local, exibe preview.
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
    _year.dispose();
    _mileage.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fuel == null) {
      showAppSnackBar(
        context,
        'Selecione o tipo de combustível.',
        isError: true,
      );
      return;
    }

    final controller = ref.read(vehicleFormControllerProvider.notifier);
    final existing = widget.vehicle;

    final vehicle = VehicleEntity(
      id: existing?.id ?? '',
      userId: existing?.userId ?? '',
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      year: int.parse(_year.text.trim()),
      fuel: _fuel!,
      plate: _plate.text.trim().isEmpty
          ? null
          : _plate.text.trim().toUpperCase(),
      currentMileage: Validators.parseMileage(_mileage.text) ?? 0,
    );

    final saved = _isEditing
        ? await controller.update(vehicle)
        : await controller.create(vehicle);

    if (!mounted) return;
    if (saved != null) {
      // Salva a foto no dispositivo se o usuário escolheu uma.
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
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _photoTempPath = picked.path;
        _photoPreview = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final loading = ref.watch(vehicleFormControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFirstVehicle
              ? 'Cadastre seu veículo'
              : (_isEditing ? 'Editar veículo' : 'Novo veículo'),
        ),
        leading: widget.isFirstVehicle
            ? null
            : null, // back button automático quando pode voltar
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isFirstVehicle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Conte um pouco sobre o seu carro para começarmos o cuidado.',
                      style: text.bodyMedium,
                    ),
                  ),
                TextFormField(
                  controller: _brand,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'Marca'),
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    hintText: 'Ex.: Honda',
                    prefixIcon: Icon(Icons.factory_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'Modelo'),
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    hintText: 'Ex.: Civic',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                ),
                const SizedBox(height: 16),
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
                          hintText: '2018',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _fuel,
                        decoration: const InputDecoration(
                          labelText: 'Combustível',
                        ),
                        items: AppConstants.fuelTypes
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _fuel = v),
                        validator: (v) =>
                            v == null ? 'Selecione o combustível.' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mileage,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.mileage,
                  decoration: const InputDecoration(
                    labelText: 'Quilometragem atual',
                    suffixText: 'km',
                    prefixIcon: Icon(Icons.speed_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plate,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Placa (opcional)',
                    hintText: 'ABC1D23',
                  ),
                ),
                const SizedBox(height: 16),
                // ─── Foto do veículo (local, fica só no aparelho) ─────────
                if (_photoPreview != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _photoPreview!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
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
                    label: const Text('Adicionar foto do veículo (opcional)'),
                  ),
                const SizedBox(height: 8),
                Text(
                  'A foto fica apenas no seu aparelho (não é enviada).',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      : Text(
                          widget.isFirstVehicle
                              ? 'Continuar'
                              : (_isEditing
                                    ? 'Salvar alterações'
                                    : 'Cadastrar'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
