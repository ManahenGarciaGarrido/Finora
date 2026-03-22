import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/bank_bloc.dart';
import '../bloc/bank_event.dart';
import '../bloc/bank_state.dart';

class BankAccountSetupPage extends StatefulWidget {
  final String connectionId;
  final String institutionName;

  const BankAccountSetupPage({
    super.key,
    required this.connectionId,
    required this.institutionName,
  });

  @override
  State<BankAccountSetupPage> createState() => _BankAccountSetupPageState();
}

class _BankAccountSetupPageState extends State<BankAccountSetupPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _ibanCtrl = TextEditingController();

  String _accountType = 'current';
  final List<_PendingCard> _pendingCards = [];
  List<Map<String, dynamic>>? _csvRows;
  int _csvRowCount = 0;
  String? _csvFileName;

  // Saving flow state
  bool _isSaving = false;
  String? _createdAccountId;
  int _cardIdx = 0;

  List<(String, String)> _accountTypes(BuildContext ctx) {
    final s = AppLocalizations.of(ctx);
    return [
      ('current', s.accountTypeCurrent),
      ('savings', s.accountTypeSavings),
      ('investment', s.accountTypeInvestment),
      ('other', s.accountTypeOther),
    ];
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.institutionName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BankBloc, BankState>(
      listener: _handleBlocState,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimaryLight,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context).newAccountTitle,
            style: AppTypography.titleLarge(),
          ),
          centerTitle: true,
        ),
        body: Builder(builder: (context) {
          final responsive = ResponsiveUtils(context);
          final listView = ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              // Institution header
              _buildInstitutionHeader(),
              const SizedBox(height: 24),

              // Account name
              _buildSectionLabel(AppLocalizations.of(context).accountName),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: AppTypography.bodyMedium(),
                decoration: _inputDecoration(hint: 'Ej. BBVA Principal'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppLocalizations.of(context).enterAccountNameError
                    : null,
              ),
              const SizedBox(height: 20),

              // Account type
              _buildSectionLabel(AppLocalizations.of(context).accountTypeLabel),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _accountType,
                  style: AppTypography.bodyMedium(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: _accountTypes(context)
                      .map(
                        (t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _accountType = v!),
                ),
              ),
              const SizedBox(height: 20),

              // IBAN (optional)
              _buildSectionLabel(AppLocalizations.of(context).ibanOptional),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ibanCtrl,
                style: AppTypography.bodyMedium(),
                decoration: _inputDecoration(
                  hint: 'ES91 2100 0418 4502 0005 1332',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 28),

              // Cards section
              _buildCardsSection(),
              const SizedBox(height: 28),

              // CSV import section
              _buildCsvSection(),
              const SizedBox(height: 16),
            ],
          );
          final formBody = Form(key: _formKey, child: listView);
          return responsive.isTablet
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: formBody,
                  ),
                )
              : formBody;
        }),
        bottomNavigationBar: _buildSaveButton(),
      ),
    );
  }

  void _handleBlocState(BuildContext context, BankState state) {
    if (state is BankAccountSetupSuccess) {
      _createdAccountId = state.account.id;
      _cardIdx = 0;
      _addNextCard(context);
    } else if (state is BankCardAdded) {
      _cardIdx++;
      _addNextCard(context);
    } else if (state is BankCardAddFailure) {
      setState(() => _isSaving = false);
      final s = AppLocalizations.of(context);
      _showError(context, '${s.cardAddError}: ${state.message}');
    } else if (state is BankCsvImportSuccess) {
      setState(() => _isSaving = false);
      context.read<BankBloc>().add(const LoadBankAccounts());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).csvImportResult(
              state.imported,
              state.skipped,
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (state is BankCsvImportFailure) {
      setState(() => _isSaving = false);
      final s = AppLocalizations.of(context);
      _showError(context, '${s.csvImportError}: ${state.message}');
    } else if (state is BankAccountSetupFailure) {
      setState(() => _isSaving = false);
      _showError(context, state.message);
    }
  }

  void _addNextCard(BuildContext context) {
    final accountId = _createdAccountId!;
    if (_cardIdx < _pendingCards.length) {
      final card = _pendingCards[_cardIdx];
      context.read<BankBloc>().add(
        AddBankCardRequested(
          bankAccountId: accountId,
          cardName: card.name,
          cardType: card.type,
          lastFour: card.lastFour,
        ),
      );
    } else {
      // Cards done → import CSV or finish
      if (_csvRows != null && _csvRows!.isNotEmpty) {
        context.read<BankBloc>().add(
          ImportCsvRequested(bankAccountId: accountId, rows: _csvRows!),
        );
      } else {
        setState(() => _isSaving = false);
        context.read<BankBloc>().add(const LoadBankAccounts());
        Navigator.pop(context);
      }
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  // ── Institution header ─────────────────────────────────────
  Widget _buildInstitutionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.institutionName,
                  style: AppTypography.titleMedium(),
                ),
                Text(
                  AppLocalizations.of(context).configureAccountMsg,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cards section ──────────────────────────────────────────
  Widget _buildCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel(AppLocalizations.of(context).cardsLabel),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAddCardSheet,
              icon: const Icon(
                Icons.add_card_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                AppLocalizations.of(context).addBtn,
                style: AppTypography.labelMedium(color: AppColors.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_pendingCards.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  color: AppColors.gray300,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).noCardsOptional,
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          )
        else
          ...(_pendingCards.asMap().entries.map(
            (e) => _buildCardTile(e.key, e.value),
          )),
      ],
    );
  }

  Widget _buildCardTile(int index, _PendingCard card) {
    final icon = card.type == 'credit'
        ? Icons.credit_card_rounded
        : card.type == 'prepaid'
        ? Icons.contactless_rounded
        : Icons.payment_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name, style: AppTypography.titleSmall()),
                Text(
                  '${_cardTypeLabel(context, card.type)}${card.lastFour != null ? ' ••••${card.lastFour}' : ''}',
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.gray400,
              size: 18,
            ),
            onPressed: () => setState(() => _pendingCards.removeAt(index)),
          ),
        ],
      ),
    );
  }

  String _cardTypeLabel(BuildContext ctx, String type) {
    final s = AppLocalizations.of(ctx);
    switch (type) {
      case 'credit':
        return s.cardTypeCredit;
      case 'prepaid':
        return s.cardTypePrepaid;
      default:
        return s.cardTypeDebit;
    }
  }

  void _showAddCardSheet() {
    showModalBottomSheet<_PendingCard>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardSetupSheet(),
    ).then((card) {
      if (card != null && mounted) {
        setState(() => _pendingCards.add(card));
      }
    });
  }

  // ── CSV section ────────────────────────────────────────────
  Widget _buildCsvSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(AppLocalizations.of(context).importCsvLabel),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_csvFileName != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _csvFileName!,
                            style: AppTypography.titleSmall(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            AppLocalizations.of(context).csvMovementsDetected(_csvRowCount),
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.gray400,
                        size: 18,
                      ),
                      onPressed: () => setState(() {
                        _csvRows = null;
                        _csvFileName = null;
                        _csvRowCount = 0;
                      }),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  AppLocalizations.of(context).csvImportDesc,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).csvFormatHelper,
                  style: AppTypography.labelSmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickCsvFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).selectCsvFile,
                          style: AppTypography.labelMedium(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String content;
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        return;
      }

      final rows = _parseCsv(content);
      if (mounted) {
        setState(() {
          _csvRows = rows;
          _csvRowCount = rows.length;
          _csvFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).csvReadError}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseCsv(String content) {
    final rows = <Map<String, dynamic>>[];
    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Skip header row if it looks like a header
    int startIdx = 0;
    if (lines.isNotEmpty) {
      final firstLower = lines.first.toLowerCase();
      if (firstLower.contains('fecha') ||
          firstLower.contains('date') ||
          firstLower.contains('descripcion') ||
          firstLower.contains('description')) {
        startIdx = 1;
      }
    }

    for (int i = startIdx; i < lines.length; i++) {
      final cols = _splitCsvLine(lines[i]);
      if (cols.length < 3) continue;

      final date = cols[0].trim();
      final description = cols.length > 1 ? cols[1].trim() : '';
      final amountStr = (cols.length > 2 ? cols[2] : '0').trim().replaceAll(
        ',',
        '.',
      );
      final amount = double.tryParse(amountStr) ?? 0.0;
      final type = cols.length > 3 ? cols[3].trim().toLowerCase() : '';

      // Infer type from sign if not given
      String txType;
      if (type == 'income' || type == 'ingreso') {
        txType = 'income';
      } else if (type == 'expense' || type == 'gasto') {
        txType = 'expense';
      } else {
        txType = amount >= 0 ? 'income' : 'expense';
      }

      rows.add({
        'date': date,
        'description': description,
        'amount': amount.abs(),
        'type': txType,
      });
    }

    return rows;
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    var inQuotes = false;
    var current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if ((c == ',' || c == ';') && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }

  // ── Save button ────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: BlocBuilder<BankBloc, BankState>(
          builder: (context, state) {
            final loading =
                _isSaving ||
                state is BankAccountSetupInProgress ||
                state is BankCardAdding ||
                state is BankCsvImportInProgress;
            return GestureDetector(
              onTap: loading ? null : () => _save(context),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: loading ? null : AppColors.primaryGradient,
                  color: loading ? AppColors.gray300 : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context).saveAccountBtn,
                          style: AppTypography.labelLarge(
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    context.read<BankBloc>().add(
      SetupBankAccountRequested(
        connectionId: widget.connectionId,
        accountName: _nameCtrl.text.trim(),
        accountType: _accountType,
        iban: _ibanCtrl.text.trim().isNotEmpty ? _ibanCtrl.text.trim() : null,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium(color: AppColors.textTertiaryLight),
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Pending card model ────────────────────────────────────────
class _PendingCard {
  final String name;
  final String type;
  final String? lastFour;
  _PendingCard({required this.name, required this.type, this.lastFour});
}

// ── Card setup bottom sheet ───────────────────────────────────
class _CardSetupSheet extends StatefulWidget {
  @override
  State<_CardSetupSheet> createState() => _CardSetupSheetState();
}

class _CardSetupSheetState extends State<_CardSetupSheet> {
  final _nameCtrl = TextEditingController();
  final _lastFourCtrl = TextEditingController();
  String _cardType = 'debit';

  List<(String, String)> _cardTypes(BuildContext ctx) {
    final s = AppLocalizations.of(ctx);
    return [
      ('debit', s.cardTypeDebit),
      ('credit', s.cardTypeCredit),
      ('prepaid', s.cardTypePrepaid),
    ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastFourCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).addCardTitle,
            style: AppTypography.titleLarge(),
          ),
          const SizedBox(height: 20),

          // Card type chips
          Text(
            AppLocalizations.of(context).accountTypeLabel,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _cardTypes(context).map((t) {
              final selected = _cardType == t.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _cardType = t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.gray200,
                      ),
                    ),
                    child: Text(
                      t.$2,
                      style: AppTypography.labelMedium(
                        color: selected
                            ? AppColors.white
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Card name
          Text(
            AppLocalizations.of(context).cardNameLabel,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: AppTypography.bodyMedium(),
            decoration: InputDecoration(
              hintText: 'Ej. Visa BBVA',
              hintStyle: AppTypography.bodyMedium(
                color: AppColors.textTertiaryLight,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Last 4 digits
          Text(
            AppLocalizations.of(context).lastFourDigitsLabel,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lastFourCtrl,
            style: AppTypography.bodyMedium(),
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              hintText: '1234',
              counterText: '',
              hintStyle: AppTypography.bodyMedium(
                color: AppColors.textTertiaryLight,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Confirm button
          GestureDetector(
            onTap: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).enterAccountNameError,
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                _PendingCard(
                  name: name,
                  type: _cardType,
                  lastFour: _lastFourCtrl.text.trim().isNotEmpty
                      ? _lastFourCtrl.text.trim()
                      : null,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).addCardTitle,
                  style: AppTypography.labelLarge(color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}