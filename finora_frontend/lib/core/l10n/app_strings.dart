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
  // ── Saludo ─────────────────────────────────────────────────────────────────
  String get hi;
  String get goodMorning;
  String get goodAfternoon;
  String get goodNight;

  // ── Meses ──────────────────────────────────────────────────────────────────
  String get january;
  String get february;
  String get march;
  String get april;
  String get may;
  String get june;
  String get july;
  String get august;
  String get september;
  String get october;
  String get november;
  String get december;

  String get jan;
  String get feb;
  String get mar;
  String get apr;
  String get mayy;
  String get jun;
  String get jul;
  String get aug;
  String get sep;
  String get oct;
  String get nov;
  String get dec;

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
  String get history;
  String get monthlySummary;

  // ── Estadísticas ───────────────────────────────────────────────────────────
  String get spendingByCategory;
  String get monthlyComparative;
  String get topMonthlyExpenses;
  String get nextExpenses;
  String get temporalEvolution;
  String get period;
  String get days;
  String get monthPeriod;
  String get thisMonth;
  String get sixMonths;
  String get yearPeriod;

  // ── Objetivos de ahorro ────────────────────────────────────────────────────
  String get savingsGoals;
  String get seeAll;
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
  String get inc;
  String get exp;
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

  // ── Navegación principal ────────────────────────────────────────────────────
  String get accounts;
  String get analysis;

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
  String get registerTransactions;
  String get emptyTopExpenses;
  String get onboarding2Subtitle;
  String get onboarding3Title;
  String get onboarding3Subtitle;
  String get withoutRecurringExpenses;
  String get recurringTimeLeft;
  String get onboarding4Title;
  String get onboarding4Subtitle;

  // ── Errores ────────────────────────────────────────────────────────────────
  String get networkError;
  String get authError;
  String get unknownError;
  String get sessionExpired;

  // ── Categorías ─────────────────────────────────────────────────────────────
  String get nutrition;
  String get transport;
  String get leisure;
  String get health;
  String get housing;
  String get services;
  String get education;
  String get clothing;
  String get other;
  String get saving;

  // ── Ajustes — secciones ────────────────────────────────────────────────────
  String get sectionGeneral;
  String get sectionSecurity;
  String get sectionData;
  String get settingsCategories;
  String get settingsCategoriesSubtitle;
  String get settingsNotifications;
  String get settingsNotificationsSubtitle;
  String get settingsBudgets;
  String get settingsBudgetsSubtitle;
  String get settingsCurrency;
  String get settingsChangePassword;
  String get settingsChangePasswordSubtitle;
  String get settingsBiometric2fa;
  String get settingsDataPrivacy;
  String get settingsExportData;
  String get settingsExportDataSubtitle;
  String get settingsPsd2;
  String get settingsPsd2Subtitle;
  String get settingsPrivacy;
  String get settingsPrivacySubtitle;
  String get settingsLogout;
  String get changingLanguage;

  // ── Formateo ───────────────────────────────────────────────────────────────
  String get locale; // 'es_ES' | 'en_US'
  String get currencySymbol; // '€' | '$'
  String get dateFormat; // 'dd/MM/yyyy' | 'MM/dd/yyyy'

  // ── Autenticación — mensajes de UI ─────────────────────────────────────────
  String get welcomeBack;
  String get signInToContinue;
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String get emailVerificationPending;
  String get emailNotVerifiedMsg;
  String get checkInboxMsg;
  String get resendEmail;
  String get spendingTrend;
  String get understood;
  String get authenticating;
  String get accessWith;
  String get noAccountYet;
  String get emailHint;

  // ── Registro ───────────────────────────────────────────────────────────────
  String get fullName;
  String get nameRequired;
  String get nameHint;
  String get confirmPasswordRequired;
  String get passwordsDoNotMatch;
  String get alreadyHaveAccount;
  String get passwordMinLength;

  // ── Validación general ─────────────────────────────────────────────────────
  String get ok;
  String get fieldRequired;
  String get amountRequired;
  String get amountInvalid;

  // ── Estadísticas — adicional ───────────────────────────────────────────────
  String get incomes;
  String get balance;
  String get expenses;
  String get noDataForPeriod;
  String get threeMonths;
  String get totalIncome;
  String get totalExpenses;
  String get netBalance;

  // ── Cuentas ────────────────────────────────────────────────────────────────
  String get totalBalance;
  String get addAccount;
  String get noAccounts;
  String get linkedBanks;
  String get addBankAccount;
  String get disconnect;
  String get manualAccount;
  String get bankAccountLabel;
  String get accountName;
  String get initialBalance;
  String get connectBank;
  String get bankConnected;

  // ── Categorías ─────────────────────────────────────────────────────────────
  String get noCategories;
  String get addCategory;
  String get categoryName;
  String get selectIcon;
  String get selectColor;
  String get categoryType;

  // ── Notificaciones — adicional ─────────────────────────────────────────────
  String get enableNotifications;
  String get notificationFilters;
  String get fromTime;
  String get toTime;

  // ── Presupuestos — adicional ───────────────────────────────────────────────
  String get noBudgets;
  String get addBudget;
  String get spent;
  String get remaining;
  String get ofAmount;
  String get budgetProgress;

  // ── Autenticación biométrica ───────────────────────────────────────────────
  String get enableBiometric;
  String get biometricNotAvailable;
  String get biometricDescription;
  String get disableBiometric;

  // ── 2FA ────────────────────────────────────────────────────────────────────
  String get enter2faCode;
  String get code2faHint;
  String get enable2fa;
  String get twoFaEnabled;
  String get twoFaDisabled;
  String get copyCode;
  String get codeCopied;

  // ── Consentimientos PSD2 ───────────────────────────────────────────────────
  String get consents;
  String get consentExpires;
  String get revokeConsent;
  String get active;
  String get expired;
  String get noConsents;
  String get consentStatus;

  // ── Objetivos — adicional ──────────────────────────────────────────────────
  String get goalName;
  String get goalNameHint;
  String get noGoalsYet;
  String get createFirstGoal;
  String get contributionAmount;
  String get goalProgress;
  String get daysLeft;
  String get completed;

  // ── Transacciones — adicional ──────────────────────────────────────────────
  String get transactionType;
  String get selectCategory;
  String get note;
  String get noteHint;
  String get recentTransactions;

  // ── Privacidad / GDPR ─────────────────────────────────────────────────────
  String get privacyPolicy;
  String get termsOfService;
  String get dataConsent;
  String get deleteAccount;
  String get downloadData;

  // ── Privacidad — UI strings ────────────────────────────────────────────────
  String get privacyAndData;
  String get gdprCompliance;
  String get viewPrivacyPolicy;
  String get consentManagement;
  String get consentManagementSubtitle;
  String get savePreferences;
  String get gdprRights;
  String get dangerZone;
  String get dangerZoneDesc;
  String get deleteMyAccount;
  String get preferencesSavedSuccess;
  String get exportMyData;
  String get dataExportedTitle;
  String get dataSummary;
  String get deleteAccountConfirmTitle;
  String get confirmDeletionTitle;
  String get deleteDefinitely;
  String get deleteConfirmHint;
  String get deleteReasonHint;
  String get typeDeleteToConfirmError;
  String get accountPermanentlyDeleted;
  String get editProfileComingSoon;
  String get noConsentChanges;
  String get privacyPolicyTitle;
  String get acceptedStatus;
  String get rejectedStatus;
  String get consentHistoryTitle;
  String get consentHistoryDesc;
  String get dataProcessingInfoTitle;
  String get dataProcessingInfoDesc;
  String get rightOfAccess;
  String get rightOfAccessDesc;
  String get rightOfRectification;
  String get rightOfRectificationDesc;

  // ── Asistente IA ─────────────────────────────────────────────────────────
  String get assistantOnlineStatus;
  String get pinchToZoom;
  String get seeRecommendations;
  String get typeYourQuestion;
  String get assistantConnectionError;
  String get affordabilityYes;
  String get affordabilityNo;
  String get affordabilityMaybe;
  String get availableBalanceLabel;
  String get balanceAfterPurchase;
  String get monthlySurplusLabel;
  String get couldSaveIn;
  String get impactOnGoalsLabel;
  String get noImpactLabel;
  String get alternativesLabel;
  String get predictionsAI;
  String get subtitleAI;
  String get finnAsisstant;
  String get subtitleFinn;
  String get lastTransactions;

  // ── Bancos — UI strings ───────────────────────────────────────────────────
  String get selectAccounts;
  String get selectAllAccounts;
  String get deselectAccounts;
  String get selectAtLeastOneAccount;
  String get linkVerb;
  String get encryptedConnectionLabel;
  String get readOnlyLabel;
  String get psd2CertifiedLabel;
  String get connectingBankTitle;
  String get openingBrowserMsg;
  String get bankOpeningTitle;
  String get bankWaitingAuthTitle;
  String get bankAuthCompleteInBrowserMsg;
  String get bankAuthReturnMsg;
  String get bankInitiatingConnectionMsg;
  String get technicalSupport;
  String get bankRetryConnection;
  String get bankChooseOtherBank;
  String get bankContactSupport;
  String get bankWhatYouCanDo;
  String get newAccountTitle;
  String get accountTypeLabel;
  String get ibanOptional;
  String get saveAccountBtn;
  String get addCardTitle;
  String get selectCsvFile;
  String get dontCloseAppMsg;
  String get aiAnalysisLabel;
  String get configureAccountMsg;
  String get cardsLabel;
  String get noCardsOptional;
  String get importCsvLabel;
  String get creditCardType;
  String get debitCardType;
  String get prepaidCardType;
  String get lastFourDigitsOptional;
  String get enterAccountNameError;
  String get csvImportDesc;

  // ── Misc ───────────────────────────────────────────────────────────────────
  String get appVersion;
  String get close;
  String get next;
  String get back;
  String get skip;
  String get done;
  String get add;
  String get name;
  String get type;
  String get optional;
  String get required;
  String get enabled;
  String get disabled;
  String get on;
  String get off;

  // ── Mensajes dinámicos (con parámetro) ────────────────────────────────────
  String categoryCreatedMsg(String name);
  String categoryUpdatedMsg(String name);
  String categoryDeletedMsg(String name);
  String goalCreatedMsg(String name);
  String budgetCreatedMsg(String name);
  String budgetUpdatedMsg(String name);
  String budgetDeletedMsg(String name);
  String accountDeletedMsg(String name);
}

