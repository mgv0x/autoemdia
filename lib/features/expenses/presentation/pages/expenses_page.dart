import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/services/calculation_service.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/app_states.dart';
import '../../../../../shared/widgets/app_top_bar.dart';
import '../../domain/expense_entity.dart';
import '../controllers/expense_controller.dart';
import '../widgets/expenses_pie_chart.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const AppTopBar(title: 'Gastos'),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton(
          onPressed: () => context.push('/expenses/new'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      body: expensesAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorState(
          onRetry: () => ref.invalidate(expensesProvider),
        ),
        data: (list) {
          final byDateAmount = list.map(
            (e) => (date: e.expenseDate, amount: e.amount),
          );
          final byCatAmount = list.map(
            (e) => (category: e.category, amount: e.amount),
          );

          final monthTotal = CalculationService.totalForMonth(
            byDateAmount,
            now.year,
            now.month,
          );
          final yearTotal = CalculationService.totalForYear(
            byDateAmount,
            now.year,
          );
          final byCategory = CalculationService.totalsByCategory(byCatAmount);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(expensesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Resumo Financeiro Header
                Text(
                  'Resumo Financeiro',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Resumo Cards Grid
                Row(
                  children: [
                    // Este Mês
                    Expanded(
                      child: _ExpenseSummaryCard(
                        icon: Icons.calendar_today_rounded,
                        label: 'ESTE MÊS',
                        amount: monthTotal,
                        deltaText: '+12% vs. último',
                        isDeltaPositive: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Este Ano
                    Expanded(
                      child: _ExpenseSummaryCard(
                        icon: Icons.event_rounded,
                        label: 'ESTE ANO',
                        amount: yearTotal,
                        deltaText: '-5% vs. 2023',
                        isDeltaPositive: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Evolução de Gastos (Line Chart Card)
                _EvolutionChartCard(expenses: list),
                const SizedBox(height: 20),

                // Distribuição por Categoria Card
                Container(
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
                      Text(
                        'Distribuição por Categoria',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ExpensesDonutChart(totalsByCategory: byCategory),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Transações Recentes Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transações Recentes',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transações List Container
                if (list.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtleColor),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: AppTheme.textMutedColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhum gasto registrado ainda.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textMutedColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/expenses/new'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Adicionar gasto'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Container(
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
                          for (var i = 0; i < list.take(5).length; i++) ...[
                            if (i > 0)
                              const Divider(height: 1, color: AppTheme.borderSubtleColor),
                            _TransactionTile(
                              expense: list[i],
                              onTap: () => context.push('/expenses/${list[i].id}', extra: list[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Button Ver todas / Adicionar
                  OutlinedButton(
                    onPressed: () => context.push('/expenses/new'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.borderSubtleColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'ADICIONAR NOVO GASTO',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Card de resumo de gastos (Este Mês / Este Ano) com delta comparativo
class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.deltaText,
    required this.isDeltaPositive,
  });

  final IconData icon;
  final String label;
  final double amount;
  final String deltaText;
  final bool isDeltaPositive;

  @override
  Widget build(BuildContext context) {
    final deltaColor = isDeltaPositive ? AppTheme.successColor : AppTheme.errorColor;
    final deltaIcon = isDeltaPositive ? Icons.trending_down_rounded : Icons.trending_up_rounded;

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
              Icon(icon, size: 16, color: AppTheme.textMutedColor),
              const SizedBox(width: 6),
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
            Formatters.currency(amount),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(deltaIcon, size: 14, color: deltaColor),
              const SizedBox(width: 4),
              Text(
                deltaText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: deltaColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card de Evolução de Gastos com Gráfico de Linha em Área
class _EvolutionChartCard extends StatelessWidget {
  const _EvolutionChartCard({required this.expenses});
  final List<ExpenseEntity> expenses;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evolução de Gastos',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textMutedColor),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Mar', 'Mai', 'Jul', 'Set', 'Nov'];
                        final index = value.toInt();
                        if (index >= 0 && index < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[index],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textMutedColor,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 25),
                      FlSpot(1, 35),
                      FlSpot(2, 65),
                      FlSpot(3, 40),
                      FlSpot(4, 75),
                      FlSpot(5, 90),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.primaryColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.25),
                          AppTheme.primaryColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de transação recente
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.expense, required this.onTap});
  final ExpenseEntity expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(expense.category);
    final iconColor = _categoryColor(expense.category);

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
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
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
                    '${Formatters.date(expense.expenseDate)} • ${expense.category}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-${Formatters.currency(expense.amount)}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String c) => switch (c) {
    'Combustível' => Icons.local_gas_station_rounded,
    'Manutenção' || 'Peças' => Icons.build_rounded,
    'Estacionamento' => Icons.local_parking_rounded,
    'Lavagem' => Icons.local_car_wash_rounded,
    'Seguro' => Icons.verified_user_rounded,
    'Documentação' => Icons.description_rounded,
    _ => Icons.payments_rounded,
  };

  Color _categoryColor(String c) => switch (c) {
    'Combustível' => AppTheme.primaryColor,
    'Manutenção' || 'Peças' => AppTheme.tertiaryColor,
    'Seguro' => AppTheme.successColor,
    'Estacionamento' => const Color(0xFF0284C7),
    'Lavagem' => const Color(0xFF059669),
    _ => AppTheme.primaryColor,
  };
}
