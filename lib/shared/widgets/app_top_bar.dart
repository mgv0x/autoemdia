import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/utils/formatters.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/subscription/presentation/controllers/subscription_controller.dart';
import '../../features/vehicle/domain/vehicle_entity.dart';
import '../../features/vehicle/presentation/controllers/vehicle_controller.dart';

/// Top bar padronizada seguindo o design system do Auto em Dia.
/// Suporta modo com seletor de veículo ativo com troca rápida via bottom sheet.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.showVehicleSelector = false,
    this.showProfile = true,
    this.actions,
    this.leading,
  });

  final String? title;
  final bool showVehicleSelector;
  final bool showProfile;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStreamProvider).value;
    final colorScheme = Theme.of(context).colorScheme;
    final activeVehicle = ref.watch(activeVehicleProvider).value;
    final vehicles = ref.watch(vehiclesProvider).value ?? const <VehicleEntity>[];
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: leading!,
                ),

              // ─── Seletor de Veículo Ativo OU Título da Tela ───────────
              if (showVehicleSelector && activeVehicle != null) ...[
                InkWell(
                  onTap: () => _showVehicleSwitchSheet(
                    context,
                    ref,
                    vehicles,
                    activeVehicle,
                    isPremium,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activeVehicle.type.icon,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: Text(
                            activeVehicle.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                if (leading == null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  title ?? 'Auto em Dia',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ],

              const Spacer(),
              if (actions != null) ...?actions,

              // ─── Avatar do Usuário (vai para Perfil / Configurações) ───
              if (showProfile)
                InkWell(
                  onTap: () => context.go('/more'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        auth != null && auth.name.isNotEmpty
                            ? auth.name.substring(0, 1).toUpperCase()
                            : 'M',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehicleSwitchSheet(
    BuildContext context,
    WidgetRef ref,
    List<VehicleEntity> vehicles,
    VehicleEntity current,
    bool isPremium,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selecione o veículo',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final v in vehicles) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: v.id == current.id
                      ? AppTheme.primaryColor.withValues(alpha: 0.08)
                      : null,
                  leading: Icon(
                    v.type.icon,
                    color: v.id == current.id
                        ? AppTheme.primaryColor
                        : AppTheme.textMutedColor,
                  ),
                  title: Text(
                    v.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: v.id == current.id
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  subtitle: Text(
                    '${Formatters.mileage(v.currentMileage)}${v.plate != null ? ' • ${v.plate}' : ''}',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Editar / Excluir veículo',
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/vehicle/edit', extra: v);
                        },
                      ),
                      if (v.id == current.id)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                    ],
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(activeVehicleIdProvider.notifier)
                        .set(v.id);
                    ref.invalidate(activeVehicleProvider);
                  },
                ),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (!isPremium && vehicles.isNotEmpty) {
                    context.push('/premium');
                  } else {
                    context.push('/vehicle/new');
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Cadastrar outro veículo'),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/my-car');
                },
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Gerenciar e excluir veículos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
