import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/services/calculation_service.dart';
import '../../../../../core/services/financial_calculation_service.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/app_states.dart';
import '../../../../../shared/widgets/app_top_bar.dart';
import '../../../settings/presentation/widgets/mileage_update_dialog.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../domain/expense_entity.dart';
import '../controllers/expense_controller.dart';
import '../widgets/expenses_pie_chart.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final vehicle = ref.watch(activeVehicleProvider).value;
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
        error: (e, _) =>
            AppErrorState(onRetry: () => ref.invalidate(expensesProvider)),
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

          // Custo por km & Média mensal (Regras puras da Fase 5)
          final costPerKmResult = vehicle != null
              ? FinancialCalculationService.calculateCostPerKm(
                  totalCost: CalculationService.totalAll(byDateAmount),
                  startMileage: vehicle.initialMileage,
                  currentMileage: vehicle.currentMileage,
                )
              : null;

          final monthlyAverageResult =
              FinancialCalculationService.calculateMonthlyAverage(byDateAmount);

          // Breakdown "Quanto custa ter meu veículo"
          final categoryBreakdown =
              FinancialCalculationService.calculateCategoryBreakdown(
                byCatAmount,
              );

          // Comparativo Mês Anterior
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
          final lastMonthTotal = CalculationService.totalForMonth(
            byDateAmount,
            lastMonthYear,
            lastMonth,
          );

          final lastYearTotal = CalculationService.totalForYear(
            byDateAmount,
            now.year - 1,
          );

          String monthDeltaText;
          bool monthDeltaPositive = true;
          if (lastMonthTotal > 0) {
            final diffPercent =
                (((monthTotal - lastMonthTotal) / lastMonthTotal) * 100)
                    .round();
            if (diffPercent > 0) {
              monthDeltaText = '+$diffPercent% vs. mês anterior';
              monthDeltaPositive = false;
            } else if (diffPercent < 0) {
              monthDeltaText = '$diffPercent% vs. mês anterior';
              monthDeltaPositive = true;
            } else {
              monthDeltaText = 'Igual ao mês anterior';
              monthDeltaPositive = true;
            }
          } else {
            monthDeltaText = 'Total deste mês';
            monthDeltaPositive = true;
          }

          String yearDeltaText;
          bool yearDeltaPositive = true;
          if (lastYearTotal > 0) {
            final diffPercent =
                (((yearTotal - lastYearTotal) / lastYearTotal) * 100).round();
            if (diffPercent > 0) {
              yearDeltaText = '+$diffPercent% vs. ${now.year - 1}';
              yearDeltaPositive = false;
            } else if (diffPercent < 0) {
              yearDeltaText = '$diffPercent% vs. ${now.year - 1}';
              yearDeltaPositive = true;
            } else {
              yearDeltaText = 'Igual a ${now.year - 1}';
              yearDeltaPositive = true;
            }
          } else {
            yearDeltaText = 'Total em ${now.year}';
            yearDeltaPositive = true;
          }

          // Filtragem de transações
          final filteredTransactions = _selectedCategory == null
              ? list
              : list.where((e) => e.category == _selectedCategory).toList();

          final isPremium = ref.watch(isPremiumProvider).value ?? false;

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

                // Resumo Cards Grid (Este Mês / Este Ano)
                Row(
                  children: [
                    // Este Mês
                    Expanded(
                      child: _ExpenseSummaryCard(
                        icon: Icons.calendar_today_rounded,
                        label: 'ESTE MÊS',
                        amount: monthTotal,
                        deltaText: monthDeltaText,
                        isDeltaPositive: monthDeltaPositive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Este Ano
                    Expanded(
                      child: _ExpenseSummaryCard(
                        icon: Icons.event_rounded,
                        label: 'ESTE ANO',
                        amount: yearTotal,
                        deltaText: yearDeltaText,
                        isDeltaPositive: yearDeltaPositive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Custo por KM & Média Mensal Card
                _CostMetricsCard(
                  costPerKmResult: costPerKmResult,
                  monthlyAverageResult: monthlyAverageResult,
                  isPremium: isPremium,
                  onTapPremium: () => context.push('/premium'),
                ),
                const SizedBox(height: 18),

                // Quick Actions Rápidas (Abastecimento, Manutenção, Gasto, Atualizar Km)
                _QuickActionsRow(
                  onFuel: () =>
                      context.push('/expenses/new?category=Combustível'),
                  onMaintenance: () => context.push('/maintenance/new'),
                  onExpense: () => context.push('/expenses/new'),
                  onMileage: vehicle != null
                      ? () => showMileageUpdateDialog(
                          context,
                          ref: ref,
                          vehicle: vehicle,
                        )
                      : null,
                ),
                const SizedBox(height: 22),

                // Evolução de Gastos (Line Chart Card)
                _EvolutionChartCard(expenses: list),
                const SizedBox(height: 20),

                // Seção: "Quanto custa ter meu veículo" (Detalhamento por categoria)
                _VehicleCostBreakdownCard(
                  totalsByCategory: byCategory,
                  breakdown: categoryBreakdown,
                  isPremium: isPremium,
                  onTapPremium: () => context.push('/premium'),
                ),
                const SizedBox(height: 26),

                // Transações Recentes Section com Filtros
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Histórico de Gastos',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (_selectedCategory != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedCategory = null),
                        child: Text(
                          'Limpar filtro',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filtro por Categoria Pills
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterPill(
                        label: 'Todos',
                        isSelected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      ...categoryBreakdown.keys.map(
                        (cat) => _FilterPill(
                          label: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() => _selectedCategory = cat),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Transações List Container
                if (filteredTransactions.isEmpty)
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
                            _selectedCategory != null
                                ? 'Nenhum gasto em "$_selectedCategory".'
                                : 'Nenhum gasto registrado ainda.',
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
                          for (
                            var i = 0;
                            i < filteredTransactions.take(8).length;
                            i++
                          ) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: AppTheme.borderSubtleColor,
                              ),
                            _TransactionTile(
                              expense: filteredTransactions[i],
                              onTap: () {
                                final e = filteredTransactions[i];
                                if (e.id.startsWith('maint_')) {
                                  final maintId = e.id.replaceFirst(
                                    'maint_',
                                    '',
                                  );
                                  context.push('/maintenance/$maintId');
                                } else {
                                  context.push(
                                    '/expenses/${e.id}',
                                    extra: e,
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Button Adicionar Novo Gasto
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

/// Barra de Ações Rápidas (Abastecimento, Manutenção, Gasto, Km)
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onFuel,
    required this.onMaintenance,
    required this.onExpense,
    this.onMileage,
  });

  final VoidCallback onFuel;
  final VoidCallback onMaintenance;
  final VoidCallback onExpense;
  final VoidCallback? onMileage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.local_gas_station_rounded,
            label: '+ Abastecer',
            color: AppTheme.primaryColor,
            onTap: onFuel,
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.build_rounded,
            label: '+ Manutenção',
            color: AppTheme.tertiaryColor,
            onTap: onMaintenance,
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: '+ Gasto',
            color: AppTheme.successColor,
            onTap: onExpense,
          ),
          if (onMileage != null) ...[
            const SizedBox(width: 8),
            _QuickActionButton(
              icon: Icons.speed_outlined,
              label: 'Atualizar km',
              color: const Color(0xFF0284C7),
              onTap: onMileage!,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de Custo por KM e Média Mensal
class _CostMetricsCard extends StatelessWidget {
  const _CostMetricsCard({
    required this.costPerKmResult,
    required this.monthlyAverageResult,
    required this.isPremium,
    required this.onTapPremium,
  });

  final CostPerKmResult? costPerKmResult;
  final MonthlyAverageResult monthlyAverageResult;
  final bool isPremium;
  final VoidCallback onTapPremium;

  @override
  Widget build(BuildContext context) {
    final costResult = costPerKmResult;

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
          // Custo por KM
          Expanded(
            child: !isPremium
                ? InkWell(
                    onTap: onTapPremium,
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: AppTheme.tertiaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CUSTO POR KM',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppTheme.textMutedColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PRO',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tertiaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Desbloquear',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Disponível no Premium',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.speed_outlined,
                            size: 14,
                            color: AppTheme.textMutedColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CUSTO POR KM',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textMutedColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (costResult != null &&
                          costResult.hasEnoughData &&
                          costResult.costPerKm != null) ...[
                        Text(
                          '${Formatters.currency(costResult.costPerKm!)}/km',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${costResult.kmDriven} km rodados',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Em formação',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          costResult?.message ?? 'Rode 100 km para calcular',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          Container(width: 1, height: 48, color: AppTheme.borderSubtleColor),
          const SizedBox(width: 14),

          // Média Mensal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 14,
                      color: AppTheme.textMutedColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'MÉDIA MENSAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (monthlyAverageResult.hasEnoughData &&
                    monthlyAverageResult.averageAmount != null) ...[
                  Text(
                    Formatters.currency(monthlyAverageResult.averageAmount!),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${monthlyAverageResult.distinctMonthsCount} meses com gastos',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Sem registros',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cadastre gastos no mês',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card "Quanto custa ter meu veículo" com gráfico Donut e detalhamento categórico
class _VehicleCostBreakdownCard extends StatelessWidget {
  const _VehicleCostBreakdownCard({
    required this.totalsByCategory,
    required this.breakdown,
    required this.isPremium,
    required this.onTapPremium,
  });

  final Map<String, double> totalsByCategory;
  final Map<String, CategoryFinancialSummary> breakdown;
  final bool isPremium;
  final VoidCallback onTapPremium;

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
                'Quanto custa ter seu veículo',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Icon(
                Icons.pie_chart_outline_rounded,
                size: 20,
                color: AppTheme.textMutedColor,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Donut Chart
          ExpensesDonutChart(totalsByCategory: totalsByCategory),
          const SizedBox(height: 20),

          const Divider(height: 1, color: AppTheme.borderSubtleColor),
          const SizedBox(height: 16),

          // Lista de Categorias com barras de proporção
          ...breakdown.values.map((item) => _CategoryDetailRow(summary: item)),

          if (!isPremium) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: onTapPremium,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.tertiaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppTheme.tertiaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Custo Total de Propriedade',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
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
                                  'PREMIUM',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Histórico vitalício e custo acumulado completo',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.tertiaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryDetailRow extends StatelessWidget {
  const _CategoryDetailRow({required this.summary});

  final CategoryFinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(summary.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary.category,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              if (summary.hasData) ...[
                Text(
                  Formatters.currency(summary.totalAmount),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${summary.percentage.toStringAsFixed(0)}%)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMutedColor,
                  ),
                ),
              ] else ...[
                Text(
                  'R\$ 0,00',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppTheme.textMutedColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Sem gastos',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (summary.hasData && summary.percentage > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: summary.percentage / 100.0,
                minHeight: 4,
                backgroundColor: AppTheme.surfaceVariantColor,
                valueColor: AlwaysStoppedAnimation<Color>(catColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _categoryColor(String c) => switch (c) {
    'Combustível' => AppTheme.primaryColor,
    'Manutenção' || 'Peças' => AppTheme.tertiaryColor,
    'Seguro' => AppTheme.successColor,
    'Estacionamento' => const Color(0xFF0284C7),
    'Lavagem' => const Color(0xFF059669),
    'Documentação' || 'Impostos' => const Color(0xFFD97706),
    _ => const Color(0xFF64748B),
  };
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.borderSubtleColor,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textMutedColor,
            ),
          ),
        ),
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
    final deltaColor = isDeltaPositive
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final deltaIcon = isDeltaPositive
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;

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
              Expanded(
                child: Text(
                  deltaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: deltaColor,
                  ),
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
    final now = DateTime.now();
    const monthNames = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    // Últimos 6 meses
    final monthsData = <({String label, double total})>[];
    for (var i = 5; i >= 0; i--) {
      var y = now.year;
      var m = now.month - i;
      while (m <= 0) {
        m += 12;
        y -= 1;
      }
      final total = CalculationService.totalForMonth(
        expenses.map((e) => (date: e.expenseDate, amount: e.amount)),
        y,
        m,
      );
      monthsData.add((label: monthNames[m - 1], total: total));
    }

    final maxVal = monthsData
        .map((e) => e.total)
        .fold(0.0, (a, b) => a > b ? a : b);
    final chartMaxY = maxVal > 0 ? maxVal * 1.25 : 100.0;

    final spots = <FlSpot>[
      for (var i = 0; i < monthsData.length; i++)
        FlSpot(i.toDouble(), monthsData[i].total),
    ];

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
              Text(
                'Últimos 6 meses',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY > 0 ? chartMaxY / 3 : 25,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppTheme.borderSubtleColor,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < monthsData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              monthsData[index].label,
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
                maxX: (monthsData.length - 1).toDouble(),
                minY: 0,
                maxY: chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.primaryColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: maxVal > 0,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: AppTheme.primaryColor,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          ),
                    ),
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

/// Tile de transação com identificação de manutenção integrada
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.expense, required this.onTap});
  final ExpenseEntity expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMaint = expense.id.startsWith('maint_');
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expense.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      if (isMaint) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiaryColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Serviço',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tertiaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${Formatters.date(expense.expenseDate)} • ${expense.category}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
    'Documentação' || 'Impostos' => Icons.description_rounded,
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
