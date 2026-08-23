import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/utils/formatters.dart';

/// Card de manutenção estilizado como item de linha do tempo.
class MaintenanceTimelineCard extends StatelessWidget {
  const MaintenanceTimelineCard({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    this.vehicleName,
    this.mileage,
    this.cost,
    this.onTap,
  });

  final String title;
  final String category;
  final DateTime date;
  final String? vehicleName;
  final int? mileage;
  final double? cost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Accent Bar
              Container(
                height: 4,
                color: statusColor,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vehicleName ?? category,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (cost != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              Formatters.currency(cost!),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date & Mileage Badges
                    Row(
                      children: [
                        _BadgePill(
                          icon: Icons.calendar_today_outlined,
                          label: Formatters.date(date),
                        ),
                        if (mileage != null) ...[
                          const SizedBox(width: 8),
                          _BadgePill(
                            icon: Icons.speed_outlined,
                            label: Formatters.mileage(mileage!),
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
      ),
    );
  }

  Color _statusColor(String cat) {
    return switch (cat) {
      'Óleo e filtros' || 'Óleo & Filtros' => AppTheme.successColor,
      'Freios' || 'Motor' => AppTheme.warningColor,
      'Pneus' || 'Suspensão' => AppTheme.primaryColor,
      _ => AppTheme.primaryColor,
    };
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMutedColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
