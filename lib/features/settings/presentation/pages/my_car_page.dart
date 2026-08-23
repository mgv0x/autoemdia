import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/utils/formatters.dart';
import '../../../../../../shared/widgets/app_states.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../../vehicle/domain/vehicle_entity.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';

/// Tela "Meu Carro": exibe e permite editar o veículo ativo.
class MyCarPage extends ConsumerWidget {
  const MyCarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu carro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(vehiclesProvider);
              ref.invalidate(activeVehicleProvider);
            },
          ),
        ],
      ),
      body: _buildBody(
        context,
        ref,
        vehicleAsync,
        vehiclesAsync,
        scheme,
        text,
        isPremium,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<VehicleEntity?> vehicleAsync,
    AsyncValue<List<VehicleEntity>> vehiclesAsync,
    ColorScheme scheme,
    TextTheme text,
    bool isPremium,
  ) {
    if (vehicleAsync is AsyncLoading || vehiclesAsync is AsyncLoading) {
      return const AppLoading();
    }
    if (vehicleAsync.hasError) {
      return AppErrorState(
        onRetry: () => ref.invalidate(activeVehicleProvider),
      );
    }
    if (vehiclesAsync.hasError) {
      return AppErrorState(onRetry: () => ref.invalidate(vehiclesProvider));
    }

    final vehicle = vehicleAsync.value;
    final vehicles = vehiclesAsync.value ?? const <VehicleEntity>[];

    if (vehicle == null) {
      return AppEmptyState(
        icon: Icons.directions_car_outlined,
        title: 'Nenhum veículo cadastrado',
        message: 'Cadastre seu primeiro veículo para começar.',
        actionLabel: 'Cadastrar veículo',
        onAction: () => context.push('/vehicle/new'),
      );
    }

    final maxVehicles = isPremium ? 5 : 1;
    final canAddMore = vehicles.length < maxVehicles;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child:
              vehicle.photoPath != null && File(vehicle.photoPath!).existsSync()
              ? CircleAvatar(
                  radius: 64,
                  backgroundImage: FileImage(File(vehicle.photoPath!)),
                  backgroundColor: scheme.primaryContainer,
                )
              : CircleAvatar(
                  radius: 64,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    Icons.directions_car,
                    size: 56,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
        ),
        const SizedBox(height: 24),
        _info(context, 'Marca', vehicle.brand),
        _info(context, 'Modelo', vehicle.model),
        _info(context, 'Ano', '${vehicle.year}'),
        _info(context, 'Combustível', vehicle.fuel),
        _info(
          context,
          'Quilometragem',
          Formatters.mileage(vehicle.currentMileage),
        ),
        if (vehicle.plate != null) _info(context, 'Placa', vehicle.plate!),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push('/vehicle/edit', extra: vehicle),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar dados'),
        ),
        const SizedBox(height: 12),
        if (canAddMore)
          OutlinedButton.icon(
            onPressed: () => context.push('/vehicle/new'),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar outro veículo'),
          )
        else
          Card(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPremium
                          ? 'Limite de 5 veículos atingido.'
                          : 'Plano gratuito: 1 veículo. '
                                'No Premium, adicione até 5.',
                      style: text.bodyMedium,
                    ),
                  ),
                  if (!isPremium)
                    TextButton(
                      onPressed: () => context.push('/premium'),
                      child: const Text('Ver Premium'),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        if (vehicles.length > 1) ...[
          Text(
            'Seus veículos',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...vehicles.map(
            (v) => Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text(v.displayName),
                subtitle: Text(Formatters.mileage(v.currentMileage)),
                trailing: v.id == vehicle.id
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () =>
                    ref.read(activeVehicleIdProvider.notifier).set(v.id),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _info(BuildContext context, String label, String value) {
    final text = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: text.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
