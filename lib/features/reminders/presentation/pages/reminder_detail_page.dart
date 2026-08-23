import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../domain/reminder_entity.dart';
import '../controllers/reminder_controller.dart';

class ReminderDetailPage extends ConsumerWidget {
  const ReminderDetailPage({super.key, required this.reminder});

  final ReminderEntity reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = reminder;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lembrete'),
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
                r.title,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (r.category != null) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 16),
                  label: Text(r.category!),
                ),
              ],
              const SizedBox(height: 20),
              if (r.dueDate != null)
                _row(
                  context,
                  Icons.calendar_today,
                  'Vencimento',
                  Formatters.date(r.dueDate!),
                ),
              if (r.dueMileage != null)
                _row(
                  context,
                  Icons.speed_outlined,
                  'Quilometragem',
                  Formatters.mileage(r.dueMileage!),
                ),
              _row(
                context,
                Icons.notifications,
                'Notificações',
                r.notificationEnabled ? 'Ativadas' : 'Desativadas',
              ),
              _row(
                context,
                Icons.task_alt,
                'Status',
                r.completed ? 'Concluído' : 'Pendente',
              ),
              const SizedBox(height: 32),
              if (!r.completed)
                FilledButton.icon(
                  onPressed: () async {
                    final ok = await ref
                        .read(reminderControllerProvider.notifier)
                        .complete(r.id);
                    if (context.mounted && ok) context.pop();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Marcar como concluído'),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/reminders/${r.id}/edit', extra: r),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await ref
                      .read(reminderControllerProvider.notifier)
                      .setNotificationEnabled(r, !r.notificationEnabled);
                  if (context.mounted) {
                    showAppSnackBar(
                      context,
                      ok
                          ? (r.notificationEnabled
                                ? 'Notificações desativadas.'
                                : 'Notificações ativadas.')
                          : 'Não foi possível atualizar.',
                      isError: !ok,
                    );
                    if (ok) context.pop();
                  }
                },
                icon: Icon(
                  r.notificationEnabled
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_outlined,
                ),
                label: Text(
                  r.notificationEnabled
                      ? 'Desativar notificações'
                      : 'Ativar notificações',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir lembrete'),
        content: const Text('Deseja excluir este lembrete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(reminderControllerProvider.notifier)
        .delete(reminder);
    if (context.mounted) {
      if (ok) {
        context.pop();
      } else {
        showAppSnackBar(context, 'Não foi possível excluir.', isError: true);
      }
    }
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
