import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/utils/snackbar.dart';
import '../../../../../../core/utils/validators.dart';
import '../../../vehicle/domain/vehicle_entity.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';

/// Diálogo para registrar/atualizar a quilometragem atual do veículo.
Future<void> showMileageUpdateDialog(
  BuildContext context, {
  required WidgetRef ref,
  required VehicleEntity vehicle,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _MileageUpdateDialog(
      vehicle: vehicle,
      onConfirm: (newMileage) async {
        final ok = await ref
            .read(vehicleFormControllerProvider.notifier)
            .updateMileage(vehicle.id, newMileage);
        if (ctx.mounted) {
          Navigator.pop(ctx);
          showAppSnackBar(
            context,
            ok
                ? 'Quilometragem atualizada para $newMileage km.'
                : 'Não foi possível atualizar a quilometragem.',
            isError: !ok,
          );
        }
      },
    ),
  );
}

class _MileageUpdateDialog extends StatefulWidget {
  const _MileageUpdateDialog({required this.vehicle, required this.onConfirm});

  final VehicleEntity vehicle;
  final Future<void> Function(int newMileage) onConfirm;

  @override
  State<_MileageUpdateDialog> createState() => _MileageUpdateDialogState();
}

class _MileageUpdateDialogState extends State<_MileageUpdateDialog> {
  late final TextEditingController _km;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _km = TextEditingController(text: widget.vehicle.currentMileage.toString());
  }

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final value = Validators.parseMileage(_km.text);
    if (value == null) {
      setState(() => _error = 'Informe uma quilometragem válida.');
      return;
    }
    if (value < 0) {
      setState(() => _error = 'A quilometragem não pode ser negativa.');
      return;
    }

    // Regra de negócio: km menor que a atual exige confirmação explícita.
    if (value < widget.vehicle.currentMileage) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quilometragem menor'),
          content: Text(
            'A quilometragem informada ($value km) é menor que a atual '
            '(${widget.vehicle.currentMileage} km). Deseja continuar mesmo assim?',
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
    }

    setState(() => _saving = true);
    await widget.onConfirm(value);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar quilometragem'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atual do veículo: '
            '${widget.vehicle.currentMileage} km',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _km,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nova quilometragem',
              suffixText: 'km',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _confirm,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