// ── Español (España) ──────────────────────────────────────────────────────────

class _AppStringsEs extends AppStringsBase {
  @override
  String get hi => 'Hola';
  @override
  String get goodMorning => 'Buenos días';
  @override
  String get goodAfternoon => 'Buenas tardes';
  @override
  String get goodNight => 'Buenas noches';

  @override
  String get january => 'Enero';
  @override
  String get february => 'Febrero';
  @override
  String get march => 'Marzo';
  @override
  String get april => 'Abril';
  @override
  String get may => 'Mayo';
  @override
  String get june => 'Junio';
  @override
  String get july => 'Julio';
  @override
  String get august => 'Agosto';
  @override
  String get september => 'Septiembre';
  @override
  String get october => 'Octubre';
  @override
  String get november => 'Noviembre';
  @override
  String get december => 'Diciembre';
  @override
  String get jan => 'Ene';
  @override
  String get feb => 'Feb';
  @override
  String get mar => 'Mar';
  @override
  String get apr => 'Abr';
  @override
  String get mayy => 'May';
  @override
  String get jun => 'Jun';
  @override
  String get jul => 'Jul';
  @override
  String get aug => 'Ago';
  @override
  String get sep => 'Sep';
  @override
  String get oct => 'Oct';
  @override
  String get nov => 'Nov';
  @override
  String get dec => 'Dic';

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
  String get history => 'Historial';
  @override
  String get monthlySummary => 'Resumen del mes';

