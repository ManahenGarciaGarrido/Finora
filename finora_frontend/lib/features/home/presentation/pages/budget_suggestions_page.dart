import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

class BudgetSuggestionsPage extends StatefulWidget {
  const BudgetSuggestionsPage({super.key});

  @override
  State<BudgetSuggestionsPage> createState() => _BudgetSuggestionsPageState();
}

class _BudgetSuggestionsPageState extends State<BudgetSuggestionsPage> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = true;
  bool _applying = false;
  String? _error;
  final _apiClient = di.sl<ApiClient>();
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _apiClient.get('/budget/suggest');
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(
            data['suggestions'] ?? [],
          );
          _selected.addAll(Iterable.generate(_suggestions.length, (i) => i));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _applySelected() async {
    final s = AppLocalizations.of(context);
    setState(() => _applying = true);
    int applied = 0;
    for (final i in _selected) {
      final sug = _suggestions[i];
      try {
        await _apiClient.post(
          '/budget',
          data: {
            'category': sug['category'],
            'monthly_limit': sug['suggested_limit'],
          },
        );
        applied++;
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$applied ${s.budgetSavedMsg}'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, applied > 0);
    }
  }

  String _getTranslatedCategory(String key, AppLocalizations s) {
    switch (key.toLowerCase().trim()) {
      case 'alimentación':
      case 'food':
        return s.nutrition;
      case 'transporte':
      case 'transport':
        return s.transport;
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
      default:
        if (key.isEmpty) return '';
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final fmt = CurrencyService().format;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          s.aiSuggestBudgetsTitle,
          style: AppTypography.titleMedium(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonListLoader(count: 5, cardHeight: 72),
            )
          : _error != null
          ? _buildError(s)
          : _suggestions.isEmpty
          ? _buildEmpty(s)
          : _buildList(s, fmt),
      bottomNavigationBar:
          (!_loading && _suggestions.isNotEmpty && _error == null)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: (_applying || _selected.isEmpty)
                      ? null
                      : _applySelected,
                  icon: _applying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text('${s.applyAllSuggestions} (${_selected.length})'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildError(AppLocalizations s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(s.error, style: AppTypography.bodyMedium()),
          TextButton(onPressed: _load, child: Text(s.reconnect)),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, color: AppColors.gray400, size: 56),
          const SizedBox(height: 16),
          Text(
            s.noHistoryData,
            style: AppTypography.bodyMedium(color: AppColors.gray500),
          ),
          const SizedBox(height: 8),
          Text(
            s.aiSuggestBudgetsInfo,
            style: AppTypography.bodySmall(color: AppColors.gray400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations s, Function fmt) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.1),
                AppColors.primarySoft,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.aiSuggestBudgetsTitle,
                      style: AppTypography.titleSmall(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.aiSuggestBudgetsInfo,
                      style: AppTypography.bodySmall(color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select all / deselect all
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_suggestions.length} sugerencias',
              style: AppTypography.labelSmall(color: AppColors.gray500),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selected.length == _suggestions.length) {
                    _selected.clear();
                  } else {
                    _selected.addAll(
                      Iterable.generate(_suggestions.length, (i) => i),
                    );
                  }
                });
              },
              child: Text(
                _selected.length == _suggestions.length
                    ? s.cancel
                    : s.applyAllSuggestions,
                style: AppTypography.labelSmall(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Suggestion cards
        for (int i = 0; i < _suggestions.length; i++) ...[
          _buildSuggestionCard(i, s, fmt),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 80), // bottom button space
      ],
    );
  }

  Widget _buildSuggestionCard(int i, AppLocalizations s, Function fmt) {
    final sug = _suggestions[i];
    final isSelected = _selected.contains(i);
    final avg = (sug['avg_spending'] as num?)?.toDouble();
    final suggested = (sug['suggested_limit'] as num).toDouble();

    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selected.remove(i);
        } else {
          _selected.add(i);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.gray200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.gray400,
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTranslatedCategory(sug['category'] as String, s),
                    style: AppTypography.titleSmall(),
                  ),
                  if (avg != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Media gasto: ${fmt(avg)}',
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt(suggested),
                  style: AppTypography.titleSmall(color: AppColors.primary),
                ),
                Text(
                  s.monthlyLimitLabel,
                  style: AppTypography.labelSmall(color: AppColors.gray400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
