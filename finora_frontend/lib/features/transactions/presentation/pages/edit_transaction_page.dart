import 'dart:io';

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

/// Página de Edición de Transacciones (RF-06)
///
/// Permite al usuario modificar cualquier campo de una transacción
/// registrada previamente. Incluye:
/// - Formulario pre-rellenado con datos actuales
/// - Validación de todos los campos modificados
/// - Confirmación antes de guardar
/// - Actualización del balance y estadísticas de categorías
/// - Registro de última modificación (timestamp)
class EditTransactionPage extends StatefulWidget {
  final TransactionEntity transaction;

  const EditTransactionPage({super.key, required this.transaction});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late TransactionType _selectedType;
  String? _selectedCategory;
  late DateTime _selectedDate;
  late PaymentMethod _selectedPaymentMethod;
  String? _photoPath;

  bool _isSubmitting = false;
  bool _showSuccess = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Frecuencia de categorías del historial para autocompletado
  Map<String, int> _categoryFrequency = {};

  @override
  void initState() {
    super.initState();

    // Pre-rellenar con datos actuales de la transacción
    final t = widget.transaction;
    _amountController = TextEditingController(
      text: t.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _descriptionController = TextEditingController(text: t.description ?? '');
    _selectedType = t.type;
    _selectedCategory = t.category;
    _selectedDate = t.date;
    _selectedPaymentMethod = t.paymentMethod;
    _photoPath = t.photoPath;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
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
      }
    });
  }

  void _computeCategoryFrequency() {
    final bloc = context.read<TransactionBloc>();
    final freq = <String, int>{};
    for (final t in bloc.transactions) {
      if (t.type == _selectedType && t.id != widget.transaction.id) {
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

  // --- Foto del ticket ---

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
              Text('Foto del ticket', style: AppTypography.titleMedium()),
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

  // --- Confirmación antes de guardar (RF-06) ---

  Future<bool> _showConfirmationDialog() async {
    final t = widget.transaction;
    final newAmount = double.parse(_amountController.text.replaceAll(',', '.'));
    final amountChanged = newAmount != t.amount;
    final typeChanged = _selectedType != t.type;
    final categoryChanged = _selectedCategory != t.category;
    final descChanged =
        (_descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim()) !=
        t.description;
    final dateChanged = _selectedDate != t.date;
    final paymentChanged = _selectedPaymentMethod != t.paymentMethod;

    final hasChanges =
        amountChanged ||
        typeChanged ||
        categoryChanged ||
        descChanged ||
        dateChanged ||
        paymentChanged;

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No has realizado ningún cambio'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text('Confirmar cambios', style: AppTypography.titleMedium()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas guardar los siguientes cambios?',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 12),
            if (amountChanged)
              _buildChangeSummaryRow(
                Icons.euro_rounded,
                'Cantidad',
                '${t.amount.toStringAsFixed(2)} → ${newAmount.toStringAsFixed(2)} €',
              ),
            if (typeChanged)
              _buildChangeSummaryRow(
                Icons.swap_vert_rounded,
                'Tipo',
                '${t.type.label} → ${_selectedType.label}',
              ),
            if (categoryChanged)
              _buildChangeSummaryRow(
                Icons.category_rounded,
                'Categoría',
                '${t.category} → ${_selectedCategory ?? ''}',
              ),
            if (dateChanged)
              _buildChangeSummaryRow(
                Icons.calendar_today_rounded,
                'Fecha',
                '${_formatDateShort(t.date)} → ${_formatDateShort(_selectedDate)}',
              ),
            if (paymentChanged)
              _buildChangeSummaryRow(
                Icons.payment_rounded,
                'Método de pago',
                '${t.paymentMethod.label} → ${_selectedPaymentMethod.label}',
              ),
            if (descChanged)
              _buildChangeSummaryRow(
                Icons.edit_note_rounded,
                'Descripción',
                'Modificada',
              ),
            if (amountChanged || typeChanged) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.warningDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El balance y las estadísticas se recalcularán automáticamente.',
                        style: AppTypography.bodySmall(
                          color: AppColors.warningDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildChangeSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: AppTypography.labelSmall(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelSmall(
                color: AppColors.textPrimaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

    // Mostrar diálogo de confirmación antes de guardar (RF-06)
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    widget.transaction.copyWith(
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
    );

    // Manejar descripción (puede ser null si se borró)
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    // Crear transacción con todos los campos actualizados
    final finalTransaction = TransactionEntity(
      id: widget.transaction.id,
      amount: amount,
      type: _selectedType,
      category: _selectedCategory!,
      description: description,
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      photoPath: _photoPath,
      createdAt: widget.transaction.createdAt,
      syncStatus: widget.transaction.syncStatus,
    );

    context.read<TransactionBloc>().add(
      EditTransaction(transaction: finalTransaction),
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

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) {
      return 'Hoy, ${date.day} de ${months[date.month - 1]}';
    }
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  // =========================================================================
  // RF-07: Confirmación y eliminación desde la página de edición
  // =========================================================================

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text('Eliminar transacción', style: AppTypography.titleMedium()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar esta transacción?',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción es permanente y no se puede deshacer.',
                      style: AppTypography.bodySmall(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<TransactionBloc>().add(
        DeleteTransaction(transactionId: widget.transaction.id!),
      );
      Navigator.pop(context); // Cerrar página de edición
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
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
          title: Text('Editar transacción', style: AppTypography.titleLarge()),
          centerTitle: true,
          // RF-07: Botón de eliminar en la barra superior
          actions: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              tooltip: 'Eliminar transacción',
              onPressed: () => _confirmDelete(context),
            ),
          ],
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de última modificación (RF-06)
          if (widget.transaction.updatedAt != null) _buildLastModifiedBanner(),
          _buildTypeSelector(),
          const SizedBox(height: 24),
          _buildAmountField(),
          const SizedBox(height: 24),
          _buildCategorySelector(),
          const SizedBox(height: 24),
          _buildDescriptionField(),
          const SizedBox(height: 24),
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildPaymentMethodSelector(),
          const SizedBox(height: 24),
          _buildPhotoTicketSection(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =========================================================================
  // WIDGETS DEL FORMULARIO
  // =========================================================================

  /// Banner informativo de última modificación (RF-06)
  Widget _buildLastModifiedBanner() {
    final updatedAt = widget.transaction.updatedAt!;
    final formatted = _formatDateShort(updatedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Última modificación: $formatted',
            style: AppTypography.bodySmall(color: AppColors.primary),
          ),
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
                'Gasto',
                Icons.arrow_downward_rounded,
                AppColors.error,
              ),
              _buildTypeOption(
                TransactionType.income,
                'Ingreso',
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
            _computeCategoryFrequency();
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

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad',
          style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
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

        final sorted = [...categories];
        sorted.sort((a, b) {
          final freqA = _categoryFrequency[a.name] ?? 0;
          final freqB = _categoryFrequency[b.name] ?? 0;
          if (freqB != freqA) return freqB.compareTo(freqA);
          return a.displayOrder.compareTo(b.displayOrder);
        });

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
                  'Categoría',
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
                      'Sugeridas por historial',
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
                          cat.name,
                          style: AppTypography.labelMedium(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
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
                Text(_formatDate(_selectedDate), style: AppTypography.input()),
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

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Método de pago',
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
                    _selectedPaymentMethod.label,
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
                  (_selectedPaymentMethod == PaymentMethod.card &&
                      method == PaymentMethod.debitCard) ||
                  (_selectedPaymentMethod == PaymentMethod.transfer &&
                      method == PaymentMethod.bankTransfer);
              return GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = method),
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
                        _shortPaymentLabel(method),
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

  String _shortPaymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.debitCard:
        return 'Débito';
      case PaymentMethod.creditCard:
        return 'Crédito';
      case PaymentMethod.prepaidCard:
        return 'Prepago';
      case PaymentMethod.bankTransfer:
        return 'Transfer.';
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
      case PaymentMethod.directDebit:
        return 'Recibo';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.voucher:
        return 'Vale';
      case PaymentMethod.crypto:
        return 'Cripto';
      default:
        return method.label;
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

  Widget _buildPhotoTicketSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Foto del ticket',
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
          border: Border.all(color: AppColors.gray200),
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
                'Añadir foto del ticket',
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
                    'Cambiar',
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
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Transacción actualizada',
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
                                'Guardar cambios',
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
