import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/errors/app_failure.dart';
import '../../../../../core/services/calculation_service.dart';
import '../../../../../core/services/insights_service.dart';
import '../../../../../core/services/vehicle_health_service.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/app_states.dart';
import '../../../../../shared/widgets/app_top_bar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../settings/presentation/widgets/mileage_update_dialog.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../../vehicle/domain/vehicle_entity.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../controllers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStreamProvider).value;
    final dataAsync = ref.watch(dashboardDataProvider);
    final vehicles = ref.watch(vehiclesProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    final firstName = auth?.name.isNotEmpty == true
        ? auth!.name.split(' ').first
        : 'Marcus';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const AppTopBar(showVehicleSelector: true),
      body: dataAsync.when(
        loading: () => const AppLoading(),
        error: (e, stack) {
          debugPrint('[Dashboard] Erro ao carregar dados: $e\n$stack');
          return AppErrorState(
            message: e is AppFailure ? e.message : 'Detalhes: $e',
            onRetry: () {
              ref.invalidate(vehiclesProvider);
              ref.invalidate(dashboardDataProvider);
            },
          );
        },
        data: (d) {
          if (vehicles.hasValue && vehicles.value!.isEmpty) {
            return AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: 'Comece cadastrando seu veículo',
              message:
                  'Adicione seu carro ou sua moto para acompanhar manutenções, gastos e lembretes.',
              actionLabel: 'Cadastrar veículo',
              onAction: () => context.push('/vehicle/new?first=true'),
            );
          }

          final vehicleTerm =
              d.vehicle?.isMotorcycle == true ? 'da sua moto' : 'do seu veículo';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehiclesProvider);
              ref.invalidate(dashboardDataProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Header Greeting
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $firstName 👋',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prontuário digital $vehicleTerm em tempo real.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Vehicle Hero Card (com Score de Saúde e ações rápidas)
                _VehicleHeroCard(
                  vehicle: d.vehicle,
                  healthResult: d.healthResult,
                  onUpdateMileage: d.vehicle != null
                      ? () => showMileageUpdateDialog(
                          context,
                          ref: ref,
                          vehicle: d.vehicle!,
                        )
                      : null,
                  onTapHealth: d.healthResult != null
                      ? () => _showHealthExplanationSheet(
                          context,
                          d.healthResult!,
                          isPremium,
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                // Aviso de Quilometragem Desatualizada (> 30 dias)
                if (d.healthResult?.isMileageStale == true && d.vehicle != null) ...[
                  _StaleMileageBanner(
                    staleDays: d.healthResult!.staleDays ?? 30,
                    onUpdate: () => showMileageUpdateDialog(
                      context,
                      ref: ref,
                      vehicle: d.vehicle!,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Status Overview Card (Saúde do Veículo com explicação)
                _StatusOverviewCard(
                  vehicle: d.vehicle,
                  healthResult: d.healthResult,
                  overdueCount: d.overdueCount,
                  totalReminders: d.upcomingReminders.length + d.overdueCount,
                  onTap: d.healthResult != null
                      ? () => _showHealthExplanationSheet(
                          context,
                          d.healthResult!,
                          isPremium,
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Insight Inteligente (Apenas Premium conforme matriz de monetização)
                if (!isPremium) ...[
                  _SingleInsightCard(
                    insight: const VehicleInsight(
                      type: InsightType.neutral,
                      title: 'Insights Inteligentes • Premium',
                      message:
                          'Acompanhe variações de gastos mês a mês e receba dicas personalizadas de economia.',
                      percentageChange: 0.0,
                    ),
                    isLocked: true,
                    onTap: () => context.push('/premium'),
                  ),
                  const SizedBox(height: 16),
                ] else if (d.singleInsight != null) ...[
                  _SingleInsightCard(
                    insight: d.singleInsight!,
                    isLocked: false,
                    onTap: () => context.go('/expenses'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Metrics Bento Grid (Gastos + Próxima manutenção projetada)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spending Card
                    Expanded(
                      child: _SpendingCard(
                        data: d,
                        onTap: () => context.go('/expenses'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next Maintenance Card
                    Expanded(
                      child: _NextMaintenanceBentoCard(
                        data: d,
                        onTap: () => context.go('/reminders'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Histórico Recente',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/maintenance'),
                      child: Text(
                        'Ver tudo',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Recent History List Card
                _RecentHistoryListCard(
                  maintenances: d.recentMaintenances,
                  onRegister: () => context.push('/maintenance/new'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHealthExplanationSheet(
    BuildContext context,
    VehicleHealthResult result,
    bool isPremium,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HealthExplanationBottomSheet(
        result: result,
        isPremium: isPremium,
      ),
    );
  }
}

/// Hero Card com imagem estilizada do veículo, linha de status, score e gradiente.
class _VehicleHeroCard extends StatelessWidget {
  const _VehicleHeroCard({
    this.vehicle,
    this.healthResult,
    this.onUpdateMileage,
    this.onTapHealth,
  });

  final VehicleEntity? vehicle;
  final VehicleHealthResult? healthResult;
  final VoidCallback? onUpdateMileage;
  final VoidCallback? onTapHealth;

  @override
  Widget build(BuildContext context) {
    final name = vehicle?.displayName ?? 'Veículo';
    final year = vehicle?.year != null ? '${vehicle!.year} • ' : '';
    final mileage = vehicle?.currentMileage != null
        ? Formatters.mileage(vehicle!.currentMileage)
        : '0 km';
    final photo = vehicle?.photoPath;

    final statusColor = _statusLineColor(healthResult);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtleColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Vehicle Background Image / Card Art
            if (photo != null && File(photo).existsSync())
              Image.file(File(photo), fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    vehicle?.type.icon ?? Icons.directions_car_filled,
                    size: 80,
                    color: Colors.white12,
                  ),
                ),
              ),

            // Top Status Accent Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(color: statusColor),
            ),

            // Top Right: Badge de Saúde do Veículo (0–100)
            Positioned(
              top: 14,
              right: 14,
              child: _HealthScoreBadge(
                healthResult: healthResult,
                onTap: onTapHealth,
              ),
            ),

            // Bottom Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.65, 1.0],
                  colors: [
                    Color(0xF00F172A),
                    Color(0x800F172A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Vehicle Text & Switch / Km Buttons
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$year$mileage',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => vehicle != null
                            ? context.push('/vehicle/edit', extra: vehicle)
                            : context.push('/my-car'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'Editar',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (onUpdateMileage != null && vehicle != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onUpdateMileage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.speed_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Nova km',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusLineColor(VehicleHealthResult? hr) {
    if (hr == null || !hr.hasEnoughData || hr.score == null) {
      return AppTheme.primaryColor;
    }
    if (hr.score! >= 85) return AppTheme.successColor;
    if (hr.score! >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}

/// Badge de Saúde no Hero Card
class _HealthScoreBadge extends StatelessWidget {
  const _HealthScoreBadge({this.healthResult, this.onTap});

  final VehicleHealthResult? healthResult;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hr = healthResult;

    if (hr == null || !hr.hasEnoughData || hr.score == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 13, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                'Sem dados',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final score = hr.score!;
    final color = score >= 85
        ? AppTheme.successColor
        : (score >= 60 ? AppTheme.warningColor : AppTheme.errorColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Saúde: $score/100',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner de Quilometragem Desatualizada (> 30 dias)
class _StaleMileageBanner extends StatelessWidget {
  const _StaleMileageBanner({
    required this.staleDays,
    required this.onUpdate,
  });

  final int staleDays;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.speed_outlined,
            color: AppTheme.warningColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Km não atualizada há $staleDays dias.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          InkWell(
            onTap: onUpdate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Atualizar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de visão geral do status do veículo com explicação de saúde ao tocar
class _StatusOverviewCard extends StatelessWidget {
  const _StatusOverviewCard({
    this.vehicle,
    required this.healthResult,
    required this.overdueCount,
    required this.totalReminders,
    this.onTap,
  });

  final VehicleEntity? vehicle;
  final VehicleHealthResult? healthResult;
  final int overdueCount;
  final int totalReminders;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hr = healthResult;

    String title;
    String subtitle;
    Color iconColor;
    IconData iconData;

    if (hr != null && hr.hasEnoughData && hr.score != null) {
      final score = hr.score!;
      if (score >= 85) {
        title = 'Saúde: $score/100 • ${hr.statusText}';
        subtitle = hr.explanation.summary;
        iconColor = AppTheme.successColor;
        iconData = Icons.check_circle_outline_rounded;
      } else if (score >= 60) {
        title = 'Saúde: $score/100 • ${hr.statusText}';
        subtitle = hr.explanation.summary;
        iconColor = AppTheme.warningColor;
        iconData = Icons.warning_amber_rounded;
      } else {
        title = 'Saúde: $score/100 • ${hr.statusText}';
        subtitle = hr.explanation.summary;
        iconColor = AppTheme.errorColor;
        iconData = Icons.error_outline_rounded;
      }
    } else {
      final label = vehicle?.isMotorcycle == true ? 'da moto' : 'do veículo';
      title = 'Saúde $label: Sem dados suficientes';
      subtitle = 'Cadastre ao menos 2 cuidados para calcular a pontuação.';
      iconColor = AppTheme.primaryColor;
      iconData = Icons.health_and_safety_outlined;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtleColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMutedColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de Insight Único (máximo 1 na Home)
class _SingleInsightCard extends StatelessWidget {
  const _SingleInsightCard({
    required this.insight,
    required this.onTap,
    this.isLocked = false,
  });

  final VehicleInsight insight;
  final VoidCallback onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final isSavings = insight.type == InsightType.decrease;
    final color = isLocked
        ? AppTheme.tertiaryColor
        : (isSavings ? AppTheme.successColor : AppTheme.primaryColor);
    final icon = isLocked
        ? Icons.auto_awesome_rounded
        : (isSavings ? Icons.savings_outlined : Icons.trending_up_rounded);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        insight.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insight.message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bento Card: Gastos com custo por km ou média mensal
class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.data, required this.onTap});
  final DashboardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = data.yearTotal;
    final costPerKm = data.costPerKmResult;

    String secondaryLabel = 'Gastos este ano';
    if (costPerKm != null && costPerKm.hasEnoughData && costPerKm.costPerKm != null) {
      secondaryLabel = '${Formatters.currency(costPerKm.costPerKm!)}/km';
    } else if (data.monthlyAverageResult.hasEnoughData &&
        data.monthlyAverageResult.averageAmount != null) {
      secondaryLabel = 'Média ${Formatters.currency(data.monthlyAverageResult.averageAmount!)}/mês';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtleColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'GASTOS TOTAIS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.currency(amount),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              secondaryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),

            // Sparkline Visual
            SizedBox(
              height: 38,
              width: double.infinity,
              child: CustomPaint(painter: _SparklinePainter()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bento Card: Próxima Manutenção com projeção de data inteligente
class _NextMaintenanceBentoCard extends StatelessWidget {
  const _NextMaintenanceBentoCard({required this.data, required this.onTap});
  final DashboardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final next = data.nextMaintenance;
    final vehicle = data.vehicle;
    final projected = data.projectedCareDate;

    String title = 'Troca de óleo';
    String subtitle = 'Sem revisões';
    double percent = 1.0;

    if (next != null) {
      title = next.title;
      if (vehicle != null && next.dueMileage != null) {
        final km = next.dueMileage! - vehicle.currentMileage;
        if (km <= 0) {
          subtitle = 'Vencido em ${-km} km';
        } else if (projected != null) {
          subtitle = 'Em $km km • ~${Formatters.date(projected.estimatedDate)}';
        } else {
          subtitle = 'Faltam $km km';
        }
        percent = ((vehicle.currentMileage / next.dueMileage!).clamp(0.0, 1.0));
      } else if (next.dueDate != null) {
        final days = CalculationService.daysRemaining(next.dueDate!);
        subtitle = days < 0 ? 'Vencido há ${-days} d' : 'Em $days dias';
        percent = 0.75;
      }
    } else {
      title = 'Tudo em dia';
      subtitle = 'Sem pendências';
      percent = 1.0;
    }

    final percentInt = (percent * 100).toInt();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtleColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'PRÓXIMO CUIDADO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build_rounded,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ),
                Text(
                  '$percentInt%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceVariantColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom Sheet: "Por que minha pontuação está assim?" (Saúde do Veículo)
class _HealthExplanationBottomSheet extends StatelessWidget {
  const _HealthExplanationBottomSheet({
    required this.result,
    required this.isPremium,
  });

  final VehicleHealthResult result;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final score = result.score;
    final exp = result.explanation;

    Color scoreColor = AppTheme.primaryColor;
    if (score != null) {
      if (score >= 85) {
        scoreColor = AppTheme.successColor;
      } else if (score >= 60) {
        scoreColor = AppTheme.warningColor;
      } else {
        scoreColor = AppTheme.errorColor;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Score Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: scoreColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saúde do Veículo',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          score != null
                              ? '$score de 100 pontos • ${result.statusText}'
                              : result.statusText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Natural Language Summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  exp.summary,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Critical Items (Vencidos)
              if (exp.criticalItems.isNotEmpty) ...[
                Text(
                  'Atenção urgente',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...exp.criticalItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cancel,
                          size: 16,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!isPremium) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.tertiaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.tertiaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: AppTheme.tertiaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Diagnóstico Avançado',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  'Exclusivo para assinantes Premium',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.tertiaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Desbloqueie a análise por subcategoria (Pneus, Freios, Motor, Revisões, Lembretes) e veja exatamente quais itens impactam a pontuação do seu veículo.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMutedColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/premium');
                          },
                          child: const Text('Desbloquear Saúde Avançada'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Warning Items (Próximos)
                if (exp.warningItems.isNotEmpty) ...[
                  Text(
                    'Vencendo em breve',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exp.warningItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.watch_later_outlined,
                            size: 16,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Positive Items (Em dia)
                if (exp.positiveItems.isNotEmpty) ...[
                  Text(
                    'Itens em dia',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exp.positiveItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Fechar button
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recent History List Container
class _RecentHistoryListCard extends StatelessWidget {
  const _RecentHistoryListCard({
    required this.maintenances,
    required this.onRegister,
  });

  final List<dynamic> maintenances;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    if (maintenances.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtleColor),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.history_toggle_off,
                size: 36,
                color: AppTheme.textMutedColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhuma manutenção registrada recentemente.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textMutedColor,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Registrar agora'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtleColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (var i = 0; i < maintenances.take(3).length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppTheme.borderSubtleColor),
              _HistoryItemTile(
                maintenance: maintenances[i],
                onTap: () => context.push(
                  '/maintenance/${maintenances[i].id}',
                  extra: maintenances[i],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryItemTile extends StatelessWidget {
  const _HistoryItemTile({required this.maintenance, required this.onTap});
  final dynamic maintenance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(maintenance.category as String);
    final desc = maintenance.description as String;
    final date = Formatters.date(maintenance.serviceDate as DateTime);
    final cat = maintenance.category as String;
    final cost = maintenance.cost != null
        ? Formatters.currency(maintenance.cost as double)
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantColor.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppTheme.textMutedColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$date • $cat',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (cost != null)
              Text(
                cost,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'Óleo e filtros' || 'Óleo & Filtros' => Icons.oil_barrel_outlined,
      'Freios' => Icons.disc_full_outlined,
      'Pneus' => Icons.album_outlined,
      'Motor' => Icons.precision_manufacturing_outlined,
      'Bateria' => Icons.battery_charging_full,
      'Lavagem' => Icons.local_car_wash_outlined,
      'Seguro' || 'Documentação' => Icons.description_outlined,
      _ => Icons.build_outlined,
    };
  }
}

/// Custom painter for the spending sparkline curve
class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final points = [
      Offset(0, h * 0.85),
      Offset(w * 0.15, h * 0.7),
      Offset(w * 0.3, h * 0.9),
      Offset(w * 0.45, h * 0.5),
      Offset(w * 0.6, h * 0.4),
      Offset(w * 0.75, h * 0.6),
      Offset(w * 0.9, h * 0.2),
      Offset(w, h * 0.15),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // Gradient Fill
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0.25),
          AppTheme.primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // Line Stroke
    final strokePaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // End Point Dot
    final dotPaint = Paint()..color = AppTheme.primaryColor;
    canvas.drawCircle(points.last, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