  @override
  String get spendingByCategory => 'Gastos por categoría';
  @override
  String get monthlyComparative => 'Comparativa mensual';
  @override
  String get topMonthlyExpenses => 'Top gastos del mes';
  @override
  String get nextExpenses => 'Próximos gastos';
  @override
  String get temporalEvolution => 'Evolución temporal';
  @override
  String get period => 'Período';
  @override
  String get days => 'Días';
  @override
  String get monthPeriod => 'Mes';
  @override
  String get thisMonth => 'Este mes';
  @override
  String get sixMonths => '6 meses';
  @override
  String get yearPeriod => 'Año';

  @override
  String get accounts => 'Cuentas';
  @override
  String get analysis => 'Análisis';

  @override
  String get savingsGoals => 'Objetivos de ahorro';
  @override
  String get seeAll => 'Ver todos';
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
  String get inc => 'Ing.';
  @override
  String get exp => 'Gas.';
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
  String get registerTransactions =>
      'Registra transacciones para ver el gráfico';
  @override
  String get emptyTopExpenses => 'Registra gastos para ver el desglose';
  @override
  String get onboarding2Subtitle => 'Manual o conectando tu banco';
  @override
  String get onboarding3Title => 'Visualiza tus finanzas';
  @override
  String get onboarding3Subtitle => 'Gráficos interactivos y predicciones';
  @override
  String get withoutRecurringExpenses => 'Sin gastos recurrentes próximos';
  @override
  String get recurringTimeLeft =>
      'Los pagos recurrentes aparecerán aquí cuando se aproxime su vencimiento';
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
  String get nutrition => 'Alimentación';
  @override
  String get transport => 'Transporte';
  @override
  String get leisure => 'Ocio';
  @override
  String get health => 'Salud';
  @override
  String get housing => 'Vivienda';
  @override
  String get services => 'Servicios';
  @override
  String get education => 'Educación';
  @override
  String get clothing => 'Ropa';
  @override
  String get other => 'Otros';
  @override
  String get saving => 'Ahorro';

  @override
  String get sectionGeneral => 'General';
  @override
  String get sectionSecurity => 'Seguridad';
  @override
  String get sectionData => 'Datos y privacidad';
  @override
  String get settingsCategories => 'Categorías';
  @override
  String get settingsCategoriesSubtitle =>
      'Gestionar categorías de gastos e ingresos';
  @override
  String get settingsNotifications => 'Notificaciones';
  @override
  String get settingsNotificationsSubtitle =>
      'Alertas de transacciones, presupuesto y objetivos';
  @override
  String get settingsBudgets => 'Presupuestos';
  @override
  String get settingsBudgetsSubtitle =>
      'Límites de gasto por categoría y alertas';
  @override
  String get settingsCurrency => 'Moneda y formato';
  @override
  String get settingsChangePassword => 'Cambiar contraseña';
  @override
  String get settingsChangePasswordSubtitle =>
      'Actualizar contraseña de acceso';
  @override
  String get settingsBiometric2fa => 'Autenticación 2FA';
  @override
  String get settingsDataPrivacy => 'Datos y privacidad';
  @override
  String get settingsExportData => 'Exportar datos';
  @override
  String get settingsExportDataSubtitle => 'Descargar historial en CSV o PDF';
  @override
  String get settingsPsd2 => 'Cuentas bancarias PSD2';
  @override
  String get settingsPsd2Subtitle =>
      'Gestionar consentimientos de Open Banking';
  @override
  String get settingsPrivacy => 'Privacidad y GDPR';
  @override
  String get settingsPrivacySubtitle => 'Tus datos, consentimientos y derechos';
  @override
  String get settingsLogout => 'Cerrar sesión';
  @override
  String get changingLanguage => 'Aplicando idioma...';

  @override
  String get locale => 'es_ES';
  @override
  String get currencySymbol => '€';
  @override
  String get dateFormat => 'dd/MM/yyyy';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';
  @override
  String get signInToContinue => 'Inicia sesión para continuar';
  @override
  String get emailRequired => 'El correo electrónico es requerido';
  @override
  String get emailInvalid => 'Ingresa un correo electrónico válido';
  @override
  String get passwordRequired => 'La contraseña es requerida';
  @override
  String get emailVerificationPending => 'Verificación Pendiente';
  @override
  String get emailNotVerifiedMsg =>
      'Tu correo electrónico aún no ha sido verificado.';
  @override
  String get checkInboxMsg =>
      'Por favor, revisa tu bandeja de entrada y haz clic en el enlace de verificación que te enviamos.';
  @override
  String get resendEmail => 'Reenviar Email';
  @override
  String get spendingTrend => 'Tendencia de gastos';
  @override
  String get understood => 'Entendido';
  @override
  String get authenticating => 'Autenticando...';
  @override
  String get accessWith => 'Acceder con';
  @override
  String get noAccountYet => '¿No tienes una cuenta?';
  @override
  String get emailHint => 'correo@ejemplo.com';

  @override
  String get fullName => 'Nombre completo';
  @override
  String get nameRequired => 'El nombre es requerido';
  @override
  String get nameHint => 'Juan García';
  @override
  String get confirmPasswordRequired => 'Por favor, confirma tu contraseña';
  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';
  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';
  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get ok => 'Aceptar';
  @override
  String get fieldRequired => 'Este campo es requerido';
  @override
  String get amountRequired => 'El importe es requerido';
  @override
  String get amountInvalid => 'Ingresa un importe válido';

  @override
  String get incomes => 'Ingresos';
  @override
  String get balance => 'Balance';
  @override
  String get expenses => 'Gastos';
  @override
  String get noDataForPeriod => 'Sin datos para este período';
  @override
  String get threeMonths => '3 meses';
  @override
  String get totalIncome => 'Total ingresos';
  @override
  String get totalExpenses => 'Total gastos';
  @override
  String get netBalance => 'Balance neto';

