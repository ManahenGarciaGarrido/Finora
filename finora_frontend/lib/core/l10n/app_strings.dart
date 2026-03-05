/// RNF-13: Localización e internacionalización — sistema de strings multiidioma
///
/// Soporta español (España) e inglés (Internacional).
/// Detección automática del idioma del sistema.
/// Los textos se acceden vía `AppStrings.forLocale(code)`.
///
/// Idiomas soportados:
///   - es (Español — España) — idioma por defecto
///   - en (English — International)
///
/// Para añadir un nuevo idioma:
///   1. Crear una nueva clase que extienda [AppStringsBase]
///   2. Registrarla en [AppStrings.forLocale]
library;

import 'dart:ui' show Locale, PlatformDispatcher;

/// Clase base abstracta con todas las claves de cadenas de texto.
abstract class AppStringsBase {
  // ── Navegación ─────────────────────────────────────────────────────────────
  String get home;
  String get transactions;
  String get statistics;
  String get goals;
  String get settings;

  // ── Autenticación ──────────────────────────────────────────────────────────
  String get login;
  String get logout;
  String get register;
  String get email;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get biometricLogin;
  String get twoFactorAuth;

  // ── Transacciones ──────────────────────────────────────────────────────────
  String get addTransaction;
  String get editTransaction;
  String get deleteTransaction;
  String get income;
  String get expense;
  String get category;
  String get description;
  String get amount;
  String get date;
  String get paymentMethod;
  String get noTransactions;

  // ── Estadísticas ───────────────────────────────────────────────────────────
  String get spendingByCategory;
  String get temporalEvolution;
  String get period;
  String get monthPeriod;
  String get sixMonths;
  String get yearPeriod;

  // ── Objetivos de ahorro ────────────────────────────────────────────────────
  String get savingsGoals;
  String get createGoal;
  String get targetAmount;
  String get currentAmount;
  String get deadline;
  String get progress;
  String get addContribution;
  String get noGoals;

  // ── Presupuestos ───────────────────────────────────────────────────────────
  String get budgets;
  String get newBudget;
  String get monthlyLimit;
  String get budgetStatus;
  String get overBudget;
  String get nearLimit;

  // ── Exportación ────────────────────────────────────────────────────────────
  String get exportData;
  String get exportCsv;
  String get exportPdf;
  String get dateRange;
  String get from;
  String get to;
  String get share;
  String get generating;

  // ── Notificaciones ─────────────────────────────────────────────────────────
  String get notifications;
  String get pushTransactions;
  String get pushBudgetAlerts;
  String get pushGoalReminders;
  String get minAmount;
  String get quietHours;
  String get noNotifications;

  // ── Seguridad ──────────────────────────────────────────────────────────────
  String get security;
  String get changePassword;
  String get biometricAuth;
  String get setup2fa;
  String get scan2faQr;
  String get verifyCode;
  String get recoveryCodes;
  String get disable2fa;

  // ── General ────────────────────────────────────────────────────────────────
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get confirm;
  String get loading;
  String get error;
  String get retry;
  String get search;
  String get filter;
  String get all;
  String get noData;
  String get comingSoon;
  String get language;
  String get spanish;
  String get english;

  // ── Onboarding ─────────────────────────────────────────────────────────────
  String get onboardingSkip;
  String get onboardingNext;
  String get onboardingStart;
  String get onboarding1Title;
  String get onboarding1Subtitle;
  String get onboarding2Title;
  String get onboarding2Subtitle;
  String get onboarding3Title;
  String get onboarding3Subtitle;
  String get onboarding4Title;
  String get onboarding4Subtitle;

  // ── Errores ────────────────────────────────────────────────────────────────
  String get networkError;
  String get authError;
  String get unknownError;
  String get sessionExpired;

  // ── Formateo ───────────────────────────────────────────────────────────────
  String get locale; // 'es_ES' | 'en_US'
  String get currencySymbol; // '€' | '$'
  String get dateFormat; // 'dd/MM/yyyy' | 'MM/dd/yyyy'
}

// ── Español (España) ──────────────────────────────────────────────────────────

