import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/pages/edit_transaction_page.dart';
import '../../../categories/domain/entities/category_entity.dart';

/// Página de Historial de Transacciones
///
/// Muestra todas las transacciones del usuario con filtros, búsqueda
/// y resumen de totales. Datos reales desde TransactionBloc.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'Todas';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()},$decPart €';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }

  IconData _getCategoryIcon(String category) {
    return CategoryEntity.getIconForName(category);
  }

  Color _getCategoryColor(String category) {
    return CategoryEntity.getColorForName(category);
  }

  List<TransactionEntity> _applyFilters(List<TransactionEntity> transactions) {
    var filtered = transactions.where((t) {
      if (_selectedFilter == 'Gastos') return t.isExpense;
      if (_selectedFilter == 'Ingresos') return t.isIncome;
      return true;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final desc = (t.description ?? '').toLowerCase();
        final cat = t.category.toLowerCase();
        return desc.contains(query) || cat.contains(query);
      }).toList();
    }

    return filtered;
  }

  Map<String, List<TransactionEntity>> _groupByDate(List<TransactionEntity> transactions) {
    final grouped = <String, List<TransactionEntity>>{};
    for (final t in transactions) {
      final key = _formatDateGroup(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<TransactionBloc>().add(LoadTransactions());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primary,
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 16,
                responsive.horizontalPadding, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('Transacciones', style: AppTypography.headlineSmall()),
                          // Indicador de transacciones pendientes de sincronizar (RNF-15)
                          BlocBuilder<TransactionBloc, TransactionState>(
                            builder: (context, state) {
                              final pending = state is TransactionsLoaded ? state.pendingSyncCount : 0;
                              if (pending == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.cloud_upload_outlined, size: 12, color: AppColors.warningDark),
                                      const SizedBox(width: 4),
                                      Text('$pending', style: AppTypography.badge(color: AppColors.warningDark)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/add-transaction'),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Summary bar with real data
                  _buildSummaryBar(),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: AppTypography.bodyMedium(),
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Buscar por descripción o categoría...',
                        hintStyle: AppTypography.bodyMedium(color: AppColors.textTertiaryLight),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray400, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.gray400),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter chips
                  Row(
                    children: [
                      _buildFilterChip('Todas'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Gastos'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ingresos'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Transactions list
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  final List<TransactionEntity> transactions =
                      state is TransactionsLoaded ? state.transactions : [];

                  if (transactions.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filtered = _applyFilters(transactions);

                  if (filtered.isEmpty) {
                    return _buildEmptyFilterState();
                  }

                  final grouped = _groupByDate(filtered);

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalPadding,
                    ),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final dateLabel = grouped.keys.elementAt(index);
                      final items = grouped[dateLabel]!;
                      return _buildDateGroup(dateLabel, items);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
        final expenses = state is TransactionsLoaded ? state.totalExpenses : 0.0;
        final count = state is TransactionsLoaded ? state.transactions.length : 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.south_west_rounded,
                  label: 'Ingresos',
                  value: _formatCurrency(income),
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.gray200),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.north_east_rounded,
                  label: 'Gastos',
                  value: _formatCurrency(expenses),
                  color: AppColors.error,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.gray200),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total',
                  value: '$count',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleSmall(color: color),
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: AppTypography.labelSmall()),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium(
            color: isSelected ? AppColors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildDateGroup(String dateLabel, List<TransactionEntity> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
          child: Text(
            dateLabel,
            style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
          ),
        ),
        ...items.map((t) => _buildTransactionItem(t)),
      ],
    );
  }

  /// Abre la página de edición de la transacción (RF-06)
  Future<void> _openEditPage(TransactionEntity t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(transaction: t),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionEntity t) {
    return Dismissible(
      key: Key(t.id ?? t.hashCode.toString()),
      direction: DismissDirection.horizontal,
      // Fondo deslizando a la derecha → Editar (RF-06)
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, color: AppColors.white),
            SizedBox(width: 6),
            Text(
              'Editar',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      // Fondo deslizando a la izquierda → Eliminar
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.delete_outline_rounded, color: AppColors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe derecha → abrir edición, no descartar
          await _openEditPage(t);
          return false;
        }
        // Swipe izquierda → confirmar eliminación
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
                const SizedBox(width: 10),
                const Text('Eliminar'),
              ],
            ),
            content: const Text('¿Eliminar esta transacción? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondaryLight)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (t.id != null) {
          context.read<TransactionBloc>().add(DeleteTransaction(transactionId: t.id!));
        }
      },
      child: GestureDetector(
        onTap: () => _openEditPage(t),
        child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: t.isPendingSync
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.gray100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _getCategoryColor(t.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(t.category),
                    color: _getCategoryColor(t.category),
                    size: 20,
                  ),
                  // Indicador de sincronización pendiente (RNF-15)
                  if (t.isPendingSync)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppColors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.cloud_upload_outlined, size: 8, color: AppColors.white),
                      ),
                    ),
                  // Indicador de error de sincronización (RNF-15)
                  if (t.hasSyncError)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppColors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.cloud_off_rounded, size: 8, color: AppColors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description?.isNotEmpty == true ? t.description! : t.category,
                    style: AppTypography.titleSmall(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        t.category,
                        style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.paymentMethod.label,
                          style: AppTypography.badge(color: AppColors.textTertiaryLight),
                        ),
                      ),
                      // Badge de pendiente de sync (RNF-15)
                      if (t.isPendingSync) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Pendiente',
                            style: AppTypography.badge(color: AppColors.warningDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${t.isExpense ? '-' : '+'}${_formatCurrency(t.amount)}',
                  style: AppTypography.titleSmall(
                    color: t.isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(t.date),
                  style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text('Sin transacciones aún', style: AppTypography.titleMedium()),
            const SizedBox(height: 8),
            Text(
              'Registra tu primera transacción\npulsando el botón +',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/add-transaction'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.shadowColor(AppColors.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: AppColors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Añadir transacción', style: AppTypography.button()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.filter_list_off_rounded,
                size: 32,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay resultados',
              style: AppTypography.titleMedium(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron transacciones\nque coincidan con "$_searchQuery"'
                  : 'No se encontraron transacciones\ncon este filtro',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(color: AppColors.textTertiaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