  @override
  String get totalBalance => 'Balance total';
  @override
  String get addAccount => 'Añadir cuenta';
  @override
  String get noAccounts => 'Sin cuentas';
  @override
  String get linkedBanks => 'Bancos vinculados';
  @override
  String get addBankAccount => 'Añadir cuenta bancaria';
  @override
  String get disconnect => 'Desconectar';
  @override
  String get manualAccount => 'Cuenta manual';
  @override
  String get bankAccountLabel => 'Cuenta bancaria';
  @override
  String get accountName => 'Nombre de cuenta';
  @override
  String get initialBalance => 'Saldo inicial';
  @override
  String get connectBank => 'Conectar banco';
  @override
  String get bankConnected => 'Banco conectado';

  @override
  String get noCategories => 'Sin categorías';
  @override
  String get addCategory => 'Añadir categoría';
  @override
  String get categoryName => 'Nombre de categoría';
  @override
  String get selectIcon => 'Seleccionar icono';
  @override
  String get selectColor => 'Seleccionar color';
  @override
  String get categoryType => 'Tipo de categoría';

  @override
  String get enableNotifications => 'Activar notificaciones';
  @override
  String get notificationFilters => 'Filtros de notificación';
  @override
  String get fromTime => 'Desde';
  @override
  String get toTime => 'Hasta';

  @override
  String get noBudgets => 'Sin presupuestos';
  @override
  String get addBudget => 'Añadir presupuesto';
  @override
  String get spent => 'Gastado';
  @override
  String get remaining => 'Restante';
  @override
  String get ofAmount => 'de';
  @override
  String get budgetProgress => 'Progreso del presupuesto';

  @override
  String get enableBiometric => 'Activar biométrico';
  @override
  String get biometricNotAvailable => 'No disponible en este dispositivo';
  @override
  String get biometricDescription =>
      'Usa tu huella dactilar o Face ID para acceder de forma rápida y segura';
  @override
  String get disableBiometric => 'Desactivar biométrico';

  @override
  String get enter2faCode => 'Introduce el código de 6 dígitos';
  @override
  String get code2faHint => 'Código de 6 dígitos';
  @override
  String get enable2fa => 'Activar 2FA';
  @override
  String get twoFaEnabled => '2FA activado';
  @override
  String get twoFaDisabled => '2FA desactivado';
  @override
  String get copyCode => 'Copiar código';
  @override
  String get codeCopied => 'Código copiado';

  @override
  String get consents => 'Consentimientos';
  @override
  String get consentExpires => 'Expira';
  @override
  String get revokeConsent => 'Revocar';
  @override
  String get active => 'Activo';
  @override
  String get expired => 'Expirado';
  @override
  String get noConsents => 'Sin consentimientos';
  @override
  String get consentStatus => 'Estado';

  @override
  String get goalName => 'Nombre del objetivo';
  @override
  String get goalNameHint => 'Ej: Vacaciones, Coche...';
  @override
  String get noGoalsYet => 'Sin objetivos todavía';
  @override
  String get createFirstGoal =>
      'Crea tu primer objetivo de ahorro\ny la IA te ayudará a alcanzarlo.';
  @override
  String get contributionAmount => 'Importe de la aportación';
  @override
  String get goalProgress => 'Progreso del objetivo';
  @override
  String get daysLeft => 'días restantes';
  @override
  String get completed => 'Completado';

  @override
  String get transactionType => 'Tipo de transacción';
  @override
  String get selectCategory => 'Seleccionar categoría';
  @override
  String get note => 'Nota';
  @override
  String get noteHint => 'Descripción opcional...';
  @override
  String get recentTransactions => 'Transacciones recientes';

  @override
  String get privacyPolicy => 'Política de privacidad';
  @override
  String get termsOfService => 'Términos de servicio';
  @override
  String get dataConsent => 'Consentimiento de datos';
  @override
  String get deleteAccount => 'Eliminar cuenta';
  @override
  String get downloadData => 'Descargar mis datos';

  @override
  String get privacyAndData => 'Privacidad y Datos';
  @override
  String get gdprCompliance => 'Cumplimiento GDPR';
  @override
  String get viewPrivacyPolicy => 'Ver Política de Privacidad';
  @override
  String get consentManagement => 'Gestión de Consentimientos';
  @override
  String get consentManagementSubtitle =>
      'Controla qué datos recopilamos y cómo los usamos.';
  @override
  String get savePreferences => 'Guardar Preferencias';
  @override
  String get gdprRights => 'Tus Derechos GDPR';
  @override
  String get dangerZone => 'Zona de Peligro';
  @override
  String get dangerZoneDesc =>
      'Estas acciones son irreversibles. Procede con precaución.';
  @override
  String get deleteMyAccount => 'Eliminar mi cuenta';
  @override
  String get preferencesSavedSuccess => 'Preferencias guardadas correctamente';
  @override
  String get exportMyData => 'Exportar mis datos';
  @override
  String get dataExportedTitle => 'Datos Exportados';
  @override
  String get dataSummary => 'Resumen de tus datos:';
  @override
  String get deleteAccountConfirmTitle => 'Eliminar Cuenta';
  @override
  String get confirmDeletionTitle => 'Confirmar Eliminación';
  @override
  String get deleteDefinitely => 'Eliminar Definitivamente';
  @override
  String get deleteConfirmHint => 'Escribe ELIMINAR';
  @override
  String get deleteReasonHint => 'Razón para eliminar (opcional)';
  @override
  String get typeDeleteToConfirmError => 'Escribe "ELIMINAR" para confirmar';
  @override
  String get accountPermanentlyDeleted =>
      'Cuenta eliminada permanentemente. Gracias por usar Finora.';
  @override
  String get editProfileComingSoon => 'Edición de perfil: próximamente';
  @override
  String get noConsentChanges =>
      'No hay cambios registrados en tus preferencias.';
  @override
  String get privacyPolicyTitle => 'Política de Privacidad';
  @override
  String get acceptedStatus => 'Aceptado';
  @override
  String get rejectedStatus => 'Rechazado';
  @override
  String get consentHistoryTitle => 'Historial de Consentimientos';
  @override
  String get consentHistoryDesc => 'Consulta los cambios en tus preferencias';
  @override
  String get dataProcessingInfoTitle => 'Información de Tratamiento';
  @override
  String get dataProcessingInfoDesc => 'Conoce cómo procesamos tus datos';
  @override
  String get rightOfAccess => 'Derecho de Acceso';
  @override
  String get rightOfAccessDesc => 'Obtén una copia de todos tus datos';
  @override
  String get rightOfRectification => 'Derecho de Rectificación';
  @override
  String get rightOfRectificationDesc =>
      'Corrige datos inexactos (próximamente)';