class _AppStringsEs extends AppStringsBase {
  @override
  String get home => 'Inicio';
  @override
  String get transactions => 'Transacciones';
  @override
  String get statistics => 'Estadísticas';
  @override
  String get goals => 'Objetivos';
  @override
  String get settings => 'Ajustes';

  @override
  String get login => 'Iniciar sesión';
  @override
  String get logout => 'Cerrar sesión';
  @override
  String get register => 'Crear cuenta';
  @override
  String get email => 'Correo electrónico';
  @override
  String get password => 'Contraseña';
  @override
  String get confirmPassword => 'Confirmar contraseña';
  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';
  @override
  String get biometricLogin => 'Acceso biométrico';
  @override
  String get twoFactorAuth => 'Autenticación en dos pasos';

  @override
  String get addTransaction => 'Añadir transacción';
  @override
  String get editTransaction => 'Editar transacción';
  @override
  String get deleteTransaction => 'Eliminar transacción';
  @override
  String get income => 'Ingreso';
  @override
  String get expense => 'Gasto';
  @override
  String get category => 'Categoría';
  @override
  String get description => 'Descripción';
  @override
  String get amount => 'Importe';
  @override
  String get date => 'Fecha';
  @override
  String get paymentMethod => 'Método de pago';
  @override
  String get noTransactions => 'Sin transacciones';

  @override
  String get spendingByCategory => 'Gastos por categoría';
  @override
  String get temporalEvolution => 'Evolución temporal';
  @override
  String get period => 'Período';
  @override
  String get monthPeriod => 'Mes';
  @override
  String get sixMonths => '6 meses';
  @override
  String get yearPeriod => 'Año';

  @override
  String get savingsGoals => 'Objetivos de ahorro';
  @override
  String get createGoal => 'Nuevo objetivo';
  @override
  String get targetAmount => 'Importe objetivo';
  @override
  String get currentAmount => 'Ahorrado hasta ahora';
  @override
  String get deadline => 'Fecha límite';
  @override
  String get progress => 'Progreso';
  @override
  String get addContribution => 'Añadir aportación';
  @override
  String get noGoals => 'Sin objetivos';

  @override
  String get budgets => 'Presupuestos';
  @override
  String get newBudget => 'Nuevo presupuesto';
  @override
  String get monthlyLimit => 'Límite mensual';
  @override
  String get budgetStatus => 'Estado del presupuesto';
  @override
  String get overBudget => 'Presupuesto superado';
  @override
  String get nearLimit => 'Cerca del límite';

  @override
  String get exportData => 'Exportar datos';
  @override
  String get exportCsv => 'Exportar a CSV';
  @override
  String get exportPdf => 'Generar informe PDF';
  @override
  String get dateRange => 'Rango de fechas';
  @override
  String get from => 'Desde';
  @override
  String get to => 'Hasta';
  @override
  String get share => 'Compartir';
  @override
  String get generating => 'Generando...';

  @override
  String get notifications => 'Notificaciones';
  @override
  String get pushTransactions => 'Nuevas transacciones';
  @override
  String get pushBudgetAlerts => 'Alertas de presupuesto';
  @override
  String get pushGoalReminders => 'Recordatorios de objetivos';
  @override
  String get minAmount => 'Importe mínimo';
  @override
  String get quietHours => 'Horas de silencio';
  @override
  String get noNotifications => 'Sin notificaciones';

  @override
  String get security => 'Seguridad';
  @override
  String get changePassword => 'Cambiar contraseña';
  @override
  String get biometricAuth => 'Autenticación biométrica';
  @override
  String get setup2fa => 'Configurar 2FA';
  @override
  String get scan2faQr => 'Escanea el código QR con tu app autenticadora';
  @override
  String get verifyCode => 'Verificar código';
  @override
  String get recoveryCodes => 'Códigos de recuperación';
  @override
  String get disable2fa => 'Desactivar 2FA';

