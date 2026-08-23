import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/app_states.dart';
import '../../../../../shared/widgets/app_top_bar.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../controllers/maintenance_controller.dart';
import '../widgets/maintenance_card.dart';

class MaintenanceListPage extends ConsumerStatefulWidget {
  const MaintenanceListPage({super.key});

  @override
  ConsumerState<MaintenanceListPage> createState() => _MaintenanceListPageState();
}

class _MaintenanceListPageState extends ConsumerState<MaintenanceListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(maintenanceListProvider);
    final currentFilter = ref.watch(maintenanceCategoryFilterProvider);
    final vehicle = ref.watch(activeVehicleProvider).value;

    final categories = ['Todos', ...AppConstants.maintenanceCategories];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const AppTopBar(title: 'Manutenções'),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton(
          onPressed: () => context.push('/maintenance/new'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      body: listAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorState(
          onRetry: () => ref.invalidate(maintenanceListProvider),
        ),
        data: (list) {
          var filtered = currentFilter == null
              ? list
              : list.where((m) => m.category == currentFilter).toList();

          if (_searchQuery.isNotEmpty) {
            filtered = filtered
                .where((m) =>
                    m.description.toLowerCase().contains(_searchQuery) ||
                    m.category.toLowerCase().contains(_searchQuery))
                .toList();
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(maintenanceListProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Headline
                        Text(
                          'Histórico',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search Input
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtleColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppTheme.textPrimaryColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar serviço ou peça...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textMutedColor,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppTheme.textMutedColor,
                                size: 22,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filter Pills Horizontal Scroll
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final cat = categories[i];
                              final isSelected = (cat == 'Todos' && currentFilter == null) ||
                                  (cat == currentFilter);

                              return InkWell(
                                onTap: () {
                                  ref
                                      .read(maintenanceCategoryFilterProvider.notifier)
                                      .set(cat == 'Todos' ? null : cat);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                          : AppTheme.borderSubtleColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cat,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : AppTheme.textMutedColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Timeline List Content
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.history_toggle_off,
                              size: 48,
                              color: AppTheme.textMutedColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentFilter == null
                                  ? 'Nenhuma manutenção registrada ainda.'
                                  : 'Nenhuma manutenção em "$currentFilter".',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: AppTheme.textMutedColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/maintenance/new'),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Registrar manutenção'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == filtered.length) {
                            // End of List Indicator
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.history_toggle_off_rounded,
                                    size: 36,
                                    color: AppTheme.borderSubtleColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fim do histórico de manutenções',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppTheme.textMutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final m = filtered[index];
                          final isLast = index == filtered.length - 1;

                          return _TimelineItemRow(
                            isFirst: index == 0,
                            isLast: isLast,
                            category: m.category,
                            child: MaintenanceTimelineCard(
                              title: m.description,
                              category: m.category,
                              date: m.serviceDate,
                              vehicleName: vehicle?.displayName,
                              mileage: m.mileage,
                              cost: m.cost,
                              onTap: () => context.push('/maintenance/${m.id}', extra: m),
                            ),
                          );
                        },
                        childCount: filtered.length + 1,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Linha da Timeline com nó circular e linha vertical
class _TimelineItemRow extends StatelessWidget {
  const _TimelineItemRow({
    required this.child,
    required this.category,
    required this.isFirst,
    required this.isLast,
  });

  final Widget child;
  final String category;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(category);
    final iconColor = _categoryColor(category);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Timeline Column
          SizedBox(
            width: 48,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Vertical Connecting Line
                Positioned(
                  top: isFirst ? 24 : 0,
                  bottom: isLast ? 24 : 0,
                  left: 23,
                  width: 2,
                  child: Container(color: AppTheme.borderSubtleColor),
                ),
                // Node Circle
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    return switch (cat) {
      'Óleo e filtros' || 'Óleo & Filtros' => AppTheme.primaryColor,
      'Freios' || 'Motor' => AppTheme.warningColor,
      _ => AppTheme.primaryColor,
    };
  }

  IconData _categoryIcon(String c) => switch (c) {
    'Óleo e filtros' || 'Óleo & Filtros' => Icons.oil_barrel_outlined,
    'Freios' => Icons.tire_repair_rounded,
    'Pneus' => Icons.album_outlined,
    'Motor' => Icons.precision_manufacturing_outlined,
    'Bateria' => Icons.battery_charging_full,
    'Lavagem' => Icons.local_car_wash_outlined,
    _ => Icons.build_outlined,
  };
}
