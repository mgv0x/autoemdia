import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../app/theme.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../core/utils/snackbar.dart';
import '../../../../../../shared/widgets/app_states.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../../vehicle/domain/vehicle_entity.dart';
import '../../../vehicle/domain/vehicle_type_config.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../widgets/mileage_update_dialog.dart';

/// Tela "Meus Veículos": gerencia o prontuário dos veículos cadastrados,
/// permite alternar o veículo ativo, editar dados e excluir em cascata.
class MyCarPage extends ConsumerWidget {
  const MyCarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Meus veículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Adicionar veículo',
            onPressed: () => _handleNewVehicle(
              context,
              ref,
              vehiclesAsync.value ?? [],
              isPremium,
            ),
          ),
        ],
      ),
      body: vehiclesAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorState(
          onRetry: () => ref.invalidate(vehiclesProvider),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: 'Nenhum veículo cadastrado',
              message: 'Cadastre seu carro ou sua moto para começar a cuidar.',
              actionLabel: 'Cadastrar veículo',
              onAction: () => context.push('/vehicle/new'),
            );
          }

          final activeVehicle = vehicleAsync.value ?? vehicles.first;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehiclesProvider);
              ref.invalidate(activeVehicleProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // ─── Veículo Ativo em Destaque ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VEÍCULO EM USO',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                    Text(
                      '${vehicles.length} veículo(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _ActiveVehicleCard(
                  vehicle: activeVehicle,
                  onUpdateMileage: () => showMileageUpdateDialog(
                    context,
                    ref: ref,
                    vehicle: activeVehicle,
                  ),
                  onEdit: () => context.push('/vehicle/edit', extra: activeVehicle),
                  onDelete: () => _confirmDeleteVehicle(context, ref, activeVehicle),
                ),
                const SizedBox(height: 28),

                // ─── Lista de Todos os Veículos ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SEUS VEÍCULOS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _handleNewVehicle(context, ref, vehicles, isPremium),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Novo veículo'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                for (final v in vehicles) ...[
                  _VehicleListItem(
                    vehicle: v,
                    isActive: v.id == activeVehicle.id,
                    onSelect: () async {
                      await ref.read(activeVehicleIdProvider.notifier).set(v.id);
                      ref.invalidate(activeVehicleProvider);
                    },
                    onEdit: () => context.push('/vehicle/edit', extra: v),
                    onDelete: () => _confirmDeleteVehicle(context, ref, v),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleNewVehicle(
    BuildContext context,
    WidgetRef ref,
    List<VehicleEntity> vehicles,
    bool isPremium,
  ) {
    if (!isPremium && vehicles.isNotEmpty) {
      _showMultipleVehiclesPaywall(context);
      return;
    }
    context.push('/vehicle/new');
  }

  void _showMultipleVehiclesPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.garage_rounded,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Múltiplos Veículos',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No plano gratuito você pode gerenciar 1 veículo com prontuário e lembretes completos.\n\n'
                'Faça o upgrade para o Premium e acompanhe toda a sua frota ou garagem (carros e motos ilimitados).',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textMutedColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/premium');
                  },
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Conhecer o Premium'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteVehicle(
    BuildContext context,
    WidgetRef ref,
    VehicleEntity vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Excluir veículo'),
          ],
        ),
        content: Text(
          'Deseja excluir "${vehicle.displayName}"?\n\n'
          '⚠️ Atenção: Esta ação é irreversível. Todas as manutenções, gastos, '
          'lembretes e histórico vinculados a este veículo serão excluídos permanentemente.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(vehicleFormControllerProvider.notifier)
          .delete(vehicle.id);
      if (context.mounted) {
        if (success) {
          showAppSnackBar(context, 'Veículo e registros associados excluídos.');
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

/// Card de destaque para o veículo ativo em uso.
class _ActiveVehicleCard extends StatelessWidget {
  const _ActiveVehicleCard({
    required this.vehicle,
    required this.onUpdateMileage,
    required this.onEdit,
    required this.onDelete,
  });

  final VehicleEntity vehicle;
  final VoidCallback onUpdateMileage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final config = VehicleTypeConfig.of(vehicle.type);
    final photo = vehicle.photoPath;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar ou Foto
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtleColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: photo != null && File(photo).existsSync()
                        ? Image.file(File(photo), fit: BoxFit.cover)
                        : Icon(config.icon, size: 28, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 14),

                // Dados
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              config.label,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.mileage(vehicle.currentMileage)} • ${vehicle.fuel}'
                        '${vehicle.plate != null ? ' • ${vehicle.plate}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtleColor),

          // Ações Rápidas
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onUpdateMileage,
                  icon: const Icon(Icons.speed_outlined, size: 16),
                  label: const Text('Registrar km'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: AppTheme.borderSubtleColor,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: AppTheme.borderSubtleColor,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppTheme.errorColor,
                  ),
                  label: const Text(
                    'Excluir',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Item da lista de veículos com troca de ativo com 1 toque.
class _VehicleListItem extends StatelessWidget {
  const _VehicleListItem({
    required this.vehicle,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final VehicleEntity vehicle;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final config = VehicleTypeConfig.of(vehicle.type);
    final photo = vehicle.photoPath;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppTheme.primaryColor : AppTheme.borderSubtleColor,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onSelect,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                : AppTheme.surfaceVariantColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: photo != null && File(photo).existsSync()
                ? Image.file(File(photo), fit: BoxFit.cover)
                : Icon(
                    config.icon,
                    size: 22,
                    color: isActive ? AppTheme.primaryColor : AppTheme.textMutedColor,
                  ),
          ),
        ),
        title: Text(
          vehicle.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          '${Formatters.mileage(vehicle.currentMileage)}${vehicle.plate != null ? ' • ${vehicle.plate}' : ''}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textMutedColor,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ativo',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              TextButton(
                onPressed: onSelect,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Selecionar'),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                      SizedBox(width: 10),
                      Text('Excluir', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
