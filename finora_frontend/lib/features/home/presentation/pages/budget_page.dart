/// Página de Presupuestos — RF-32
///
/// RF-32: Alertas de exceso de presupuesto
///  - Configuración de presupuesto mensual por categoría
///  - Barra de progreso con colores: verde (<60%), amarillo (60-80%), rojo (>80%)
///  - Estado actual del mes vs presupuesto
///  - Alertas visuales al superar 80% y 100%
///  - Histórico de cumplimiento
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// RF-32: Gestión visual de presupuestos mensuales por categoría.
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _apiClient = di.sl<ApiClient>();
  final _fmtMoney = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );

  // Estado
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _statuses = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _unbudgeted = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final [statusRes, budgetRes] = await Future.wait([
        _apiClient.get('/budget/status'),
        _apiClient.get('/budget'),
      ]);

      final statusData = statusRes.data as Map<String, dynamic>;
      final budgetData = budgetRes.data as Map<String, dynamic>;

      setState(() {
        _statuses = List<Map<String, dynamic>>.from(
          statusData['statuses'] ?? [],
        );
        _alerts = List<Map<String, dynamic>>.from(statusData['alerts'] ?? []);
        _unbudgeted = List<Map<String, dynamic>>.from(
          statusData['unbudgeted'] ?? [],
        );
        _budgets = List<Map<String, dynamic>>.from(budgetData['budgets'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Crear / editar presupuesto ─────────────────────────────────────────────

  Future<void> _showBudgetDialog({
    String? category,
    double? currentLimit,
  }) async {
    final catController = TextEditingController(text: category ?? '');
    final limitController = TextEditingController(
      text: currentLimit != null ? currentLimit.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          category != null ? 'Editar presupuesto' : 'Nuevo presupuesto',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category == null)
                TextFormField(
                  controller: catController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              if (category != null) ...[
                Text(category, style: AppTypography.titleSmall()),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: limitController,
                decoration: const InputDecoration(
                  labelText: 'Límite mensual (€)',
                  prefixText: '€ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  return (n == null || n <= 0)
                      ? 'Introduce un importe válido'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              try {
                await _apiClient.post(
                  '/budget',
                  data: {
                    'category': category ?? catController.text.trim(),
                    'monthly_limit': double.parse(
                      limitController.text.replaceAll(',', '.'),
                    ),
                  },
                );
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Presupuesto guardado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(String category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: Text('¿Eliminar el presupuesto de "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _apiClient.delete('/budget/${Uri.encodeComponent(category)}');
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text('Presupuestos', style: AppTypography.titleMedium()),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Estado actual'),
            Tab(text: 'Mis presupuestos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabs,
              children: [_buildStatusTab(), _buildBudgetsTab()],
            ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
        const SizedBox(height: 12),
        Text('Error al cargar datos', style: AppTypography.bodyMedium()),
        TextButton(onPressed: _loadData, child: const Text('Reintentar')),
      ],
    ),
  );

  // ── Tab: Estado actual ─────────────────────────────────────────────────────

  Widget _buildStatusTab() {
    if (_statuses.isEmpty && _alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.gray400,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin presupuestos configurados',
              style: AppTypography.bodyMedium(color: AppColors.gray500),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer presupuesto para hacer seguimiento',
              style: AppTypography.bodySmall(color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_alerts.isNotEmpty) ...[
            _buildAlertsBanner(),
            const SizedBox(height: 16),
          ],
          ..._statuses.map(_buildStatusCard),
          if (_unbudgeted.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Sin presupuesto',
              style: AppTypography.labelSmall(color: AppColors.gray500),
            ),
            const SizedBox(height: 8),
            ..._unbudgeted.map((u) => _buildUnbudgetedItem(u)),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertsBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_alerts.length} presupuesto${_alerts.length > 1 ? 's' : ''} con alerta activa',
              style: AppTypography.bodySmall(color: AppColors.warningDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> s) {
    final pct = (s['percentage'] as num).toDouble();
    final alertLevel = s['alert_level'] as String;
    Color barColor;
    if (alertLevel == 'critical') {
      barColor = AppColors.error;
    } else if (alertLevel == 'warning') {
      barColor = AppColors.warning;
    } else {
      barColor = pct > 60 ? AppColors.success : AppColors.success;
    }
    if (pct > 60 && alertLevel == 'ok') barColor = AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertLevel == 'critical'
              ? AppColors.error.withValues(alpha: 0.4)
              : alertLevel == 'warning'
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s['category'] as String,
                  style: AppTypography.titleSmall(),
                ),
              ),
              if (alertLevel == 'critical')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Superado',
                    style: AppTypography.labelSmall(color: AppColors.error),
                  ),
                )
              else if (alertLevel == 'warning')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '80% alcanzado',
                    style: AppTypography.labelSmall(color: AppColors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.gray100,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_fmtMoney.format(s['spent'])} de ${_fmtMoney.format(s['monthly_limit'])}',
                style: AppTypography.bodySmall(color: AppColors.gray600),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: AppTypography.labelSmall(color: barColor),
              ),
            ],
          ),
          if (s['remaining'] > 0)
            Text(
              'Restante: ${_fmtMoney.format(s['remaining'])}',
              style: AppTypography.bodySmall(color: AppColors.gray400),
            ),
        ],
      ),
    );
  }

  Widget _buildUnbudgetedItem(Map<String, dynamic> u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              u['category'] as String,
              style: AppTypography.bodyMedium(),
            ),
          ),
          Text(
            _fmtMoney.format(u['spent']),
            style: AppTypography.bodySmall(color: AppColors.gray500),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () =>
                _showBudgetDialog(category: u['category'] as String),
            child: const Text('Añadir límite'),
          ),
        ],
      ),
    );
  }

  // ── Tab: Mis presupuestos ──────────────────────────────────────────────────

  Widget _buildBudgetsTab() {
    if (_budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wallet_outlined, color: AppColors.gray400, size: 56),
            const SizedBox(height: 16),
            Text(
              'No tienes presupuestos aún',
              style: AppTypography.bodyMedium(color: AppColors.gray500),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showBudgetDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear presupuesto'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _budgets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final b = _budgets[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['category'] as String,
                      style: AppTypography.titleSmall(),
                    ),
                    Text(
                      _fmtMoney.format(b['monthly_limit']),
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.gray500,
                  size: 20,
                ),
                onPressed: () => _showBudgetDialog(
                  category: b['category'] as String,
                  currentLimit: (b['monthly_limit'] as num).toDouble(),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: () => _deleteBudget(b['category'] as String),
              ),
            ],
          ),
        );
      },
    );
  }
}
