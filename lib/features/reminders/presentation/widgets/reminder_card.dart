import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../domain/reminder_entity.dart';

/// Card moderno de lembrete com indicador de status e estilo tech forward.
class ReminderTechCard extends StatelessWidget {
  const ReminderTechCard({
    super.key,
    required this.reminder,
    required this.statusType, // 'overdue', 'upcoming', 'future', 'completed'
    this.badgeText,
    this.currentMileage = 0,
    this.onTap,
    this.onComplete,
  });

  final ReminderEntity reminder;
  final String statusType;
  final String? badgeText;
  final int currentMileage;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final isDone = reminder.completed;
    final isOverdue = statusType == 'overdue';
    final isUpcoming = statusType == 'upcoming';

    final accentColor = isDone
        ? AppTheme.successColor
        : isOverdue
        ? AppTheme.errorColor
        : isUpcoming
        ? AppTheme.warningColor
        : AppTheme.primaryColor;

    final icon = _categoryIcon(reminder.category ?? '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue
                ? AppTheme.errorColor.withValues(alpha: 0.3)
                : AppTheme.borderSubtleColor,
            width: isOverdue ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? AppTheme.errorColor.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Accent Bar
              Container(height: 3, color: accentColor),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Box
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            isDone ? Icons.check_circle_rounded : icon,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      reminder.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimaryColor,
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (badgeText != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: accentColor.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        badgeText!,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _buildSubtitle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

                    // Bottom Action for Overdue or Active items
                    if (isOverdue && !isDone) ...[
                      const SizedBox(height: 12),
                      const Divider(
                        height: 1,
                        color: AppTheme.borderSubtleColor,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reminder.dueDate != null
                                ? 'Vencido em: ${Formatters.date(reminder.dueDate!)}'
                                : 'Vencido por km',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textMutedColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: onComplete,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Concluir agora',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (!isDone) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: onComplete,
                          child: Text(
                            'Marcar como concluído',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (reminder.category != null && reminder.category!.isNotEmpty) {
      parts.add(reminder.category!);
    }
    if (reminder.dueDate != null) {
      parts.add(Formatters.date(reminder.dueDate!));
    }
    if (reminder.dueMileage != null) {
      parts.add(Formatters.mileage(reminder.dueMileage!));
    }
    return parts.isEmpty ? 'Revisão preventiva' : parts.join(' • ');
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'Óleo e filtros' || 'Óleo & Filtros' => Icons.oil_barrel_outlined,
      'Freios' => Icons.disc_full_outlined,
      'Pneus' => Icons.tire_repair_outlined,
      'Motor' => Icons.precision_manufacturing_outlined,
      'Bateria' => Icons.battery_charging_full,
      'Seguro' || 'Documentação' => Icons.description_outlined,
      _ => Icons.notifications_none_rounded,
    };
  }
}
