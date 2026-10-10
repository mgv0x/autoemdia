import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../domain/maintenance_entity.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDetailPage extends ConsumerWidget {
  const MaintenanceDetailPage({super.key, required this.maintenance});

  final MaintenanceEntity maintenance;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir manutenção'),
        content: const Text(
          'Esta ação não pode ser desfeita. Deseja excluir este registro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
              foregroundColor: Theme.of(ctx).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(maintenanceFormControllerProvider.notifier)
        .delete(maintenance.id);
    if (context.mounted) {
      if (ok) {
        context.pop();
      } else {
        showAppSnackBar(
          context,
          ref.read(maintenanceFormControllerProvider).error?.toString() ??
              'Não foi possível excluir.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = maintenance;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                m.description,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Chip(
                avatar: const Icon(Icons.category_outlined, size: 16),
                label: Text(m.category),
              ),
              const SizedBox(height: 20),
              _detailRow(
                context,
                Icons.calendar_today,
                'Data',
                Formatters.date(m.serviceDate),
              ),
              if (m.mileage != null)
                _detailRow(
                  context,
                  Icons.speed_outlined,
                  'Quilometragem',
                  Formatters.mileage(m.mileage!),
                ),
              if (m.cost != null)
                _detailRow(
                  context,
                  Icons.attach_money,
                  'Valor',
                  Formatters.currency(m.cost!),
                ),
              if (m.part != null && m.part!.isNotEmpty)
                _detailRow(
                  context,
                  Icons.settings_suggest_outlined,
                  'Peça / Marca',
                  m.part!,
                ),
              if (m.workshop != null && m.workshop!.isNotEmpty)
                _detailRow(
                  context,
                  Icons.storefront_outlined,
                  'Oficina / Local',
                  m.workshop!,
                ),
              if (m.notes != null && m.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Observações',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(m.notes!),
              ],
              if (m.nextMileage != null || m.nextDate != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próxima manutenção',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (m.nextMileage != null)
                        Text('Aos ${Formatters.mileage(m.nextMileage!)}'),
                      if (m.nextDate != null)
                        Text('Em ${Formatters.date(m.nextDate!)}'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    context.push('/maintenance/${m.id}/edit', extra: m),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label:', style: text.bodyMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