  @override
  String get assistantOnlineStatus => 'Asistente IA · En línea';
  @override
  String get pinchToZoom => 'Pellizca para ampliar';
  @override
  String get seeRecommendations => 'Ver recomendaciones';
  @override
  String get typeYourQuestion => 'Escribe tu pregunta...';
  @override
  String get assistantConnectionError =>
      'Lo siento, no pude conectar con el asistente. Verifica tu conexión e inténtalo de nuevo.';
  @override
  String get affordabilityYes => 'Sí puedes';
  @override
  String get affordabilityNo => 'No puedes';
  @override
  String get affordabilityMaybe => 'Con precaución';
  @override
  String get availableBalanceLabel => 'Balance disponible';
  @override
  String get balanceAfterPurchase => 'Balance tras compra';
  @override
  String get monthlySurplusLabel => 'Superávit mensual';
  @override
  String get couldSaveIn => 'Podrías ahorrar en';
  @override
  String get impactOnGoalsLabel => 'Impacto en objetivos:';
  @override
  String get noImpactLabel => 'Sin impacto';
  @override
  String get alternativesLabel => 'Alternativas:';
  @override
  String get predictionsAI => 'Predicciones IA';
  @override
  String get subtitleAI => 'Gastos del próximo mes y recomendaciones de ahorro';
  @override
  String get finnAsisstant => 'Asistente Finn';
  @override
  String get subtitleFinn =>
      '¿En qué pudeo ayudarte hoy?\n'
      'Pregúntame lo que quieras';
  @override
  String get lastTransactions => 'Últimas transacciones';

  @override
  String get selectAccounts => 'Seleccionar cuentas';
  @override
  String get selectAllAccounts => 'Seleccionar todas';
  @override
  String get deselectAccounts => 'Deseleccionar';
  @override
  String get selectAtLeastOneAccount => 'Selecciona al menos una cuenta';
  @override
  String get linkVerb => 'Vincular';
  @override
  String get encryptedConnectionLabel => 'Conexión cifrada';
  @override
  String get readOnlyLabel => 'Solo lectura';
  @override
  String get psd2CertifiedLabel => 'PSD2 certificado';
  @override
  String get connectingBankTitle => 'Conectando banco';
  @override
  String get openingBrowserMsg => 'Abriendo el navegador...';
  @override
  String get bankOpeningTitle => 'Abriendo tu banco';
  @override
  String get bankWaitingAuthTitle => 'Esperando autorización';
  @override
  String get bankAuthCompleteInBrowserMsg =>
      'Completa la autorización en el navegador para continuar.';
  @override
  String get bankAuthReturnMsg =>
      'Una vez que autorices en el navegador, volverás automáticamente a Finora.';
  @override
  String get bankInitiatingConnectionMsg => 'Iniciando la conexión segura con';
  @override
  String get technicalSupport => 'Soporte técnico';
  @override
  String get bankRetryConnection => 'Reintentar conexión';
  @override
  String get bankChooseOtherBank => 'Elegir otro banco';
  @override
  String get bankContactSupport => '¿Necesitas ayuda? Contacta con soporte';
  @override
  String get bankWhatYouCanDo => 'Qué puedes hacer';
  @override
  String get newAccountTitle => 'Nueva cuenta';
  @override
  String get accountTypeLabel => 'Tipo de cuenta';
  @override
  String get ibanOptional => 'IBAN (opcional)';
  @override
  String get saveAccountBtn => 'Guardar cuenta';
  @override
  String get addCardTitle => 'Añadir tarjeta';
  @override
  String get selectCsvFile => 'Seleccionar archivo CSV';
  @override
  String get dontCloseAppMsg => 'No cierres la aplicación durante este proceso';
  @override
  String get aiAnalysisLabel => 'Análisis IA';
  @override
  String get configureAccountMsg => 'Configura tu cuenta para empezar';
  @override
  String get cardsLabel => 'Tarjetas';
  @override
  String get noCardsOptional => 'Sin tarjetas — opcional';
  @override
  String get importCsvLabel => 'Importar movimientos (CSV)';
  @override
  String get creditCardType => 'Crédito';
  @override
  String get debitCardType => 'Débito';
  @override
  String get prepaidCardType => 'Prepago';
  @override
  String get lastFourDigitsOptional => 'Últimos 4 dígitos (opcional)';
  @override
  String get enterAccountNameError => 'Introduce un nombre';
  @override
  String get csvImportDesc =>
      'Importa el historial de movimientos de tu cuenta.';

  @override
  String get appVersion => 'Versión';
  @override
  String get close => 'Cerrar';
  @override
  String get next => 'Siguiente';
  @override
  String get back => 'Atrás';
  @override
  String get skip => 'Saltar';
  @override
  String get done => 'Listo';
  @override
  String get add => 'Añadir';
  @override
  String get name => 'Nombre';
  @override
  String get type => 'Tipo';
  @override
  String get optional => 'Opcional';
  @override
  String get required => 'Requerido';
  @override
  String get enabled => 'Activado';
  @override
  String get disabled => 'Desactivado';
  @override
  String get on => 'Sí';
  @override
  String get off => 'No';

  @override
  String categoryCreatedMsg(String name) => 'Categoría "$name" creada';
  @override
  String categoryUpdatedMsg(String name) => 'Categoría "$name" actualizada';
  @override
  String categoryDeletedMsg(String name) => 'Categoría "$name" eliminada';
  @override
  String goalCreatedMsg(String name) => 'Objetivo "$name" creado';
  @override
  String budgetCreatedMsg(String name) => 'Presupuesto "$name" creado';
  @override
  String budgetUpdatedMsg(String name) => 'Presupuesto "$name" actualizado';
  @override
  String budgetDeletedMsg(String name) => 'Presupuesto "$name" eliminado';
  @override
  String accountDeletedMsg(String name) => 'Cuenta "$name" eliminada';
}

