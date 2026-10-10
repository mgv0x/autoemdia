import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/snackbar.dart';
import '../../domain/expense_entity.dart';
import '../controllers/expense_controller.dart';

class ExpenseDetailPage extends ConsumerWidget {
  const ExpenseDetailPage({super.key, required this.expense});

  final ExpenseEntity expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = expense;
    final text = Theme.of(context).textTheme;
    final isMaint = e.id.startsWith('maint_');
    final maintId = isMaint ? e.id.replaceFirst('maint_', '') : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMaint ? 'Gasto com Manutenção' : 'Detalhes do Gasto'),
        actions: [
          if (!isMaint)
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
                e.description,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.currency(e.amount),
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.category_outlined, size: 16),
                    label: Text(e.category),
                  ),
                  if (isMaint) ...[
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.build_rounded, size: 16),
                      label: const Text('Serviço'),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.tertiaryContainer,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              _row(
                context,
                Icons.calendar_today,
                'Data',
                Formatters.date(e.expenseDate),
              ),
              if (isMaint) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Este lançamento é proveniente do registro de uma manutenção.',
                          style: text.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/maintenance/$maintId'),
                  icon: const Icon(Icons.build_outlined),
                  label: const Text('Ver manutenção vinculada'),
                ),
              ] else ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/expenses/${e.id}/edit', extra: e),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ],
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
        title: const Text('Excluir gasto'),
        content: const Text('Deseja excluir este gasto?'),
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
        .read(expenseFormControllerProvider.notifier)
        .delete(expense.id);
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
