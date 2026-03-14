import 'dart:io';

import 'package:finora_frontend/core/l10n/app_localizations.dart';
import 'package:finora_frontend/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_event.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../banks/presentation/bloc/bank_bloc.dart';
import '../../../banks/presentation/bloc/bank_event.dart';
import '../../../banks/presentation/bloc/bank_state.dart';
import '../../../banks/domain/entities/bank_account_entity.dart';
import '../../../banks/domain/entities/bank_card_entity.dart';

/// Página de Registro Manual de Transacciones (RF-05, HU-03)
///
/// Permite al usuario registrar manualmente gastos e ingresos especificando:
/// - Cantidad (numérica, positiva) — teclado numérico por defecto
/// - Tipo (gasto/ingreso)
/// - Categoría (con autocompletado basado en historial)
/// - Descripción (texto libre, opcional)
/// - Fecha (default: hoy)
/// - Método de pago (efectivo, tarjeta, transferencia)
/// - Foto del ticket (opcional)
class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.debitCard;
  String? _photoPath;

  bool _isSubmitting = false;
  bool _showSuccess = false;

  // Bank account / card selector
  List<BankAccountEntity> _bankAccounts = [];
  List<BankCardEntity> _bankCards = [];
  String? _selectedBankAccountId;
  String? _selectedBankCardId;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // HU-03: Autocompletado — frecuencia de categorías del historial
  Map<String, int> _categoryFrequency = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );
    _animationController.forward();
    _computeCategoryFrequency();

    // RNF-08: Carga lazy de categorías — solo se cargan cuando el usuario
    // abre esta pantalla, no al inicio de la app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryBloc>().add(LoadCategories());
        context.read<BankBloc>().add(const LoadBankAccounts());
        context.read<BankBloc>().add(const LoadBankCards());
      }
    });
  }

  /// HU-03: Calcula la frecuencia de uso de cada categoría desde el historial
  void _computeCategoryFrequency() {
    final bloc = context.read<TransactionBloc>();
    final freq = <String, int>{};
    for (final t in bloc.transactions) {
      if (t.type == _selectedType) {
        freq[t.category] = (freq[t.category] ?? 0) + 1;
      }
    }
    _categoryFrequency = freq;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Validación ---

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'La cantidad es requerida';
    }
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      return 'Introduce una cantidad válida mayor que 0';
    }
    if (amount > 999999.99) {
      return 'La cantidad no puede exceder €999.999,99';
    }
    return null;
  }

  // --- Traducción de categorías ---
  String _getTranslatedCategory(BuildContext context, String categoryKey) {
    final s = AppLocalizations.of(context);

    switch (categoryKey.toLowerCase()) {
      case 'alimentación':
        return s.nutrition;
      case 'transporte':
        return s.transport;
      case 'ocio':
        return s.leisure;
      case 'salud':
        return s.health;
      case 'vivienda':
        return s.housing;
      case 'servicios':
        return s.services;
      case 'educación':
        return s.education;
      case 'ropa':
        return s.clothing;
      case 'otros':
        return s.other;
      case 'ahorro':
        return s.saving;
      default:
        return categoryKey;
    }
  }

  String _getPaymentMethodLabel(BuildContext context, PaymentMethod method) {
    final s = AppLocalizations.of(context);

    switch (method) {
      case PaymentMethod.cash:
        return s.paymentCash;
      case PaymentMethod.debitCard:
        return s.pmDebitCard;
      case PaymentMethod.creditCard:
        return s.pmCreditCard;
      case PaymentMethod.prepaidCard:
        return s.pmPrepaidCard;
      case PaymentMethod.card:
        return s.pmCard;
      case PaymentMethod.bankTransfer:
        return s.pmBankTransfer;
      case PaymentMethod.transfer:
        return s.pmTransfer;
      case PaymentMethod.sepa:
        return s.pmSepa;
      case PaymentMethod.wire:
        return s.pmWire;
      case PaymentMethod.directDebit:
        return s.pmDirectDebit;
      case PaymentMethod.cheque:
        return s.paymentCheque;
      case PaymentMethod.voucher:
        return s.pmVoucher;
      case PaymentMethod.crypto:
        return s.pmCrypto;

      // Nombres que no se traducen (Estáticos)
      case PaymentMethod.bizum:
        return 'Bizum';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
    }
  }
  // --- Fecha ---

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- HU-03: Foto del ticket ---

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Añadir foto del ticket',
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text('Cámara', style: AppTypography.bodyMedium()),
                subtitle: Text(
                  'Hacer una foto ahora',
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text('Galería', style: AppTypography.bodyMedium()),
                subtitle: Text(
                  'Seleccionar de la galería',
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoPath != null) ...[
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  title: Text(
                    'Eliminar foto',
                    style: AppTypography.bodyMedium(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _photoPath = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Submit ---

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una categoría'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final transaction = TransactionEntity(
      amount: amount,
      type: _selectedType,
      category: _selectedCategory!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      photoPath: _photoPath,
      bankAccountId: _selectedBankAccountId,
      cardId: _selectedPaymentMethod.isCard ? _selectedBankCardId : null,
    );

    context.read<TransactionBloc>().add(
      AddTransaction(transaction: transaction),
    );

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      _isSubmitting = false;
      _showSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime date, BuildContext context) {
    final s = AppLocalizations.of(context);
    final months = [
      s.january,
      s.february,
      s.march,
      s.april,
      s.may,
      s.june,
      s.july,
      s.august,
      s.september,
      s.october,
      s.november,
      s.december,
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) {
      return '${s.today}, ${date.day} ${months[date.month - 1]}';
    }
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  action: SnackBarAction(
                    label: 'Reintentar',
                    textColor: AppColors.white,
                    onPressed: () {
                      setState(() {
                        _isSubmitting = false;
                        _showSuccess = false;
                      });
                    },
                  ),
                ),
              );
              setState(() {
                _isSubmitting = false;
                _showSuccess = false;
              });
            }
          },
        ),
        BlocListener<BankBloc, BankState>(
          listener: (context, state) {
            if (state is BankAccountsLoaded) {
              setState(() => _bankAccounts = state.accounts);
            } else if (state is BankCardsLoaded) {
              setState(() => _bankCards = state.cards);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(s.newTransaction, style: AppTypography.titleLarge()),
          centerTitle: true,
        ),
        body: ResponsiveBuilder(
          mobile: (context) => _buildMobileLayout(context),
          tablet: (context) => _buildTabletLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding,
            vertical: 8,
          ),
          child: _buildFormContent(context),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding,
            vertical: responsive.verticalPadding,
          ),
          child: Card(
            elevation: 0,
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _buildFormContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode:
          AutovalidateMode.onUserInteraction, // HU-03: tiempo real
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeSelector(context),
          const SizedBox(height: 24),
          _buildAmountField(context),
          const SizedBox(height: 24),
          _buildCategorySelector(context),
          const SizedBox(height: 24),
          _buildDescriptionField(context),
          const SizedBox(height: 24),
          _buildDateSelector(context),
          const SizedBox(height: 24),
          _buildPaymentMethodSelector(context),
          if (_selectedPaymentMethod.isCard ||
              _selectedPaymentMethod.isBank) ...[
            const SizedBox(height: 16),
            _buildAccountCardSelector(context),
          ],
          const SizedBox(height: 24),
          _buildPhotoTicketSection(context), // HU-03: foto del ticket
          const SizedBox(height: 32),
          _buildSubmitButton(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGETS DEL FORMULARIO
  // =========================================================================

  Widget _buildTypeSelector(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.transactionType,
          style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTypeOption(
                TransactionType.expense,
                s.expense,
                Icons.arrow_downward_rounded,
                AppColors.error,
              ),
              _buildTypeOption(
                TransactionType.income,
                s.income,
                Icons.arrow_upward_rounded,
                AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    TransactionType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
            _computeCategoryFrequency(); // Recalcular por tipo
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.white
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelLarge(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.amount,
          style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          // HU-03: teclado numérico por defecto
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          autofocus: true, // HU-03: foco automático para rapidez
          style: AppTypography.moneyLarge(
            color: _selectedType == TransactionType.expense
                ? AppColors.error
                : AppColors.success,
          ),
          textAlign: TextAlign.center,
          validator: _validateAmount,
          decoration: InputDecoration(
            hintText: '0,00',
            hintStyle: AppTypography.moneyLarge(
              color: AppColors.textTertiaryLight,
            ),
            prefixText: '€ ',
            prefixStyle: AppTypography.moneyLarge(
              color: _selectedType == TransactionType.expense
                  ? AppColors.error
                  : AppColors.success,
            ),
            filled: true,
            fillColor: AppColors.gray50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _selectedType == TransactionType.expense
                    ? AppColors.error
                    : AppColors.success,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// HU-03: Selector de categoría con autocompletado por historial.
  /// Las categorías más usadas aparecen primero y marcadas con un badge.
  Widget _buildCategorySelector(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        List<CategoryEntity> categories;
        if (categoryState is CategoriesLoaded) {
          categories = _selectedType == TransactionType.expense
              ? categoryState.expenseCategories
              : categoryState.incomeCategories;
        } else {
          categories = _selectedType == TransactionType.expense
              ? CategoryEntity.defaultExpenseCategories
              : CategoryEntity.defaultIncomeCategories;
        }

        // Ordenar por frecuencia de uso (historial) — autocompletado
        final sorted = [...categories];
        sorted.sort((a, b) {
          final freqA = _categoryFrequency[a.name] ?? 0;
          final freqB = _categoryFrequency[b.name] ?? 0;
          if (freqB != freqA) return freqB.compareTo(freqA);
          return a.displayOrder.compareTo(b.displayOrder);
        });

        // Las 2 más frecuentes del historial (si existen)
        final topCategories =
            _categoryFrequency.entries.where((e) => e.value > 0).toList()
              ..sort((a, b) => b.value.compareTo(a.value));
        final topNames = topCategories.take(2).map((e) => e.key).toSet();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.category,
                  style: AppTypography.labelMedium(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (topNames.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.hisorySuggestions,
                      style: AppTypography.labelSmall(color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sorted.map((cat) {
                final isSelected = _selectedCategory == cat.name;
                final catColor = cat.colorValue;
                final isTop = topNames.contains(cat.name);

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? catColor : AppColors.gray50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTop && !isSelected
                            ? catColor.withValues(alpha: 0.6)
                            : isSelected
                            ? Colors.transparent
                            : AppColors.gray200,
                        width: isTop && !isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: catColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.iconData,
                          size: 16,
                          color: isSelected ? AppColors.white : catColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getTranslatedCategory(context, cat.name),
                          style: AppTypography.labelMedium(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        // Indicador visual de categoría frecuente
                        if (isTop && !isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.trending_up_rounded,
                            size: 12,
                            color: catColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedCategory == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '* ${s.selectACategory}',
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.description,
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${s.optional})',
              style: AppTypography.bodySmall(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 2,
          maxLength: 500,
          style: AppTypography.input(),
          decoration: InputDecoration(
            hintText: s.exampleOfDescription,
            hintStyle: AppTypography.hint(),
            counterText: '',
            filled: true,
            fillColor: AppColors.gray50,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 12, bottom: 24),
              child: Icon(
                Icons.edit_note_rounded,
                color: AppColors.gray400,
                size: 22,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.date,
          style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(_formatDate(_selectedDate, context), style: AppTypography.input()),
                const Spacer(),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.gray400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // All methods shown in the UI (excludes legacy aliases)
  static const _displayMethods = [
    PaymentMethod.cash,
    PaymentMethod.debitCard,
    PaymentMethod.creditCard,
    PaymentMethod.prepaidCard,
    PaymentMethod.bankTransfer,
    PaymentMethod.sepa,
    PaymentMethod.wire,
    PaymentMethod.bizum,
    PaymentMethod.paypal,
    PaymentMethod.applePay,
    PaymentMethod.googlePay,
    PaymentMethod.directDebit,
    PaymentMethod.cheque,
    PaymentMethod.voucher,
    PaymentMethod.crypto,
  ];

  Widget _buildPaymentMethodSelector(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.paymentMethod,
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPaymentIcon(_selectedPaymentMethod),
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getPaymentMethodLabel(context, _selectedPaymentMethod),
                    style: AppTypography.labelSmall(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _displayMethods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final method = _displayMethods[i];
              final isSelected =
                  _selectedPaymentMethod == method ||
                  // Handle legacy alias selection
                  (_selectedPaymentMethod == PaymentMethod.card &&
                      method == PaymentMethod.debitCard) ||
                  (_selectedPaymentMethod == PaymentMethod.transfer &&
                      method == PaymentMethod.bankTransfer);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedPaymentMethod = method;
                  if (!method.isCard) _selectedBankCardId = null;
                  if (!method.isCard && !method.isBank) {
                    _selectedBankAccountId = null;
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray200,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPaymentIcon(method),
                        size: 22,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _shortPaymentLabel(context, method),
                        style: AppTypography.labelSmall(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCardSelector(BuildContext context) {
    final isCard = _selectedPaymentMethod.isCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank account selector (shown for card AND transfer methods)
        if (_bankAccounts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  size: 18,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context).noLinkedAccounts,
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text(
            isCard
                ? AppLocalizations.of(context).cardBankAccount
                : AppLocalizations.of(context).accounts,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedBankAccountId,
            hint: AppLocalizations.of(context).selectAccounts,
            items: _bankAccounts
                .map(
                  (acct) => DropdownMenuItem(
                    value: acct.id,
                    child: Text(
                      acct.iban != null
                          ? '${acct.accountName} (${acct.maskedIban})'
                          : acct.accountName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() {
              _selectedBankAccountId = val;
              _selectedBankCardId = null; // reset card on account change
            }),
          ),
          // Card selector (only for card methods)
          if (isCard) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).pmCard,
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final filteredCards = _selectedBankAccountId == null
                    ? _bankCards
                    : _bankCards
                          .where(
                            (c) => c.bankAccountId == _selectedBankAccountId,
                          )
                          .toList();
                if (filteredCards.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.credit_card_off_outlined,
                          size: 18,
                          color: AppColors.gray400,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context).noCardsInAccount,
                          style: AppTypography.bodySmall(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _buildDropdown(
                  value: _selectedBankCardId,
                  hint: AppLocalizations.of(context).selectCardOptional,
                  items: filteredCards
                      .map(
                        (card) => DropdownMenuItem(
                          value: card.id,
                          child: Text(
                            card.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedBankCardId = val),
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.gray50,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      hint: Text(
        hint,
        style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
      ),
      items: items,
      onChanged: onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.gray400,
      ),
      isExpanded: true,
    );
  }

  String _shortPaymentLabel(BuildContext context, PaymentMethod method) {
    final s = AppLocalizations.of(context);

    switch (method) {
      case PaymentMethod.cash:
        return s.paymentCash;
      case PaymentMethod.debitCard:
        return s.paymentDebit;
      case PaymentMethod.creditCard:
        return s.paymentCredit;
      case PaymentMethod.prepaidCard:
        return s.paymentPrepaid;
      case PaymentMethod.bankTransfer:
        return s.paymentTransfer;
      case PaymentMethod.directDebit:
        return s.paymentDirectDebit;
      case PaymentMethod.cheque:
        return s.paymentCheque;
      case PaymentMethod.voucher:
        return s.paymentVoucher;
      case PaymentMethod.crypto:
        return s.paymentCrypto;

      // Estos se quedan estáticos porque no cambian entre idiomas
      case PaymentMethod.sepa:
        return 'SEPA';
      case PaymentMethod.wire:
        return 'Wire';
      case PaymentMethod.bizum:
        return 'Bizum';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';

      default:
        return _getPaymentMethodLabel(context, _selectedPaymentMethod);
    }
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.debitCard:
      case PaymentMethod.card:
        return Icons.payment_rounded;
      case PaymentMethod.creditCard:
        return Icons.credit_card_rounded;
      case PaymentMethod.prepaidCard:
        return Icons.contactless_rounded;
      case PaymentMethod.bankTransfer:
      case PaymentMethod.transfer:
        return Icons.swap_horiz_rounded;
      case PaymentMethod.sepa:
        return Icons.account_balance_outlined;
      case PaymentMethod.wire:
        return Icons.language_rounded;
      case PaymentMethod.bizum:
        return Icons.phone_android_rounded;
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.applePay:
        return Icons.apple_rounded;
      case PaymentMethod.googlePay:
        return Icons.g_mobiledata_rounded;
      case PaymentMethod.directDebit:
        return Icons.autorenew_rounded;
      case PaymentMethod.cheque:
        return Icons.article_outlined;
      case PaymentMethod.voucher:
        return Icons.local_offer_outlined;
      case PaymentMethod.crypto:
        return Icons.currency_bitcoin_rounded;
    }
  }

  /// HU-03: Sección para añadir foto del ticket (opcional)
  Widget _buildPhotoTicketSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).receiptPhoto,
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${AppLocalizations.of(context).optional})',
              style: AppTypography.bodySmall(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photoPath != null)
          _buildPhotoPreview()
        else
          _buildPhotoPlaceholder(),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gray200,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.primary.withValues(alpha: 0.7),
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).addReceiptPhoto,
                style: AppTypography.labelMedium(
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_photoPath!),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _photoPath = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    color: AppColors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context).change,
                    style: AppTypography.labelSmall(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // HU-03: Botón de guardado con confirmación visual animada
  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showSuccess
            ? Container(
                key: const ValueKey('success'),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).transactionRecorded,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : GestureDetector(
                key: const ValueKey('button'),
                onTap: _isSubmitting ? null : _handleSubmit,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _isSubmitting ? null : AppColors.primaryGradient,
                    color: _isSubmitting ? AppColors.gray300 : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isSubmitting
                        ? null
                        : AppColors.shadowColor(AppColors.primary),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.save_rounded,
                                color: AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context).saveTransaction,
                                style: AppTypography.button(),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
      ),
    );
  }
}
