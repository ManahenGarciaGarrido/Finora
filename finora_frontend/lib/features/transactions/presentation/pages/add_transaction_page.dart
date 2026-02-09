import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';

/// Página de Registro Manual de Transacciones (RF-05)
///
/// Permite al usuario registrar manualmente gastos e ingresos especificando:
/// - Cantidad (numérica, positiva)
/// - Tipo (gasto/ingreso)
/// - Categoría (selección)
/// - Descripción (texto libre, opcional)
/// - Fecha (default: hoy)
/// - Método de pago (efectivo, tarjeta, transferencia)
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
  PaymentMethod _selectedPaymentMethod = PaymentMethod.card;

  bool _isSubmitting = false;
  bool _showSuccess = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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

    final amount = double.parse(
      _amountController.text.replaceAll(',', '.'),
    );

    final transaction = TransactionEntity(
      amount: amount,
      type: _selectedType,
      category: _selectedCategory!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
    );

    // Añadir la transacción al BLoC
    context.read<TransactionBloc>().add(
      AddTransaction(transaction: transaction),
    );

    // Pequeña espera para simular procesamiento
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      _isSubmitting = false;
      _showSuccess = true;
    });

    // Mostrar confirmación y volver al dashboard
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoy, ${date.day} de ${months[date.month - 1]}';
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nueva transacción',
          style: AppTypography.titleLarge(),
        ),
        centerTitle: true,
      ),
      body: ResponsiveBuilder(
        mobile: (context) => _buildMobileLayout(context),
        tablet: (context) => _buildTabletLayout(context),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de tipo (Gasto / Ingreso)
          _buildTypeSelector(),
          const SizedBox(height: 24),

          // Campo de cantidad
          _buildAmountField(),
          const SizedBox(height: 24),

          // Selector de categoría
          _buildCategorySelector(),
          const SizedBox(height: 24),

          // Campo de descripción
          _buildDescriptionField(),
          const SizedBox(height: 24),

          // Selector de fecha
          _buildDateSelector(),
          const SizedBox(height: 24),

          // Selector de método de pago
          _buildPaymentMethodSelector(),
          const SizedBox(height: 32),

          // Botón de guardar
          _buildSubmitButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de transacción',
          style: AppTypography.labelMedium(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = TransactionType.expense;
                      _selectedCategory = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedType == TransactionType.expense
                          ? AppColors.error
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedType == TransactionType.expense
                          ? [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
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
                          Icons.arrow_downward_rounded,
                          size: 18,
                          color: _selectedType == TransactionType.expense
                              ? AppColors.white
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Gasto',
                          style: AppTypography.labelLarge(
                            color: _selectedType == TransactionType.expense
                                ? AppColors.white
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = TransactionType.income;
                      _selectedCategory = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedType == TransactionType.income
                          ? AppColors.success
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedType == TransactionType.income
                          ? [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.3),
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
                          Icons.arrow_upward_rounded,
                          size: 18,
                          color: _selectedType == TransactionType.income
                              ? AppColors.white
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ingreso',
                          style: AppTypography.labelLarge(
                            color: _selectedType == TransactionType.income
                                ? AppColors.white
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad',
          style: AppTypography.labelMedium(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
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

  Widget _buildCategorySelector() {
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categoría',
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat.name;
                final catColor = cat.colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catColor
                          : AppColors.gray50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.gray200,
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
                          color: isSelected
                              ? AppColors.white
                              : catColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: AppTypography.labelMedium(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
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
                  '* Selecciona una categoría',
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

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Descripción',
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(opcional)',
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
            hintText: 'Ej: Compra semanal del supermercado',
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

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha',
          style: AppTypography.labelMedium(
            color: AppColors.textSecondaryLight,
          ),
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
                Text(
                  _formatDate(_selectedDate),
                  style: AppTypography.input(),
                ),
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

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de pago',
          style: AppTypography.labelMedium(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: PaymentMethod.values.map((method) {
            final isSelected = _selectedPaymentMethod == method;
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedPaymentMethod = method),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: method != PaymentMethod.transfer ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.gray200,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
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
                        method.label,
                        style: AppTypography.labelSmall(
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
          }).toList(),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.transfer:
        return Icons.swap_horiz_rounded;
    }
  }

  Widget _buildSubmitButton() {
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
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Transacción registrada',
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
                              const Icon(Icons.save_rounded,
                                  color: AppColors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Guardar transacción',
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