// ── English (International) ───────────────────────────────────────────────────

class _AppStringsEn extends AppStringsBase {
  @override
  String get hi => 'Hello';
  @override
  String get goodMorning => 'Good Morning';
  @override
  String get goodAfternoon => 'Good Afternoon';
  @override
  String get goodNight => 'Good Night';

  @override
  String get january => 'January';
  @override
  String get february => 'February';
  @override
  String get march => 'March';
  @override
  String get april => 'April';
  @override
  String get may => 'May';
  @override
  String get june => 'Jun';
  @override
  String get july => 'July';
  @override
  String get august => 'August';
  @override
  String get september => 'September';
  @override
  String get october => 'October';
  @override
  String get november => 'November';
  @override
  String get december => 'December';
  @override
  String get jan => 'Jan';
  @override
  String get feb => 'Feb';
  @override
  String get mar => 'Mar';
  @override
  String get apr => 'Apr';
  @override
  String get mayy => 'May';
  @override
  String get jun => 'Jun';
  @override
  String get jul => 'Jul';
  @override
  String get aug => 'Aug';
  @override
  String get sep => 'Sep';
  @override
  String get oct => 'Oct';
  @override
  String get nov => 'Nov';
  @override
  String get dec => 'Dec';

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
  String get history => 'History';
  @override
  String get monthlySummary => 'Monthly summary';

  @override
  String get spendingByCategory => 'Spending by category';
  @override
  String get monthlyComparative => 'Monthly comparative';
  @override
  String get topMonthlyExpenses => 'Top monthly expenses';
  @override
  String get nextExpenses => 'Upcoming expenses';
  @override
  String get temporalEvolution => 'Temporal evolution';
  @override
  String get period => 'Period';
  @override
  String get days => 'Days';
  @override
  String get monthPeriod => 'Month';
  @override
  String get thisMonth => 'This month';
  @override
  String get sixMonths => '6 months';
  @override
  String get yearPeriod => 'Year';

  @override
  String get accounts => 'Accounts';
  @override
  String get analysis => 'Analysis';

  @override
  String get savingsGoals => 'Savings goals';
  @override
  String get seeAll => 'See all';
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
  String get inc => 'Inc.';
  @override
  String get exp => 'Exp.';
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
  String get registerTransactions => 'Record trsansactions to see the chart';
  @override
  String get emptyTopExpenses => 'Record expenses to see the breakdown';
  @override
  String get onboarding2Subtitle => 'Manual entry or bank sync';
  @override
  String get onboarding3Title => 'Visualize your finances';
  @override
  String get onboarding3Subtitle => 'Interactive charts and ML predictions';
  @override
  String get withoutRecurringExpenses => 'Without upcoming recurring expenses';
  @override
  String get recurringTimeLeft =>
      'Recurring payments will appear here as their due date approaches';
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
  String get nutrition => 'Nutrition';
  @override
  String get transport => 'Transport';
  @override
  String get leisure => 'Leisure';
  @override
  String get health => 'Health';
  @override
  String get housing => 'Housing';
  @override
  String get services => 'Services';
  @override
  String get education => 'Education';
  @override
  String get clothing => 'Clothing';
  @override
  String get other => 'Other';
  @override
  String get saving => 'Saving';

  @override
  String get sectionGeneral => 'General';
  @override
  String get sectionSecurity => 'Security';
  @override
  String get sectionData => 'Data & privacy';
  @override
  String get settingsCategories => 'Categories';
  @override
  String get settingsCategoriesSubtitle =>
      'Manage income and expense categories';
  @override
  String get settingsNotifications => 'Notifications';
  @override
  String get settingsNotificationsSubtitle =>
      'Transaction, budget and goal alerts';
  @override
  String get settingsBudgets => 'Budgets';
  @override
  String get settingsBudgetsSubtitle =>
      'Spending limits by category and alerts';
  @override
  String get settingsCurrency => 'Currency & format';
  @override
  String get settingsChangePassword => 'Change password';
  @override
  String get settingsChangePasswordSubtitle => 'Update your access password';
  @override
  String get settingsBiometric2fa => '2FA authentication';
  @override
  String get settingsDataPrivacy => 'Data & privacy';
  @override
  String get settingsExportData => 'Export data';
  @override
  String get settingsExportDataSubtitle => 'Download history as CSV or PDF';
  @override
  String get settingsPsd2 => 'PSD2 bank accounts';
  @override
  String get settingsPsd2Subtitle => 'Manage Open Banking consents';
  @override
  String get settingsPrivacy => 'Privacy & GDPR';
  @override
  String get settingsPrivacySubtitle => 'Your data, consents and rights';
  @override
  String get settingsLogout => 'Sign out';
  @override
  String get changingLanguage => 'Applying language...';

  @override
  String get locale => 'en_US';
  @override
  String get currencySymbol => '€'; // App uses EUR
  @override
  String get dateFormat => 'MM/dd/yyyy';

  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get signInToContinue => 'Sign in to continue';
  @override
  String get emailRequired => 'Email address is required';
  @override
  String get emailInvalid => 'Enter a valid email address';
  @override
  String get passwordRequired => 'Password is required';
  @override
  String get emailVerificationPending => 'Verification Pending';
  @override
  String get emailNotVerifiedMsg =>
      'Your email address has not been verified yet.';
  @override
  String get checkInboxMsg =>
      'Please check your inbox and click the verification link we sent you.';
  @override
  String get resendEmail => 'Resend Email';
  @override
  String get spendingTrend => 'Spending trend';
  @override
  String get understood => 'Got it';
  @override
  String get authenticating => 'Authenticating...';
  @override
  String get accessWith => 'Sign in with';
  @override
  String get noAccountYet => "Don't have an account?";
  @override
  String get emailHint => 'email@example.com';

