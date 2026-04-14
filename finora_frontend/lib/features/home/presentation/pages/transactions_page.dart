import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Importante para formatos de moneda/fecha localizados

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart'; // Import de traducciones
import '../../../../core/services/currency_service.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/pages/edit_transaction_page.dart';
import '../../../categories/domain/entities/category_entity.dart';

/// Página de Historial de Transacciones (RF-08)
///
/// Muestra todas las transacciones del usuario con filtros avanzados:
/// - Filtro por tipo (ingreso/gasto)
/// - Filtro por rango de fechas
/// - Filtro por categoría (selección múltiple)
/// - Filtro por método de pago
/// - Indicador visual de filtros activos
/// - Opción de limpiar todos los filtros
/// - Scroll infinito para grandes cantidades
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => TransactionsPageState();
}

/// RF-12: clase pública para permitir GlobalKey< TransactionsPageState > desde home_page.dart
class TransactionsPageState extends State<TransactionsPage> {
  // ─── Filtro básico de tipo (RF-08) ──────────────────────────────────────────
  /// Usamos un identificador interno. La traducción se hace en la interfaz.
  /// 'all', 'expense', 'income'
  String _selectedFilter = 'Todas';

  // ─── Búsqueda (RF-09) ──────────────────────────────────────────────────────
  final _searchController = TextEditingController();

  /// Texto mostrado en el campo (actualización inmediata para el botón de limpiar)
  String _searchText = '';

  /// Query con debounce de 300ms — usado para el motor de búsqueda (Nota Técnica)
  String _searchQuery = '';
  Timer? _debounceTimer;

  // ─── Filtros avanzados (RF-08) ──────────────────────────────────────────────
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  final Set<String> _filterCategories = {};
  final Set<PaymentMethod> _filterPaymentMethods = {};

  // ─── RF-12: Filtro por cuenta bancaria ──────────────────────────────────────
  String? _filterBankAccountId;
  String? _filterBankAccountName;

  // ─── Tablet: transacción seleccionada para el panel derecho ─────────────────
  TransactionEntity? _selectedTransaction;

