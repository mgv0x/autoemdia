import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/services/calculation_service.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/app_states.dart';
import '../../../../../shared/widgets/app_top_bar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
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

    final firstName = auth?.name.isNotEmpty == true ? auth!.name.split(' ').first : 'Marcus';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const AppTopBar(title: 'Início'),
      body: dataAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorState(
          onRetry: () {
            ref.invalidate(vehiclesProvider);
            ref.invalidate(dashboardDataProvider);
          },
        ),
        data: (d) {
          if (vehicles.hasValue && vehicles.value!.isEmpty) {
            return AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: 'Comece cadastrando seu veículo',
              message: 'Adicione seu carro para acompanhar manutenções, gastos e lembretes.',
              actionLabel: 'Cadastrar veículo',
              onAction: () => context.push('/vehicle/new?first=true'),
            );
          }

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
                      'Veja como está seu carro hoje.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Vehicle Hero Card
                _VehicleHeroCard(vehicle: d.vehicle),
                const SizedBox(height: 16),

                // Status Overview Card
                _StatusOverviewCard(
                  overdueCount: d.overdueCount,
                  totalReminders: d.upcomingReminders.length + d.overdueCount,
                ),
                const SizedBox(height: 16),

                // Metrics Bento Grid (Gastos este ano + Próxima manutenção)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spending Card
                    Expanded(
                      child: _SpendingCard(
                        amount: d.yearTotal,
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
}

/// Hero Card com imagem estilizada do veículo, linha de status e gradiente.
class _VehicleHeroCard extends StatelessWidget {
  const _VehicleHeroCard({this.vehicle});
  final VehicleEntity? vehicle;

  @override
  Widget build(BuildContext context) {
    final name = vehicle?.displayName ?? 'Honda Civic';
    final year = vehicle?.year != null ? '${vehicle!.year} • ' : '2018 • ';
    final mileage = vehicle?.currentMileage != null
        ? Formatters.mileage(vehicle!.currentMileage)
        : '92.450 km';
    final photo = vehicle?.photoPath;

    return Container(
      height: 190,
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
            // Vehicle Background Image
            if (photo != null && File(photo).existsSync())
              Image.file(
                File(photo),
                fit: BoxFit.cover,
              )
            else
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCDCZjp0k6Aqu4MZ0Efd8hcL_ZjluEE2RWyuffhVJcPE7l8nJDR6V7wIyIcA1w4XERye6XX3fo69aIJAHVYg3BH91WxibrA98lLMt8yX2wCBanC67-1uzEWrAyguSshpItN_QhUJG0fljUGLrI4uK_eb3bbA9VtxV0mXsgFhdHZwfoYNPIh7XAIVm_BFdmKTbS-a4h80joXrlxLNOM-BkN1mNMUnbqqTlPGD-F7NHeQDgD5bYBCWM_ROQ',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(
                    child: Icon(Icons.directions_car_filled, size: 72, color: Colors.white24),
                  ),
                ),
              ),

            // Top Status Bar (green line)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(color: AppTheme.successColor),
            ),

            // Bottom Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.6, 1.0],
                  colors: [
                    Color(0xF00F172A),
                    Color(0x800F172A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Vehicle Text & Switch Button
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
                  InkWell(
                    onTap: () => vehicle != null
                        ? context.push('/vehicle/edit', extra: vehicle)
                        : context.push('/my-car'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Trocar',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de visão geral do status do veículo com badge âmbar/verde.
class _StatusOverviewCard extends StatelessWidget {
  const _StatusOverviewCard({
    required this.overdueCount,
    required this.totalReminders,
  });

  final int overdueCount;
  final int totalReminders;

  @override
  Widget build(BuildContext context) {
    final hasAttention = overdueCount > 0;
    final iconColor = hasAttention ? AppTheme.warningColor : AppTheme.successColor;
    final iconData = hasAttention ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded;
    final title = hasAttention ? 'Seu carro está em dia.' : 'Seu carro está 100% em dia.';
    final subtitle = hasAttention
        ? '$overdueCount item(ns) precisam de atenção.'
        : 'Nenhuma pendência para o momento.';

    return Container(
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }
}

/// Bento Card: Gastos este ano com mini sparkline chart.
class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.amount, required this.onTap});
  final double amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                    'GASTOS ESTE ANO',
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
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Sparkline Visual
            SizedBox(
              height: 42,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bento Card: Próxima Manutenção com progress bar.
class _NextMaintenanceBentoCard extends StatelessWidget {
  const _NextMaintenanceBentoCard({required this.data, required this.onTap});
  final DashboardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final next = data.nextMaintenance;
    final vehicle = data.vehicle;

    String title = 'Troca de óleo';
    String subtitle = 'Faltam 550 km';
    double percent = 0.85;

    if (next != null) {
      title = next.title;
      if (vehicle != null && next.dueMileage != null) {
        final km = next.dueMileage! - vehicle.currentMileage;
        subtitle = km <= 0 ? 'Vencido em ${-km} km' : 'Faltam $km km';
        percent = ((vehicle.currentMileage / next.dueMileage!).clamp(0.0, 1.0));
      } else if (next.dueDate != null) {
        final days = CalculationService.daysRemaining(next.dueDate!);
        subtitle = days < 0 ? 'Vencido há ${-days} d' : 'Em $days dias';
        percent = 0.75;
      }
    } else {
      title = 'Tudo em dia';
      subtitle = 'Sem revisões';
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
                    'PRÓXIMA REVISÃO',
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMutedColor,
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
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ],
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
              const Icon(Icons.history_toggle_off, size: 36, color: AppTheme.textMutedColor),
              const SizedBox(height: 8),
              Text(
                'Nenhuma manutenção registrada recentemente.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMutedColor),
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
              if (i > 0) const Divider(height: 1, color: AppTheme.borderSubtleColor),
              _HistoryItemTile(
                maintenance: maintenances[i],
                onTap: () => context.push('/maintenance/${maintenances[i].id}', extra: maintenances[i]),
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
    final cost = maintenance.cost != null ? Formatters.currency(maintenance.cost as double) : null;

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
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
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