  @override
  String get fullName => 'Full name';
  @override
  String get nameRequired => 'Name is required';
  @override
  String get nameHint => 'John Smith';
  @override
  String get confirmPasswordRequired => 'Please confirm your password';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get alreadyHaveAccount => 'Already have an account?';
  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get ok => 'OK';
  @override
  String get fieldRequired => 'This field is required';
  @override
  String get amountRequired => 'Amount is required';
  @override
  String get amountInvalid => 'Enter a valid amount';

  @override
  String get incomes => 'Income';
  @override
  String get balance => 'Balance';
  @override
  String get expenses => 'Expenses';
  @override
  String get noDataForPeriod => 'No data for this period';
  @override
  String get threeMonths => '3 months';
  @override
  String get totalIncome => 'Total income';
  @override
  String get totalExpenses => 'Total expenses';
  @override
  String get netBalance => 'Net balance';

  @override
  String get totalBalance => 'Total balance';
  @override
  String get addAccount => 'Add account';
  @override
  String get noAccounts => 'No accounts';
  @override
  String get linkedBanks => 'Linked banks';
  @override
  String get addBankAccount => 'Add bank account';
  @override
  String get disconnect => 'Disconnect';
  @override
  String get manualAccount => 'Manual account';
  @override
  String get bankAccountLabel => 'Bank account';
  @override
  String get accountName => 'Account name';
  @override
  String get initialBalance => 'Initial balance';
  @override
  String get connectBank => 'Connect bank';
  @override
  String get bankConnected => 'Bank connected';

  @override
  String get noCategories => 'No categories';
  @override
  String get addCategory => 'Add category';
  @override
  String get categoryName => 'Category name';
  @override
  String get selectIcon => 'Select icon';
  @override
  String get selectColor => 'Select color';
  @override
  String get categoryType => 'Category type';

  @override
  String get enableNotifications => 'Enable notifications';
  @override
  String get notificationFilters => 'Notification filters';
  @override
  String get fromTime => 'From';
  @override
  String get toTime => 'To';

  @override
  String get noBudgets => 'No budgets';
  @override
  String get addBudget => 'Add budget';
  @override
  String get spent => 'Spent';
  @override
  String get remaining => 'Remaining';
  @override
  String get ofAmount => 'of';
  @override
  String get budgetProgress => 'Budget progress';

  @override
  String get enableBiometric => 'Enable biometric';
  @override
  String get biometricNotAvailable => 'Not available on this device';
  @override
  String get biometricDescription =>
      'Use your fingerprint or Face ID for quick and secure access';
  @override
  String get disableBiometric => 'Disable biometric';

  @override
  String get enter2faCode => 'Enter the 6-digit code';
  @override
  String get code2faHint => '6-digit code';
  @override
  String get enable2fa => 'Enable 2FA';
  @override
  String get twoFaEnabled => '2FA enabled';
  @override
  String get twoFaDisabled => '2FA disabled';
  @override
  String get copyCode => 'Copy code';
  @override
  String get codeCopied => 'Code copied';

  @override
  String get consents => 'Consents';
  @override
  String get consentExpires => 'Expires';
  @override
  String get revokeConsent => 'Revoke';
  @override
  String get active => 'Active';
  @override
  String get expired => 'Expired';
  @override
  String get noConsents => 'No consents';
  @override
  String get consentStatus => 'Status';

  @override
  String get goalName => 'Goal name';
  @override
  String get goalNameHint => 'e.g. Vacation, Car...';
  @override
  String get noGoalsYet => 'No goals yet';
  @override
  String get createFirstGoal =>
      'Create your first savings goal\nand AI will help you reach it.';
  @override
  String get contributionAmount => 'Contribution amount';
  @override
  String get goalProgress => 'Goal progress';
  @override
  String get daysLeft => 'days left';
  @override
  String get completed => 'Completed';

  @override
  String get transactionType => 'Transaction type';
  @override
  String get selectCategory => 'Select category';
  @override
  String get note => 'Note';
  @override
  String get noteHint => 'Optional description...';
  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get privacyPolicy => 'Privacy policy';
  @override
  String get termsOfService => 'Terms of service';
  @override
  String get dataConsent => 'Data consent';
  @override
  String get deleteAccount => 'Delete account';
  @override
  String get downloadData => 'Download my data';

  @override
  String get privacyAndData => 'Privacy & Data';
  @override
  String get gdprCompliance => 'GDPR Compliance';
  @override
  String get viewPrivacyPolicy => 'View Privacy Policy';
  @override
  String get consentManagement => 'Consent Management';
  @override
  String get consentManagementSubtitle =>
      'Control what data we collect and how we use it.';
  @override
  String get savePreferences => 'Save Preferences';
  @override
  String get gdprRights => 'Your GDPR Rights';
  @override
  String get dangerZone => 'Danger Zone';
  @override
  String get dangerZoneDesc =>
      'These actions are irreversible. Proceed with caution.';
  @override
  String get deleteMyAccount => 'Delete my account';
  @override
  String get preferencesSavedSuccess => 'Preferences saved successfully';
  @override
  String get exportMyData => 'Export my data';
  @override
  String get dataExportedTitle => 'Data Exported';
  @override
  String get dataSummary => 'Your data summary:';
  @override
  String get deleteAccountConfirmTitle => 'Delete Account';
  @override
  String get confirmDeletionTitle => 'Confirm Deletion';
  @override
  String get deleteDefinitely => 'Delete Permanently';
  @override
  String get deleteConfirmHint => 'Type DELETE';
  @override
  String get deleteReasonHint => 'Reason for deletion (optional)';
  @override
  String get typeDeleteToConfirmError => 'Type "DELETE" to confirm';
  @override
  String get accountPermanentlyDeleted =>
      'Account permanently deleted. Thank you for using Finora.';
  @override
  String get editProfileComingSoon => 'Profile editing: coming soon';
  @override
  String get noConsentChanges => 'No changes recorded in your preferences.';
  @override
  String get privacyPolicyTitle => 'Privacy Policy';
  @override
  String get acceptedStatus => 'Accepted';
  @override
  String get rejectedStatus => 'Rejected';
  @override
  String get consentHistoryTitle => 'Consent History';
  @override
  String get consentHistoryDesc => 'View your preferences changes';
  @override
  String get dataProcessingInfoTitle => 'Data Processing Information';
  @override
  String get dataProcessingInfoDesc => 'Learn how we process your data';
  @override
  String get rightOfAccess => 'Right of Access';
  @override
  String get rightOfAccessDesc => 'Get a copy of all your data';
  @override
  String get rightOfRectification => 'Right of Rectification';
  @override
  String get rightOfRectificationDesc =>
      'Correct inaccurate data (coming soon)';

