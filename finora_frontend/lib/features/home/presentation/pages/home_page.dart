import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';

/// Página Principal / Dashboard
///
/// Muestra un resumen de las finanzas del usuario con diseño responsive
/// que se adapta a diferentes tamaños de pantalla (RNF-12)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: ResponsiveBuilder(
        mobile: (context) => _buildMobileLayout(context),
        tablet: (context) => _buildTabletLayout(context),
      ),
      bottomNavigationBar: context.isMobile ? _buildBottomNav() : null,
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverToBoxAdapter(child: _buildHeader(context)),

          // Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
              ),
              child: _buildBalanceCard(context),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: _buildQuickActions(context),
            ),
          ),

          // Transactions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
              ),
              child: _buildSectionHeader('Últimas transacciones', 'Ver todas'),
            ),
          ),

          // Transactions List
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTransactionItem(context, index),
                childCount: 5,
              ),
            ),
          ),

          // Spending Chart Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: _buildSpendingChart(context),
            ),
          ),

          // Bottom Padding
          SliverToBoxAdapter(child: SizedBox(height: responsive.hp(10))),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SafeArea(
      child: Row(
        children: [
          // Navigation Rail para tablets
          _buildNavigationRail(),

          // Contenido principal
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),

                SliverPadding(
                  padding: EdgeInsets.all(responsive.horizontalPadding),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna izquierda
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildBalanceCard(context),
                              const SizedBox(height: 24),
                              _buildQuickActions(context),
                              const SizedBox(height: 24),
                              _buildSpendingChart(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Columna derecha
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildSectionHeader(
                                'Últimas transacciones',
                                'Ver todas',
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(
                                5,
                                (index) =>
                                    _buildTransactionItem(context, index),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Padding(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, Juan!',
                style: responsive.isMobile
                    ? AppTypography.headlineSmall()
                    : AppTypography.headlineMedium(),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido de nuevo',
                style: AppTypography.bodyMedium(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Notificaciones
              Container(
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Badge(
                    smallSize: 8,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () {},
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'JG',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.value(mobile: 20.0, tablet: 24.0)),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowColor(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance total',
                style: AppTypography.bodyMedium(
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: AppColors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Mostrar',
                      style: AppTypography.labelSmall(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '€ 12,458.50',
            style: responsive.isMobile
                ? AppTypography.moneyLarge(color: AppColors.white)
                : AppTypography.displaySmall(color: AppColors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBalanceIndicator(
                icon: Icons.arrow_upward_rounded,
                label: 'Ingresos',
                amount: '€ 4,250.00',
                color: AppColors.successLight,
              ),
              const SizedBox(width: 24),
              _buildBalanceIndicator(
                icon: Icons.arrow_downward_rounded,
                label: 'Gastos',
                amount: '€ 2,150.00',
                color: AppColors.errorLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                amount,
                style: AppTypography.titleSmall(color: AppColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_rounded,
        label: 'Añadir',
        color: AppColors.primary,
      ),
      _QuickAction(
        icon: Icons.send_rounded,
        label: 'Enviar',
        color: AppColors.secondary,
      ),
      _QuickAction(
        icon: Icons.qr_code_rounded,
        label: 'Escanear',
        color: AppColors.accent,
      ),
      _QuickAction(
        icon: Icons.more_horiz_rounded,
        label: 'Más',
        color: AppColors.gray500,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((action) => _buildQuickActionItem(action)).toList(),
    );
  }

  Widget _buildQuickActionItem(_QuickAction action) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(action.icon, color: action.color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          action.label,
          style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.titleMedium()),
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: AppTypography.labelMedium(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, int index) {
    final transactions = [
      _Transaction(
        icon: Icons.shopping_bag_outlined,
        title: 'Amazon',
        subtitle: 'Compras',
        amount: '-€ 89.99',
        isExpense: true,
        date: 'Hoy',
      ),
      _Transaction(
        icon: Icons.restaurant_outlined,
        title: 'Restaurante El Sol',
        subtitle: 'Alimentación',
        amount: '-€ 45.50',
        isExpense: true,
        date: 'Hoy',
      ),
      _Transaction(
        icon: Icons.work_outline_rounded,
        title: 'Nómina Empresa',
        subtitle: 'Salario',
        amount: '+€ 2,500.00',
        isExpense: false,
        date: 'Ayer',
      ),
      _Transaction(
        icon: Icons.flash_on_outlined,
        title: 'Iberdrola',
        subtitle: 'Facturas',
        amount: '-€ 78.30',
        isExpense: true,
        date: 'Ayer',
      ),
      _Transaction(
        icon: Icons.subscriptions_outlined,
        title: 'Netflix',
        subtitle: 'Suscripciones',
        amount: '-€ 15.99',
        isExpense: true,
        date: '20 Ene',
      ),
    ];

    final transaction = transactions[index % transactions.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: transaction.isExpense
                  ? AppColors.errorSoft
                  : AppColors.successSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction.icon,
              color: transaction.isExpense
                  ? AppColors.error
                  : AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: AppTypography.titleSmall()),
                const SizedBox(height: 2),
                Text(
                  transaction.subtitle,
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
                transaction.amount,
                style: AppTypography.titleSmall(
                  color: transaction.isExpense
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                transaction.date,
                style: AppTypography.bodySmall(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Container(
      padding: EdgeInsets.all(responsive.value(mobile: 20.0, tablet: 24.0)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gastos por categoría', style: AppTypography.titleMedium()),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Este mes', style: AppTypography.labelSmall()),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Placeholder para gráfico circular
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: responsive.value(mobile: 160.0, tablet: 180.0),
                  height: responsive.value(mobile: 160.0, tablet: 180.0),
                  child: CustomPaint(painter: _DonutChartPainter()),
                ),
                Column(
                  children: [
                    Text('€ 2,150', style: AppTypography.headlineSmall()),
                    Text(
                      'Total gastado',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Leyenda
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildLegendItem(
                'Alimentación',
                AppColors.categoryColors[0],
                '35%',
              ),
              _buildLegendItem(
                'Transporte',
                AppColors.categoryColors[1],
                '25%',
              ),
              _buildLegendItem('Ocio', AppColors.categoryColors[2], '20%'),
              _buildLegendItem('Otros', AppColors.categoryColors[3], '20%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text('$label $percentage', style: AppTypography.bodySmall()),
      ],
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedNavIndex = index);
      },
      backgroundColor: AppColors.surfaceLight,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.white,
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Inicio'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: Text('Estadísticas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: Text('Cuentas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: Text('Ajustes'),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Inicio', 0),
              _buildNavItem(Icons.analytics_rounded, 'Estadísticas', 1),
              _buildAddButton(),
              _buildNavItem(Icons.account_balance_wallet_rounded, 'Cuentas', 2),
              _buildNavItem(Icons.settings_rounded, 'Ajustes', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedNavIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: isSelected ? AppColors.primary : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowColor(AppColors.primary),
      ),
      child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
    );
  }
}

/// Modelo para acciones rápidas
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;

  _QuickAction({required this.icon, required this.label, required this.color});
}

/// Modelo para transacciones
class _Transaction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;
  final String date;

  _Transaction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.date,
  });
}

/// Painter para el gráfico de dona
class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Segmentos del gráfico
    final segments = [
      (0.35, AppColors.categoryColors[0]), // Alimentación 35%
      (0.25, AppColors.categoryColors[1]), // Transporte 25%
      (0.20, AppColors.categoryColors[2]), // Ocio 20%
      (0.20, AppColors.categoryColors[3]), // Otros 20%
    ];

    var startAngle = -90.0 * (3.14159 / 180); // Empezar desde arriba

    for (final segment in segments) {
      final sweepAngle = segment.$1 * 2 * 3.14159;
      paint.color = segment.$2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.05, // Pequeño gap entre segmentos
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