  @override
  String get save => 'Guardar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get delete => 'Eliminar';
  @override
  String get edit => 'Editar';
  @override
  String get confirm => 'Confirmar';
  @override
  String get loading => 'Cargando...';
  @override
  String get error => 'Error';
  @override
  String get retry => 'Reintentar';
  @override
  String get search => 'Buscar';
  @override
  String get filter => 'Filtrar';
  @override
  String get all => 'Todos';
  @override
  String get noData => 'Sin datos';
  @override
  String get comingSoon => 'Próximamente';
  @override
  String get language => 'Idioma';
  @override
  String get spanish => 'Español';
  @override
  String get english => 'English';

  @override
  String get onboardingSkip => 'Saltar';
  @override
  String get onboardingNext => 'Siguiente';
  @override
  String get onboardingStart => '¡Empezar ahora!';
  @override
  String get onboarding1Title => 'Bienvenido a Finora';
  @override
  String get onboarding1Subtitle => 'Tu gestor financiero personal inteligente';
  @override
  String get onboarding2Title => 'Registra transacciones fácilmente';
  @override
  String get onboarding2Subtitle => 'Manual o conectando tu banco';
  @override
  String get onboarding3Title => 'Visualiza tus finanzas';
  @override
  String get onboarding3Subtitle => 'Gráficos interactivos y predicciones';
  @override
  String get onboarding4Title => 'Alcanza tus metas';
  @override
  String get onboarding4Subtitle =>
      'Objetivos de ahorro con recomendaciones IA';

  @override
  String get networkError => 'Sin conexión. Comprueba tu internet.';
  @override
  String get authError => 'Credenciales incorrectas';
  @override
  String get unknownError => 'Error inesperado. Inténtalo de nuevo.';
  @override
  String get sessionExpired => 'Sesión expirada. Inicia sesión de nuevo.';

  @override
  String get locale => 'es_ES';
  @override
  String get currencySymbol => '€';
  @override
  String get dateFormat => 'dd/MM/yyyy';
}

// ── English (International) ───────────────────────────────────────────────────

class _AppStringsEn extends AppStringsBase {
  @override
  String get home => 'Home';
  @override
  String get transactions => 'Transactions';
  @override
  String get statistics => 'Statistics';
  @override
  String get goals => 'Goals';
  @override
  String get settings => 'Settings';

  @override
  String get login => 'Sign in';
  @override
  String get logout => 'Sign out';
  @override
  String get register => 'Create account';
  @override
  String get email => 'Email address';
  @override
  String get password => 'Password';
  @override
  String get confirmPassword => 'Confirm password';
  @override
  String get forgotPassword => 'Forgot password?';
  @override
  String get biometricLogin => 'Biometric login';
  @override
  String get twoFactorAuth => 'Two-factor authentication';

  @override
  String get addTransaction => 'Add transaction';
  @override
  String get editTransaction => 'Edit transaction';
  @override
  String get deleteTransaction => 'Delete transaction';
  @override
  String get income => 'Income';
  @override
  String get expense => 'Expense';
  @override
  String get category => 'Category';
  @override
  String get description => 'Description';
  @override
  String get amount => 'Amount';
  @override
  String get date => 'Date';
  @override
  String get paymentMethod => 'Payment method';
  @override
  String get noTransactions => 'No transactions';

  @override
  String get spendingByCategory => 'Spending by category';
  @override
  String get temporalEvolution => 'Temporal evolution';
  @override
  String get period => 'Period';
  @override
  String get monthPeriod => 'Month';
  @override
  String get sixMonths => '6 months';
  @override
  String get yearPeriod => 'Year';

  @override
  String get savingsGoals => 'Savings goals';
  @override
  String get createGoal => 'New goal';
  @override
  String get targetAmount => 'Target amount';
  @override
  String get currentAmount => 'Saved so far';
  @override
  String get deadline => 'Deadline';
  @override
  String get progress => 'Progress';
  @override
  String get addContribution => 'Add contribution';
  @override
  String get noGoals => 'No goals yet';

  @override
  String get budgets => 'Budgets';
  @override
  String get newBudget => 'New budget';
  @override
  String get monthlyLimit => 'Monthly limit';
  @override
  String get budgetStatus => 'Budget status';
  @override
  String get overBudget => 'Over budget';
  @override
  String get nearLimit => 'Near limit';