  @override
  String get assistantOnlineStatus => 'AI Assistant · Online';
  @override
  String get pinchToZoom => 'Pinch to zoom';
  @override
  String get seeRecommendations => 'View recommendations';
  @override
  String get typeYourQuestion => 'Type your question...';
  @override
  String get assistantConnectionError =>
      "Sorry, I couldn't connect to the assistant. Check your connection and try again.";
  @override
  String get affordabilityYes => 'You can';
  @override
  String get affordabilityNo => 'You cannot';
  @override
  String get affordabilityMaybe => 'With caution';
  @override
  String get availableBalanceLabel => 'Available balance';
  @override
  String get balanceAfterPurchase => 'Balance after purchase';
  @override
  String get monthlySurplusLabel => 'Monthly surplus';
  @override
  String get couldSaveIn => 'Could save in';
  @override
  String get impactOnGoalsLabel => 'Impact on goals:';
  @override
  String get noImpactLabel => 'No impact';
  @override
  String get alternativesLabel => 'Alternatives:';
  @override
  String get predictionsAI => 'AI Predictions';
  @override
  String get subtitleAI => 'Next months expenses and savings recommendations';
  @override
  String get finnAsisstant => 'Assistant Finn';
  @override
  String get subtitleFinn =>
      'How can I help you today?\n'
      'Ask me whatever you want';
  @override
  String get lastTransactions => 'Last transactions';

  @override
  String get selectAccounts => 'Select accounts';
  @override
  String get selectAllAccounts => 'Select all';
  @override
  String get deselectAccounts => 'Deselect';
  @override
  String get selectAtLeastOneAccount => 'Select at least one account';
  @override
  String get linkVerb => 'Link';
  @override
  String get encryptedConnectionLabel => 'Encrypted connection';
  @override
  String get readOnlyLabel => 'Read only';
  @override
  String get psd2CertifiedLabel => 'PSD2 certified';
  @override
  String get connectingBankTitle => 'Connecting bank';
  @override
  String get openingBrowserMsg => 'Opening browser...';
  @override
  String get bankOpeningTitle => 'Opening your bank';
  @override
  String get bankWaitingAuthTitle => 'Waiting for authorization';
  @override
  String get bankAuthCompleteInBrowserMsg =>
      'Complete the authorization in the browser to continue.';
  @override
  String get bankAuthReturnMsg =>
      'Once you authorize in the browser, you will automatically return to Finora.';
  @override
  String get bankInitiatingConnectionMsg => 'Initiating secure connection with';
  @override
  String get technicalSupport => 'Technical support';
  @override
  String get bankRetryConnection => 'Retry connection';
  @override
  String get bankChooseOtherBank => 'Choose another bank';
  @override
  String get bankContactSupport => 'Need help? Contact support';
  @override
  String get bankWhatYouCanDo => 'What you can do';
  @override
  String get newAccountTitle => 'New account';
  @override
  String get accountTypeLabel => 'Account type';
  @override
  String get ibanOptional => 'IBAN (optional)';
  @override
  String get saveAccountBtn => 'Save account';
  @override
  String get addCardTitle => 'Add card';
  @override
  String get selectCsvFile => 'Select CSV file';
  @override
  String get dontCloseAppMsg => "Don't close the app during this process";
  @override
  String get aiAnalysisLabel => 'AI Analysis';
  @override
  String get configureAccountMsg => 'Configure your account to get started';
  @override
  String get cardsLabel => 'Cards';
  @override
  String get noCardsOptional => 'No cards — optional';
  @override
  String get importCsvLabel => 'Import transactions (CSV)';
  @override
  String get creditCardType => 'Credit';
  @override
  String get debitCardType => 'Debit';
  @override
  String get prepaidCardType => 'Prepaid';
  @override
  String get lastFourDigitsOptional => 'Last 4 digits (optional)';
  @override
  String get enterAccountNameError => 'Enter a name';
  @override
  String get csvImportDesc => 'Import your account transaction history.';

  @override
  String get appVersion => 'Version';
  @override
  String get close => 'Close';
  @override
  String get next => 'Next';
  @override
  String get back => 'Back';
  @override
  String get skip => 'Skip';
  @override
  String get done => 'Done';
  @override
  String get add => 'Add';
  @override
  String get name => 'Name';
  @override
  String get type => 'Type';
  @override
  String get optional => 'Optional';
  @override
  String get required => 'Required';
  @override
  String get enabled => 'Enabled';
  @override
  String get disabled => 'Disabled';
  @override
  String get on => 'On';
  @override
  String get off => 'Off';

  @override
  String categoryCreatedMsg(String name) => 'Category "$name" created';
  @override
  String categoryUpdatedMsg(String name) => 'Category "$name" updated';
  @override
  String categoryDeletedMsg(String name) => 'Category "$name" deleted';
  @override
  String goalCreatedMsg(String name) => 'Goal "$name" created';
  @override
  String budgetCreatedMsg(String name) => 'Budget "$name" created';
  @override
  String budgetUpdatedMsg(String name) => 'Budget "$name" updated';
  @override
  String budgetDeletedMsg(String name) => 'Budget "$name" deleted';
  @override
  String accountDeletedMsg(String name) => 'Account "$name" deleted';
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
