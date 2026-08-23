import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/services/calculation_service.dart';
import '../../../../../shared/widgets/app_states.dart';
import '../../../../../shared/widgets/app_top_bar.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../domain/reminder_entity.dart';
import '../controllers/reminder_controller.dart';
import '../widgets/reminder_card.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    final vehicle = ref.watch(activeVehicleProvider).value;
    final currentKm = vehicle?.currentMileage ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const AppTopBar(title: 'Lembretes'),
      body: remindersAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorState(
          onRetry: () => ref.invalidate(remindersProvider),
        ),
        data: (list) {
          final groups = _group(list, currentKm);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(remindersProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Overview Stats Bento Grid
                Row(
                  children: [
                    // Atrasados Bento Card
                    Expanded(
                      child: _BentoStatCard(
                        icon: Icons.warning_rounded,
                        iconColor: AppTheme.errorColor,
                        label: 'ATRASADOS',
                        count: groups.overdue.length,
                        subtitle: 'Ação imediata necessária',
                        textColor: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Próximos Bento Card
                    Expanded(
                      child: _BentoStatCard(
                        icon: Icons.schedule_rounded,
                        iconColor: AppTheme.warningColor,
                        label: 'PRÓXIMOS',
                        count: groups.upcoming.length,
                        subtitle: 'Atenção requerida breve',
                        textColor: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section: Atrasados
                if (groups.overdue.isNotEmpty) ...[
                  _SectionStatusHeader(
                    title: 'Atrasados',
                    color: AppTheme.errorColor,
                    isPulse: true,
                  ),
                  const SizedBox(height: 10),
                  ...groups.overdue.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReminderTechCard(
                        reminder: r,
                        statusType: 'overdue',
                        currentMileage: currentKm,
                        badgeText: _badgeText(r, currentKm, isOverdue: true),
                        onTap: () => context.push('/reminders/${r.id}', extra: r),
                        onComplete: () => _completeReminder(ref, r.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Section: Próximos
                if (groups.upcoming.isNotEmpty) ...[
                  _SectionStatusHeader(
                    title: 'Próximos',
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(height: 10),
                  ...groups.upcoming.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReminderTechCard(
                        reminder: r,
                        statusType: 'upcoming',
                        currentMileage: currentKm,
                        badgeText: _badgeText(r, currentKm),
                        onTap: () => context.push('/reminders/${r.id}', extra: r),
                        onComplete: () => _completeReminder(ref, r.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Section: Futuros
                if (groups.future.isNotEmpty) ...[
                  _SectionStatusHeader(
                    title: 'Futuros',
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 10),
                  ...groups.future.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReminderTechCard(
                        reminder: r,
                        statusType: 'future',
                        currentMileage: currentKm,
                        badgeText: _badgeText(r, currentKm),
                        onTap: () => context.push('/reminders/${r.id}', extra: r),
                        onComplete: () => _completeReminder(ref, r.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Section: Concluídos
                if (groups.completed.isNotEmpty) ...[
                  _SectionStatusHeader(
                    title: 'Concluídos',
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(height: 10),
                  ...groups.completed.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReminderTechCard(
                        reminder: r,
                        statusType: 'completed',
                        currentMileage: currentKm,
                        badgeText: 'Feito',
                        onTap: () => context.push('/reminders/${r.id}', extra: r),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Bottom Delight Illustration: "Tudo sob controle"
                _AllCaughtUpCard(
                  hasOverdue: groups.overdue.isNotEmpty,
                  onNewReminder: () => context.push('/reminders/new'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _completeReminder(WidgetRef ref, String id) {
    ref.read(reminderControllerProvider.notifier).complete(id);
  }

  String _badgeText(ReminderEntity r, int currentKm, {bool isOverdue = false}) {
    if (r.dueMileage != null) {
      final km = r.dueMileage! - currentKm;
      if (km <= 0) return '+${-km} km';
      if (km < 1000) return 'Em $km km';
    }
    if (r.dueDate != null) {
      final days = CalculationService.daysRemaining(r.dueDate!);
      if (days < 0) return 'Vencido';
      if (days == 0) return 'Hoje';
      if (days <= 30) return 'Em $days dias';
      final months = (days / 30).ceil();
      return '$months meses';
    }
    return 'Pendente';
  }

  ({
    List<ReminderEntity> overdue,
    List<ReminderEntity> upcoming,
    List<ReminderEntity> future,
    List<ReminderEntity> completed,
  }) _group(List<ReminderEntity> list, int currentKm) {
    final overdue = <ReminderEntity>[];
    final upcoming = <ReminderEntity>[];
    final future = <ReminderEntity>[];
    final completed = <ReminderEntity>[];

    for (final r in list) {
      if (r.completed) {
        completed.add(r);
        continue;
      }
      var isOverdue = false;
      var daysLeft = 1 << 30;
      var kmLeft = 1 << 30;

      if (r.dueDate != null) {
        daysLeft = CalculationService.daysRemaining(r.dueDate!);
        if (daysLeft < 0) isOverdue = true;
      }
      if (r.dueMileage != null) {
        kmLeft = r.dueMileage! - currentKm;
        if (kmLeft <= 0) isOverdue = true;
      }

      if (isOverdue) {
        overdue.add(r);
      } else {
        final urgency = daysLeft < kmLeft ? daysLeft : kmLeft;
        if (urgency <= 30 || kmLeft <= 500) {
          upcoming.add(r);
        } else {
          future.add(r);
        }
      }
    }

    return (
      overdue: overdue,
      upcoming: upcoming,
      future: future,
      completed: completed,
    );
  }
}

/// Bento Card de estatísticas com número grande
class _BentoStatCard extends StatelessWidget {
  const _BentoStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.subtitle,
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final String subtitle;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppTheme.textMutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabeçalho da seção com indicador luminoso
class _SectionStatusHeader extends StatelessWidget {
  const _SectionStatusHeader({
    required this.title,
    required this.color,
    this.isPulse = false,
  });

  final String title;
  final Color color;
  final bool isPulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Delightful Illustration Card no final da tela ("Tudo sob controle")
class _AllCaughtUpCard extends StatelessWidget {
  const _AllCaughtUpCard({required this.hasOverdue, required this.onNewReminder});
  final bool hasOverdue;
  final VoidCallback onNewReminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderSubtleColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          // Concentric Animated Circle Representation
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 28,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Tudo sob controle',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Você não tem nenhum lembrete crítico esquecido. Bom trabalho!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMutedColor,
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: onNewReminder,
            icon: const Icon(Icons.add_rounded, size: 18, color: AppTheme.primaryColor),
            label: Text(
              'Novo Lembrete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.borderSubtleColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