  @override
  String get exportData => 'Export data';
  @override
  String get exportCsv => 'Export to CSV';
  @override
  String get exportPdf => 'Generate PDF report';
  @override
  String get dateRange => 'Date range';
  @override
  String get from => 'From';
  @override
  String get to => 'To';
  @override
  String get share => 'Share';
  @override
  String get generating => 'Generating...';

  @override
  String get notifications => 'Notifications';
  @override
  String get pushTransactions => 'New transactions';
  @override
  String get pushBudgetAlerts => 'Budget alerts';
  @override
  String get pushGoalReminders => 'Goal reminders';
  @override
  String get minAmount => 'Minimum amount';
  @override
  String get quietHours => 'Quiet hours';
  @override
  String get noNotifications => 'No notifications';

  @override
  String get security => 'Security';
  @override
  String get changePassword => 'Change password';
  @override
  String get biometricAuth => 'Biometric authentication';
  @override
  String get setup2fa => 'Set up 2FA';
  @override
  String get scan2faQr => 'Scan the QR code with your authenticator app';
  @override
  String get verifyCode => 'Verify code';
  @override
  String get recoveryCodes => 'Recovery codes';
  @override
  String get disable2fa => 'Disable 2FA';

  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get confirm => 'Confirm';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error';
  @override
  String get retry => 'Retry';
  @override
  String get search => 'Search';
  @override
  String get filter => 'Filter';
  @override
  String get all => 'All';
  @override
  String get noData => 'No data';
  @override
  String get comingSoon => 'Coming soon';
  @override
  String get language => 'Language';
  @override
  String get spanish => 'Español';
  @override
  String get english => 'English';

  @override
  String get onboardingSkip => 'Skip';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingStart => 'Get started!';
  @override
  String get onboarding1Title => 'Welcome to Finora';
  @override
  String get onboarding1Subtitle => 'Your smart personal finance manager';
  @override
  String get onboarding2Title => 'Track transactions easily';
  @override
  String get onboarding2Subtitle => 'Manual entry or bank sync';
  @override
  String get onboarding3Title => 'Visualize your finances';
  @override
  String get onboarding3Subtitle => 'Interactive charts and ML predictions';
  @override
  String get onboarding4Title => 'Reach your goals';
  @override
  String get onboarding4Subtitle => 'Savings goals with AI recommendations';

  @override
  String get networkError => 'No connection. Check your internet.';
  @override
  String get authError => 'Invalid credentials';
  @override
  String get unknownError => 'Unexpected error. Please try again.';
  @override
  String get sessionExpired => 'Session expired. Please sign in again.';

  @override
  String get locale => 'en_US';
  @override
  String get currencySymbol => '€'; // App uses EUR
  @override
  String get dateFormat => 'MM/dd/yyyy';
}

// ── Factory principal ─────────────────────────────────────────────────────────

/// Punto de acceso global a las cadenas de texto localizadas.
///
/// Uso:
/// ```dart
/// // Strings por defecto (español):
/// AppStrings.es.login
///
/// // Por locale:
/// AppStrings.forLocale('en').save
/// ```
class AppStrings {
  AppStrings._();

  static final AppStringsBase es = _AppStringsEs();
  static final AppStringsBase en = _AppStringsEn();

  /// Devuelve las strings correspondientes al locale indicado.
  /// Si el locale no está soportado, devuelve español como fallback.
  static AppStringsBase forLocale(String localeCode) {
    switch (localeCode.split('_').first.toLowerCase()) {
      case 'en':
        return en;
      case 'es':
      default:
        return es;
    }
  }

  /// Detecta el idioma del sistema y devuelve las strings correspondientes.
  static AppStringsBase fromSystemLocale() {
    final systemLocale = PlatformDispatcher.instance.locale.languageCode;
    return forLocale(systemLocale);
  }

  /// Lista de locales soportados por la aplicación.
  static const supportedLocales = [Locale('es', 'ES'), Locale('en', 'US')];
}