  // ─── Scroll infinito (RNF-20) ────────────────────────────────────────────────
  static const int _pageSize = 20;
  int _displayCount = _pageSize;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Detecta cuando el usuario llega al final de la lista y carga más elementos.
  /// RNF-20: Cuando se agotan los datos en memoria y el servidor tiene más
  /// páginas, se despacha LoadMoreTransactions para cargar el siguiente lote.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<TransactionBloc>().state;
      if (state is TransactionsLoaded &&
          state.hasMorePages &&
          _displayCount >= state.transactions.length - _pageSize) {
        context.read<TransactionBloc>().add(LoadMoreTransactions());
      }
      setState(() => _displayCount += _pageSize);
    }
  }

  /// Retorna true si hay algún filtro avanzado activo (RF-08)
  bool get _hasAdvancedFilters =>
      _filterDateFrom != null ||
      _filterDateTo != null ||
      _filterCategories.isNotEmpty ||
      _filterPaymentMethods.isNotEmpty ||
      _filterBankAccountId != null;

  /// Número de filtros avanzados activos para mostrar en el badge visual (RF-08)
  int get _activeFilterCount {
    int count = 0;
    if (_filterDateFrom != null || _filterDateTo != null) count++;
    count += _filterCategories.length;
    count += _filterPaymentMethods.length;
    if (_filterBankAccountId != null) count++;
    return count;
  }

  /// Limpia todos los filtros activos y resetea el scroll (RF-08)
  void _clearAllFilters() {
    _debounceTimer?.cancel();
    setState(() {
      _selectedFilter = 'Todas'; // Clave interna
      _searchText = '';
      _searchQuery = '';
      _searchController.clear();
      _filterDateFrom = null;
      _filterDateTo = null;
      _filterCategories.clear();
      _filterPaymentMethods.clear();
      _filterBankAccountId = null;
      _filterBankAccountName = null;
      _displayCount = _pageSize;
    });
  }

  /// RF-12: Filtra las transacciones por una cuenta bancaria específica
  void filterByBankAccount(String accountId, String accountName) {
    setState(() {
      _filterBankAccountId = accountId;
      _filterBankAccountName = accountName;
      _displayCount = _pageSize;
    });
  }

  // ─── Helpers de Formato Localizado (i18n) ──────────────────────────────────

  String _formatCurrency(double amount) => CurrencyService().format(amount);

  /// Formatea la fecha de forma amigable (Hoy, Ayer o 12 Mar 2024)
  String _formatDate(DateTime date) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return s.today;
    if (dateOnly == yesterday) return s.yesterday;

    // Formato localizado corto: ej. 12 mar 2024 o Mar 12, 2024
    return DateFormat.yMMMd(locale).format(date);
  }

  /// Formatea la fecha para el encabezado de grupo (ej: 12 de Marzo o March 12)
  String _formatDateGroup(DateTime date) {
    final s = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return s.today;
    if (dateOnly == yesterday) return s.yesterday;

    // Usamos el constructor dinámico para nombres de mes traducidos
    final monthName = s.monthNames[date.month - 1];
    return s.dateGroupLabel(date.day, monthName);
  }

  /// Genera la etiqueta de texto para el rango de fechas activo (RF-08)
  /// Ejemplo: "12 mar 2026 – 15 mar 2026" o "Desde 12 mar 2026"
  String _buildActiveDateRangeLabel() {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    if (_filterDateFrom != null && _filterDateTo != null) {
      return '${DateFormat.yMMMd(locale).format(_filterDateFrom!)} – ${DateFormat.yMMMd(locale).format(_filterDateTo!)}';
    } else if (_filterDateFrom != null) {
      return '${s.fromLabel} ${DateFormat.yMMMd(locale).format(_filterDateFrom!)}';
    } else if (_filterDateTo != null) {
      return '${s.toLabel} ${DateFormat.yMMMd(locale).format(_filterDateTo!)}';
    }
    return '';
  }

  /// Formatea fecha corta para filtros (ej: 12/03/2024)
  String _formatDateShort(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(date);
  }

  // ─── Categorías ──────────────────────────────────────────────────────────

  IconData _getCategoryIcon(String category) {
    return CategoryEntity.getIconForName(category);
  }

  Color _getCategoryColor(String category) {
    return CategoryEntity.getColorForName(category);
  }

  /// Traduce el nombre de la categoría del backend a la UI localizada
  String _getTranslatedCategory(String categoryKey) {
    final s = AppLocalizations.of(context);
    final key = categoryKey.toLowerCase().trim();
    switch (key) {
      case 'alimentación':
      case 'food':
        return s.nutrition;
      case 'transporte':
      case 'transport':
        return s.transport;
      case 'ahorro':
        return s.saving;
      case 'ocio':
      case 'leisure':
        return s.leisure;
      case 'salud':
      case 'health':
        return s.health;
      case 'vivienda':
      case 'housing':
        return s.housing;
      case 'servicios':
      case 'services':
        return s.services;
      case 'suscripciones':
      case 'subscriptions':
        return s.tabSubscriptions;
      case 'otros':
        return s.other;
      case 'salario':
        return s.salary;
      case 'otros ingresos':
        return s.other;
      default:
        if (categoryKey.isEmpty) return '';
        // Capitalización por defecto si no hay traducción
        return categoryKey[0].toUpperCase() + categoryKey.substring(1);
    }
  }

  String _translatePaymentMethod(BuildContext context, String method) {
    final s = AppLocalizations.of(context);

    // Normalizamos: pasamos a minúsculas y quitamos espacios extra para asegurar el match
    final m = method.toLowerCase().trim();

    switch (m) {
      // --- Efectivo ---
      case 'efectivo':
      case 'cash':
        return s.paymentCash;

      // --- Tarjetas ---
      case 'tarjeta de débito':
      case 'débito':
      case 'debit card':
        return s.pmDebitCard;
      case 'tarjeta de crédito':
      case 'crédito':
      case 'credit card':
        return s.pmCreditCard;
      case 'tarjeta prepago':
      case 'prepago':
      case 'prepaid card':
        return s.pmPrepaidCard;
      case 'tarjeta':
      case 'card':
        return s.pmCard;

      // --- Transferencias ---
      case 'transferencia bancaria':
      case 'transferencia':
      case 'bank transfer':
      case 'transfer.': // Por si viene con el punto del label corto
        return s.pmBankTransfer;
      case 'transferencia sepa':
      case 'sepa':
        return s.pmSepa;
      case 'transferencia internacional':
      case 'wire':
        return s.pmWire;

      // --- Bancarios / Recibos ---
      case 'domiciliación/recibo':
      case 'recibo':
      case 'direct debit':
        return s.pmDirectDebit;
      case 'cheque':
      case 'check':
        return s.paymentCheque;
      case 'cupón/vale':
      case 'vale':
      case 'voucher':
        return s.pmVoucher;

      // --- Digitales (Nombres propios, se quedan igual) ---
      case 'bizum':
        return 'Bizum';
      case 'paypal':
        return 'PayPal';
      case 'apple pay':
        return 'Apple Pay';
      case 'google pay':
        return 'Google Pay';

      // --- Cripto ---
      case 'criptomonedas':
      case 'cripto':
      case 'crypto':
        return s.pmCrypto;

      // --- Fallback ---
      default:
        // Si no hay match, devolvemos el texto original capitalizado
        if (method.isEmpty) return '';
        return method[0].toUpperCase() + method.substring(1);
    }
  }

  // ─── Fuzzy Search (Nota Técnica RF-09) ─────────────────────────────────────

  /// Implementación de la Distancia de Levenshtein (RNF-09).
  /// Calcula el número mínimo de ediciones para transformar una cadena en otra.
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final matrix = List.generate(
      s.length + 1,
      (i) => List<int>.filled(t.length + 1, 0),
    );

    for (int i = 0; i <= s.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= t.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        final cost = s[i - 1].toLowerCase() == t[j - 1].toLowerCase() ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // Deletion
          matrix[i][j - 1] + 1, // Insertion
          matrix[i - 1][j - 1] + cost, // Substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[s.length][t.length];
  }

  /// Verifica si [text] contiene [pattern] permitiendo 1 o 2 errores (RF-09).
  bool _fuzzyContains(String text, String pattern) {
    if (pattern.isEmpty) return true;
    final txt = text.toLowerCase();
    final pat = pattern.toLowerCase();

    // Si hay coincidencia exacta o substring, es éxito inmediato
    if (txt.contains(pat)) return true;

    // Para palabras muy cortas (≤ 2), no permitimos errores fuzzy
    if (pat.length <= 2) return false;

    // Umbral de error: 1 error para palabras cortas, 2 para largas (Nota Técnica)
    final maxErrors = pat.length <= 5 ? 1 : 2;

    // Ventana deslizante para buscar el patrón fuzzy dentro del texto
    for (int i = 0; i <= txt.length - pat.length + maxErrors; i++) {
      final end = (i + pat.length + maxErrors).clamp(0, txt.length);
      final sub = txt.substring(i, end);
      if (sub.length < pat.length - maxErrors) continue;

      if (_levenshtein(sub, pat) <= maxErrors) return true;
    }
    return false;
  }

  /// Determina si una transacción coincide con la consulta multipalabra (RF-09).
  bool _matchesSearch(TransactionEntity t, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;

    final description = (t.description ?? '').toLowerCase();
    // Buscamos sobre la categoría TRADUCIDA para que coincida con lo que ve el usuario
    final category = _getTranslatedCategory(t.category).toLowerCase();

    // Soporte para búsqueda de múltiples palabras (tokens)
    final tokens = q.split(' ').where((w) => w.isNotEmpty);

    // Todas las palabras de la búsqueda deben aparecer (en orden o no)
    for (final token in tokens) {
      if (!_fuzzyContains(description, token) &&
          !_fuzzyContains(category, token)) {
        return false;
      }
    }
    return true;
  }

  /// Calcula una puntuación de relevancia para ordenar los resultados (RF-09).
  int _searchRelevanceScore(TransactionEntity t, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return 0;

    final desc = (t.description ?? '').toLowerCase();
    final cat = _getTranslatedCategory(t.category).toLowerCase();
    int score = 0;

    // Prioridad 1: Coincidencia en descripción
    if (desc == q) {
      score += 100;
    } else if (desc.startsWith(q)) {
      score += 60;
    } else if (desc.contains(q)) {
      score += 30;
    } else if (_fuzzyContains(desc, q)) {
      score += 10;
    }

    // Prioridad 2: Coincidencia en categoría
    if (cat == q) {
      score += 50;
    } else if (cat.startsWith(q)) {
      score += 25;
    } else if (cat.contains(q)) {
      score += 15;
    }

    return score;
  }

  // ─── Lógica de Filtrado Combinado ──────────────────────────────────────────

  /// Aplica todos los filtros activos a la lista de transacciones.
  /// Implementa la lógica de filtrado por tipo, búsqueda fuzzy, fechas y metadatos.
  List<TransactionEntity> _applyFilters(List<TransactionEntity> transactions) {
    var filtered = transactions.where((t) {
      // 1. Filtro por tipo (Claves internas: 'Gastos', 'Ingresos')
      if (_selectedFilter == 'Gastos' && !t.isExpense) return false;
      if (_selectedFilter == 'Ingresos' && !t.isIncome) return false;

      // 2. Filtro por búsqueda de texto (RF-09 + Nota Técnica)
      if (_searchQuery.isNotEmpty && !_matchesSearch(t, _searchQuery)) {
        return false;
      }

      // 3. Filtro por rango de fechas
      final txDate = DateTime(t.date.year, t.date.month, t.date.day);
      if (_filterDateFrom != null) {
        final from = DateTime(
          _filterDateFrom!.year,
          _filterDateFrom!.month,
          _filterDateFrom!.day,
        );
        if (txDate.isBefore(from)) return false;
      }
      if (_filterDateTo != null) {
        final to = DateTime(
          _filterDateTo!.year,
          _filterDateTo!.month,
          _filterDateTo!.day,
        );
        if (txDate.isAfter(to)) return false;
      }

      // 4. Filtro por categoría múltiple
      if (_filterCategories.isNotEmpty &&
          !_filterCategories.contains(t.category)) {
        return false;
      }

      // 5. Filtro por método de pago
      if (_filterPaymentMethods.isNotEmpty &&
          !_filterPaymentMethods.contains(t.paymentMethod)) {
        return false;
      }

      // 6. Filtro por cuenta bancaria (RF-12)
      if (_filterBankAccountId != null &&
          t.bankAccountId != _filterBankAccountId) {
        return false;
      }

      return true;
    }).toList();

    // Ordenar por relevancia si hay búsqueda, o por fecha por defecto
    if (_searchQuery.isNotEmpty) {
      filtered.sort((a, b) {
        final scoreA = _searchRelevanceScore(a, _searchQuery);
        final scoreB = _searchRelevanceScore(b, _searchQuery);
        if (scoreB != scoreA) return scoreB.compareTo(scoreA);
        return b.date.compareTo(a.date);
      });
    } else {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    }

    return filtered;
  }

  /// Agrupa las transacciones por su fecha formateada para la vista de lista.
  Map<String, List<TransactionEntity>> _groupByDate(
    List<TransactionEntity> transactions,
  ) {
    final grouped = <String, List<TransactionEntity>>{};
    for (final t in transactions) {
      final key = _formatDateGroup(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  // ─── UI: Panel de Filtros Avanzados (RF-08) ────────────────────────────────

  /// Abre el Modal Bottom Sheet con las opciones granulares de filtrado.
  Future<void> _showAdvancedFilters(
    List<TransactionEntity> allTransactions,
  ) async {
    final s = AppLocalizations.of(context);

    // Obtener categorías únicas presentes en los datos actuales
    final availableCategories =
        allTransactions.map((t) => t.category).toSet().toList()..sort();

    // Estado local para el Modal (se confirma al pulsar "Aplicar")
    DateTime? localDateFrom = _filterDateFrom;
    DateTime? localDateTo = _filterDateTo;
    final localCategories = Set<String>.from(_filterCategories);
    final localPaymentMethods = Set<PaymentMethod>.from(_filterPaymentMethods);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            expand: false,
            builder: (ctx, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Tirador visual
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gray300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Encabezado del Panel
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s.advancedFiltersTitle,
                            style: AppTypography.titleMedium(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              localDateFrom = null;
                              localDateTo = null;
                              localCategories.clear();
                              localPaymentMethods.clear();
                            });
                          },
                          child: Text(
                            s.clearFilters,
                            style: AppTypography.labelMedium(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Cuerpo del panel con Scroll
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // ── Seccion: Rango de fechas ───────────────────────
                        Text(s.dateRange, style: AppTypography.labelMedium()),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePickerField(
                                label: s.fromLabel,
                                date: localDateFrom,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate:
                                        localDateFrom ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: localDateTo ?? DateTime.now(),
                                    // Flutter usa automáticamente el locale de la App
                                  );
                                  if (picked != null) {
                                    setSheetState(() => localDateFrom = picked);
                                  }
                                },
                                onClear: () =>
                                    setSheetState(() => localDateFrom = null),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDatePickerField(
                                label: s.toLabel,
                                date: localDateTo,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: localDateTo ?? DateTime.now(),
                                    firstDate: localDateFrom ?? DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => localDateTo = picked);
                                  }
                                },
                                onClear: () =>
                                    setSheetState(() => localDateTo = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Sección: Método de pago (Selección múltiple) ───
                        Text(
                          s.paymentMethodLabel,
                          style: AppTypography.labelMedium(),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PaymentMethod.values.map((method) {
                            final selected = localPaymentMethods.contains(
                              method,
                            );
                            return FilterChip(
                              label: Text(
                                _translatePaymentMethod(context, method.label),
                              ),
                              selected: selected,
                              onSelected: (val) {
                                setSheetState(() {
                                  if (val) {
                                    localPaymentMethods.add(method);
                                  } else {
                                    localPaymentMethods.remove(method);
                                  }
                                });
                              },
                              selectedColor: AppColors.primarySoft,
                              checkmarkColor: AppColors.primary,
                              labelStyle: AppTypography.labelMedium(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondaryLight,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.gray200,
                              ),
                              backgroundColor: AppColors.cardLight,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // ── Sección: Categorías (Selección múltiple) ──────
                        if (availableCategories.isNotEmpty) ...[
                          Text(s.category, style: AppTypography.labelMedium()),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableCategories.map((catKey) {
                              final selected = localCategories.contains(catKey);
                              final translatedName = _getTranslatedCategory(
                                catKey,
                              );

                              return FilterChip(
                                avatar: Icon(
                                  CategoryEntity.getIconForName(catKey),
                                  size: 16,
                                  color: selected
                                      ? AppColors.primary
                                      : CategoryEntity.getColorForName(catKey),
                                ),
                                label: Text(translatedName),
                                selected: selected,
                                onSelected: (val) {
                                  setSheetState(() {
                                    if (val) {
                                      localCategories.add(catKey);
                                    } else {
                                      localCategories.remove(catKey);
                                    }
                                  });
                                },
                                selectedColor: AppColors.primarySoft,
                                checkmarkColor: AppColors.primary,
                                labelStyle: AppTypography.labelMedium(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textSecondaryLight,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.gray200,
                                ),
                                backgroundColor: AppColors.cardLight,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Botón de Acción Final ──────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(ctx).viewInsets.bottom + 20,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterDateFrom = localDateFrom;
                            _filterDateTo = localDateTo;
                            _filterCategories
                              ..clear()
                              ..addAll(localCategories);
                            _filterPaymentMethods
                              ..clear()
                              ..addAll(localPaymentMethods);
                            _displayCount = _pageSize; // Reset scroll
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          s.applyFilters,
                          style: AppTypography.button(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget de apoyo para mostrar un campo de selección de fecha localizado
  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final s = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: date != null ? AppColors.primarySoft : AppColors.gray100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.badge(
                      color: date != null
                          ? AppColors.primary
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? _formatDateShort(date) : s.selectDate,
                    style: AppTypography.labelMedium(
                      color: date != null
                          ? AppColors.primary
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              )
            else
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.gray400,
              ),
          ],
        ),
      ),
    );
  }

  // ─── Tablet Layout ───────────────────────────────────────────────────────────

  Widget _buildTabletContent(
    BuildContext context,
    List<TransactionEntity> allTransactions,
  ) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    final state = context.read<TransactionBloc>().state;
    final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
    final expenses = state is TransactionsLoaded ? state.totalExpenses : 0.0;
    final net = income - expenses;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── LEFT PANEL (40%) ─────────────────────────────────────────────────
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  16,
                  responsive.horizontalPadding,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.transactionsTitle,
                      style: AppTypography.headlineSmall(),
                    ),
                    Row(
                      children: [
                        // Filter button
                        GestureDetector(
                          onTap: () => _showAdvancedFilters(allTransactions),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _hasAdvancedFilters
                                  ? AppColors.primarySoft
                                  : AppColors.gray100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _hasAdvancedFilters
                                    ? AppColors.primary
                                    : AppColors.gray200,
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _hasAdvancedFilters
                                  ? AppColors.primary
                                  : AppColors.gray400,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add button
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/add-transaction'),
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Search bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.bodyMedium(),
                    onChanged: (value) {
                      setState(() => _searchText = value);
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(
                        const Duration(milliseconds: 300),
                        () => setState(() {
                          _searchQuery = value;
                          _displayCount = _pageSize;
                        }),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: s.searchHint,
                      hintStyle: AppTypography.bodyMedium(
                        color: AppColors.textTertiaryLight,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.gray400,
                        size: 20,
                      ),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.gray400,
                              ),
                              onPressed: () {
                                _debounceTimer?.cancel();
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                  _searchQuery = '';
                                  _displayCount = _pageSize;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Filter chips
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                ),
                child: Row(
                  children: [
                    _buildFilterChip(s.filterAll, 'Todas'),
                    const SizedBox(width: 8),
                    _buildFilterChip(s.filterExpenses, 'Gastos'),
                    const SizedBox(width: 8),
                    _buildFilterChip(s.filterIncomes, 'Ingresos'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Transaction list
              Expanded(
                child: _buildTransactionListTablet(allTransactions, responsive),
              ),
            ],
          ),
        ),
        // ── RIGHT PANEL ──────────────────────────────────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border(
                left: BorderSide(color: AppColors.gray200, width: 2),
              ),
            ),
            child: _selectedTransaction == null
                ? _buildTabletRightPanelSummary(context, income, expenses, net)
                : _buildTabletTransactionDetail(context, _selectedTransaction!),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionListTablet(
    List<TransactionEntity> allTransactions,
    ResponsiveUtils responsive,
  ) {
    if (allTransactions.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _applyFilters(allTransactions);

    if (filtered.isEmpty) {
      return _buildEmptyFilterState();
    }

    final displayed = filtered.take(_displayCount).toList();
    final hasMore = filtered.length > _displayCount;
    final isSearching = _searchQuery.isNotEmpty;
    final grouped = isSearching ? null : _groupByDate(displayed);
    final groupKeys = grouped?.keys.toList() ?? [];

    final listLength = isSearching
        ? displayed.length + (hasMore ? 1 : 0)
        : groupKeys.length + (hasMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      itemCount: listLength,
      itemBuilder: (context, index) {
        final isMoreIndicator = isSearching
            ? index == displayed.length
            : index == groupKeys.length;

        if (isMoreIndicator && hasMore) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '${filtered.length - _displayCount} ${AppLocalizations.of(context).moreItems}',
                style: AppTypography.bodySmall(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ),
          );
        }

        if (isSearching) {
          return _buildTabletTransactionItem(displayed[index]);
        } else {
          final dateLabel = groupKeys[index];
          return _buildTabletDateGroup(dateLabel, grouped![dateLabel]!);
        }
      },
    );
  }

  Widget _buildTabletDateGroup(
    String dateLabel,
    List<TransactionEntity> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
          child: Text(
            dateLabel,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        ...items.map((t) => _buildTabletTransactionItem(t)),
      ],
    );
  }

  Widget _buildTabletTransactionItem(TransactionEntity t) {
    final translatedCat = _getTranslatedCategory(t.category);
    final isSelected = _selectedTransaction?.id == t.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedTransaction = t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : t.isPendingSync
                ? AppColors.warning.withValues(alpha: 0.3)
                : AppColors.gray100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(t.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(t.category),
                color: _getCategoryColor(t.category),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description?.isNotEmpty == true
                        ? t.description!
                        : translatedCat,
                    style: AppTypography.titleSmall(),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    translatedCat,
                    style: AppTypography.bodySmall(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${t.isExpense ? '-' : '+'}${_formatCurrency(t.amount)}',
                  style: AppTypography.titleSmall(
                    color: t.isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
                Text(
                  _formatDate(t.date),
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletRightPanelSummary(
    BuildContext context,
    double income,
    double expenses,
    double net,
  ) {
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen', style: AppTypography.headlineSmall()),
          const SizedBox(height: 24),
          // Income card
          _buildTabletSummaryCard(
            icon: Icons.south_west_rounded,
            label: s.filterIncomes,
            value: _formatCurrency(income),
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          // Expense card
          _buildTabletSummaryCard(
            icon: Icons.north_east_rounded,
            label: s.filterExpenses,
            value: _formatCurrency(expenses),
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          // Net balance card
          _buildTabletSummaryCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Balance neto',
            value: _formatCurrency(net),
            color: net >= 0 ? AppColors.primary : AppColors.error,
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 36,
                  color: AppColors.gray300,
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca una transacción para ver detalles',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTabletSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Text(value, style: AppTypography.titleMedium(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletTransactionDetail(
    BuildContext context,
    TransactionEntity t,
  ) {
    final s = AppLocalizations.of(context);
    final translatedCat = _getTranslatedCategory(t.category);
    final catColor = _getCategoryColor(t.category);
    final catIcon = _getCategoryIcon(t.category);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            children: [
              Text('Detalle', style: AppTypography.headlineSmall()),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedTransaction = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Category icon and type
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(catIcon, color: catColor, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  '${t.isExpense ? '-' : '+'}${_formatCurrency(t.amount)}',
                  style: AppTypography.moneyLarge(
                    color: t.isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.description?.isNotEmpty == true
                      ? t.description!
                      : translatedCat,
                  style: AppTypography.titleMedium(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Details rows
          _buildDetailRow(
            Icons.category_rounded,
            s.category,
            translatedCat,
            catColor,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today_rounded,
            'Fecha',
            _formatDate(t.date),
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.payment_rounded,
            s.paymentMethodLabel,
            _translatePaymentMethod(context, t.paymentMethod.label),
            AppColors.accent,
          ),
          const Spacer(),
          // Edit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTransactionPage(transaction: t),
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(s.edit),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall(
                  color: AppColors.textTertiaryLight,
                ),
              ),
              Text(value, style: AppTypography.bodyMedium(), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);

    return SafeArea(
      child: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          // Extraemos la lista base del estado de BLoC
          final List<TransactionEntity> allTransactions =
              state is TransactionsLoaded ? state.transactions : [];

          if (responsive.isTablet) {
            return _buildTabletContent(context, allTransactions);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionBloc>().add(LoadTransactions());
              // Delay estético para asegurar que el usuario vea la animación
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primary,
            child: Column(
              children: [
                // ── Cabecera de la Página ────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    16,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                s.transactionsTitle,
                                style: AppTypography.headlineSmall(),
                              ),
                              // Indicador de transacciones pendientes (RNF-15)
                              if (state is TransactionsLoaded &&
                                  state.pendingSyncCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 14,
                                          color: AppColors.warningDark,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${state.pendingSyncCount}',
                                          style: AppTypography.badge(
                                            color: AppColors.warningDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              // Botón de Filtros con Badge (RF-08)
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _showAdvancedFilters(allTransactions),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _hasAdvancedFilters
                                            ? AppColors.primarySoft
                                            : AppColors.gray100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _hasAdvancedFilters
                                              ? AppColors.primary
                                              : AppColors.gray200,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: _hasAdvancedFilters
                                            ? AppColors.primary
                                            : AppColors.gray400,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  if (_activeFilterCount > 0)
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.cardLight,
                                            width: 1.5,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$_activeFilterCount',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // Botón Añadir (RF-05)
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/add-transaction',
                                ),
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Barra de Resumen Financiero ────────────────────────
                      _buildSummaryBar(state),
                      const SizedBox(height: 16),
                      // ── Barra de Búsqueda Inteligente (RF-09) ──────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppTypography.bodyMedium(),
                          onChanged: (value) {
                            setState(() => _searchText = value);
                            // Debounce de 300ms para no saturar el filtrado (Nota Técnica)
                            _debounceTimer?.cancel();
                            _debounceTimer = Timer(
                              const Duration(milliseconds: 300),
                              () => setState(() {
                                _searchQuery = value;
                                _displayCount =
                                    _pageSize; // Reset scroll al buscar
                              }),
                            );
                          },
                          decoration: InputDecoration(
                            hintText: s.searchHint,
                            hintStyle: AppTypography.bodyMedium(
                              color: AppColors.textTertiaryLight,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.gray400,
                              size: 20,
                            ),
                            suffixIcon: _searchText.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppColors.gray400,
                                    ),
                                    onPressed: () {
                                      _debounceTimer?.cancel();
                                      _searchController.clear();
                                      setState(() {
                                        _searchText = '';
                                        _searchQuery = '';
                                        _displayCount = _pageSize;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Chips de Filtrado Rápido y Limpieza ────────────────
                      Row(
                        children: [
                          _buildFilterChip(s.filterAll, 'Todas'),
                          const SizedBox(width: 8),
                          _buildFilterChip(s.filterExpenses, 'Gastos'),
                          const SizedBox(width: 8),
                          _buildFilterChip(s.filterIncomes, 'Ingresos'),
                          const Spacer(),
                          // Botón para limpiar todos los filtros avanzados (RF-08)
                          if (_hasAdvancedFilters)
                            GestureDetector(
                              onTap: _clearAllFilters,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.filter_list_off_rounded,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.clearFilters,
                                      style: AppTypography.badge(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ── Indicadores de Filtros de Fecha/Cuenta Activos ──────
                      if (_filterDateFrom != null || _filterDateTo != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _buildActiveDateRangeLabel(),
                                style: AppTypography.badge(
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_filterBankAccountId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.accountFilterLabel(
                                  _filterBankAccountName ?? '',
                                ),
                                style: AppTypography.badge(
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _filterBankAccountId = null;
                                _filterBankAccountName = null;
                              }),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // ── Cuerpo: Lista de Transacciones ───────────────────────────
                Expanded(
                  child: _buildTransactionList(allTransactions, responsive),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Widgets de Apoyo y Listado ───────────────────────────────────────────

  /// Genera el listado dinámico manejando estados vacíos y scroll infinito (RF-08)
  Widget _buildTransactionList(
    List<TransactionEntity> allTransactions,
    ResponsiveUtils responsive,
  ) {
    final s = AppLocalizations.of(context);

    if (allTransactions.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _applyFilters(allTransactions);

    if (filtered.isEmpty) {
      return _buildEmptyFilterState();
    }

    // Lógica de Scroll Infinito: Solo mostramos hasta _displayCount (RNF-20)
    final displayed = filtered.take(_displayCount).toList();
    final hasMore = filtered.length > _displayCount;

    // Si hay búsqueda activa (RF-09), mostramos lista plana por relevancia.
    // Si no, mostramos la lista agrupada por fechas para mejor legibilidad.
    final isSearching = _searchQuery.isNotEmpty;
    final grouped = isSearching ? null : _groupByDate(displayed);
    final groupKeys = grouped?.keys.toList() ?? [];

    final listLength = isSearching
        ? displayed.length + (hasMore ? 1 : 0)
        : groupKeys.length + (hasMore ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicador de número de resultados localizados (RF-09)
        if (isSearching)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: 6,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 13,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(width: 5),
                Text(
                  '${filtered.length} ${filtered.length == 1 ? s.resultCount : s.resultsCount}',
                  style: AppTypography.badge(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
            ),
            itemCount: listLength,
            itemBuilder: (context, index) {
              final isMoreIndicator = isSearching
                  ? index == displayed.length
                  : index == groupKeys.length;

              // Widget de "Cargando más" para Scroll Infinito
              if (isMoreIndicator && hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      '${filtered.length - _displayCount} ${s.moreItems}',
                      style: AppTypography.bodySmall(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                );
              }

              if (isSearching) {
                return _buildTransactionItem(displayed[index]);
              } else {
                final dateLabel = groupKeys[index];
                return _buildDateGroup(dateLabel, grouped![dateLabel]!);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Construye la barra de resumen con ingresos y gastos totales del periodo
  Widget _buildSummaryBar(TransactionState state) {
    final s = AppLocalizations.of(context);
    final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
    final expenses = state is TransactionsLoaded ? state.totalExpenses : 0.0;
    final count = state is TransactionsLoaded ? state.transactions.length : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat(
              icon: Icons.south_west_rounded,
              label: s.filterIncomes,
              value: _formatCurrency(income),
              color: AppColors.success,
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.gray200),
          Expanded(
            child: _buildMiniStat(
              icon: Icons.north_east_rounded,
              label: s.filterExpenses,
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

  /// Chip de filtrado con animación y estilo localizado
  Widget _buildFilterChip(String localizedLabel, String internalKey) {
    final isSelected = _selectedFilter == internalKey;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedFilter = internalKey;
        _displayCount = _pageSize;
      }),
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
          localizedLabel,
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
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        ...items.map((t) => _buildTransactionItem(t)),
      ],
    );
  }

  // ─── Highlight de términos coincidentes (RF-09) ───────────────────────────

  /// Resalta visualmente los términos que coinciden con la búsqueda actual
  Widget _buildHighlightedText(
    String text,
    String query, {
    TextStyle? baseStyle,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    while (matchIndex != -1) {
      if (matchIndex > start) {
        spans.add(
          TextSpan(text: text.substring(start, matchIndex), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + lowerQuery.length),
          style: (baseStyle ?? const TextStyle()).copyWith(
            backgroundColor: const Color(0xFFFFE082), // Resaltado visual
            color: const Color(0xFF333333),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = matchIndex + lowerQuery.length;
      matchIndex = lowerText.indexOf(lowerQuery, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  // ─── Ítem de Transacción e Interacciones (RF-06 / RF-07) ──────────────────

  Widget _buildTransactionItem(TransactionEntity t) {
    final s = AppLocalizations.of(context);
    final translatedCat = _getTranslatedCategory(t.category);

    return Dismissible(
      key: Key(t.id ?? t.hashCode.toString()),
      direction: DismissDirection.horizontal,
      // Deslizar derecha -> Editar (RF-06)
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: AppColors.white),
            const SizedBox(width: 8),
            Text(
              s.edit,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      // Deslizar izquierda -> Eliminar (RF-07)
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.delete,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: AppColors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTransactionPage(transaction: t),
            ),
          );
          return false;
        }
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                const SizedBox(width: 10),
                Text(s.deleteConfirmTitle),
              ],
            ),
            content: Text(s.deleteConfirmContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(s.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        final deletedTx = t;
        context.read<TransactionBloc>().add(
          DeleteTransaction(transactionId: t.id!),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.transactionDeleted),
            action: SnackBarAction(
              label: s.undo,
              onPressed: () => context.read<TransactionBloc>().add(
                AddTransaction(transaction: deletedTx),
              ),
            ),
          ),
        );
      },
      child: Semantics(
        label: s.transactionSemantics(
          isExpense: t.isExpense,
          category: translatedCat,
          amount: t.amount.toStringAsFixed(2),
          description: t.description,
          date: _formatDate(t.date),
          pending: t.isPendingSync,
        ),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTransactionPage(transaction: t),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: t.isPendingSync
                    ? AppColors.warning.withValues(alpha: 0.3)
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
                      if (t.isPendingSync)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cardLight,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              size: 8,
                              color: Colors.white,
                            ),
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
                      _buildHighlightedText(
                        t.description?.isNotEmpty == true
                            ? t.description!
                            : translatedCat,
                        _searchQuery,
                        baseStyle: AppTypography.titleSmall(),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: _buildHighlightedText(
                              translatedCat,
                              _searchQuery,
                              baseStyle: AppTypography.bodySmall(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (t.isPendingSync)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningSoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                s.pendingSync,
                                style: AppTypography.badge(
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${t.isExpense ? '-' : '+'}${_formatCurrency(t.amount)}',
                      style: AppTypography.titleSmall(
                        color: t.isExpense
                            ? AppColors.expense
                            : AppColors.income,
                      ),
                    ),
                    Text(
                      _formatDate(t.date),
                      style: AppTypography.bodySmall(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final s = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 16),
            Text(s.noTransactionsYet, style: AppTypography.titleMedium()),
            Text(
              s.registerFirstTransaction,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    final s = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 16),
            Text(s.noResultsFound, style: AppTypography.titleMedium()),
            Text(
              _searchQuery.isNotEmpty
                  ? s.noResultsMatching(_searchQuery)
                  : s.noResultsWithFilters,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _clearAllFilters,
              child: Text(s.clearFilters),
            ),
          ],
        ),
      ),
    );
  }
}
