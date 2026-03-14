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

  // ── Biometría ──────────────────────────────────────────────────────────────
  String biometricEnabledStatus(String label);
  String biometricDisabledStatus(String label);
  String get biometricNotAvailable;
  String get notAvailable;
  String get biometricFaceId;
  String get biometricFingerprint;
  String get biometricGeneric;

  // ── Transacciones ──────────────────────────────────────────────────────────
  String get hisorySuggestions;
  String get newTransaction;
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
  String get firstTransaction;
  String get registerFirst;

  // ── Asistente Finn ─────────────────────────────────────────────────────────
  String get finnWelcomeMessage;
  String get suggestionSpentMonth;
  String get suggestionTopCategory;
  String get suggestionGoalsProgress;
  String get suggestionAffordabilityExample;
  String get suggestionSavingTips;
  String get suggestionCurrentBalance;

  // Keywords para lógica (no se muestran, pero cambian por idioma)
  List<String> get affordabilityKeywords;

  // Recomendaciones proactivas
  String get aiRecsHeader;
  String get aiRecsBalanced;
  String aiFinancialScore(int score);
  String aiPotentialSavingMonthly(String amount);
  String monthCountLabel(int count);

  String get budgetsTitle;
  String get budgetStatusTab;
  String get myBudgetsTab;
  String get editBudgetTitle;
  String get newBudgetTitle;
  String get monthlyLimitLabel;
  String get invalidAmountError;
  String get budgetSavedMsg;
  String get deleteBudgetTitle;
  String deleteBudgetConfirm(String category);
  String get noBudgetsConfigured;
  String get createFirstBudgetInfo;
  String get budgetExceededLabel;
  String get budget80ReachedLabel;
  String get remainingLabel;
  String get unbudgetedTitle;
  String get addLimitLabel;
  String activeAlertsMsg(int count);
  String get spentOfLabel; // "spent of" o "de"

  // ── Estadísticas ───────────────────────────────────────────────────────────
  String get spendingByCategory;
  String get monthlyComparative;
  String get topMonthlyExpenses;
  String get nextExpenses;
  String get temporalEvolution;
  String get period;
  String get reset;
  String get expenseProgress;
  String get ofIncome;
  String get yesterday;
  String get objectiveLoadFailure;
  String get ofText;
  String get today;
  String get tomorrow;
  String get inDays;
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
  String get user;

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
  String get refreshPredictions;
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

  // ── 2FA Setup ──────────────────────────────────────────────────────────────
  String get twoFaProtectionInfo;
  String get twoFaActivatePrompt;
  String get twoFaIncorrectCode;
  String get twoFaEnterPasswordDisable;
  String get incorrectPassword;
  String get howDoesItWork;
  String get installAuthApp;
  String get sessionRequirement2fa;
  String get openAuthAppPrompt;
  String get manualKeyPrompt;
  String get active2faInfo;
  String get currentPassword;
  String get saveCodesWarning;

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
  String get salary;

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

  // ── Reset Password ─────────────────────────────────────────────────────────
  String get resetPasswordTitle;
  String get resetPasswordSubtitle;
  String get newPasswordLabel;
  String get confirmPasswordLabel;
  String get confirmPasswordRequired;
  String get resetPasswordButton;
  String get successTitle;
  String get passwordRequirementsHeader;

  // ── Contenido Legal: Términos y Condiciones ────────────────────────────────
  String get termsSection1Title;
  String get termsSection1Body;
  String get termsSection2Title;
  String get termsSection2Body;
  String get termsSection3Title;
  String get termsSection3Body;
  String get termsSection4Title;
  String get termsSection4Body;
  String get termsSection5Title;
  String get termsSection5Body;
  String get termsSection6Title;
  String get termsSection6Body;
  String get termsSection7Title;
  String get termsSection7Body;

  // ── Contenido Legal: Privacidad ────────────────────────────────────────────
  String get privacyPolicyContact;
  String get gdprComplianceFull;

  // ── Registro ───────────────────────────────────────────────────────────────
  String get fullName;
  String get nameRequired;
  String get nameHint;
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
  // goals_page
  String goalInProgress(int n);
  String goalCompletedCount(int n);
  String goalAmountOf(String current, String target);
  String goalDeadlineDate(String date);
  String goalRemainingAmount(String amount);
  // create_goal_page
  String get goalNameRequired;
  String get goalTargetAmountLabel;
  String get goalAmountRequired;
  String get goalAmountPositive;
  String get goalIconLabel;
  String get goalDeadlineOptional;
  String get goalNoDeadline;
  String get goalCategoryOptional;
  String get goalSelectCategory;
  String get goalNoteOptional;
  String get goalNoteHint;
  String get goalAiHint;
  String get goalAnalyzeAndCreate;
  String get goalFeasibleLabel;
  String get goalDifficultLabel;
  String get goalNotViableLabel;
  String goalMonthlySuggested(String amount);
  List<String> get goalCategoriesList;
  // goal_detail_page
  String get cancelGoal;
  String get contributionAdded;
  String get contributions;
  String get labelSaved;
  String get labelProjection;
  String get contributionLabel;
  String get cashAccountName;
  String get noLinkedBankAccount;
  String get enterAmount;
  String get enterPositiveAmount;
  String get originAccount;
  String get analyzingLabel;
  String get analyzeWithAI;
  String get confirmContribution;
  String get noContributionsYet;
  String get deleteContributionTitle;
  String get no;
  String get cancelGoalTitle;
  String cancelGoalContent(String name);
  String get cancelGoalConfirm;

  // ── Transacciones — adicional ──────────────────────────────────────────────
  String get transactionType;
  String get selectCategory;
  String get selectACategory;
  String get note;
  String get noteHint;
  String get recentTransactions;

  // ── Privacidad / GDPR ─────────────────────────────────────────────────────
  String get privacyPolicy;
  String get termsOfService;
  String get dataConsent;
  String get deleteAccount;
  String get deleteAllData;
  String get downloadData;

  // ── Registro (RF-01) ───────────────────────────────────────────────────────
  String get registerTitle;
  String get registerSubtitle;
  String get nameTooShort;
  String get passwordTooShort;
  String get passwordUppercase;
  String get passwordNumber;
  String get passwordSpecial;
  String get passwordsDontMatch;
  String get acceptTermsPrivacyError;
  String get registerSuccessTitle;
  String get verificationEmailSent;
  String get checkInboxVerify;
  String get verificationWarning;
  String get goToLogin;
  String get fullNameLabel;
  String get fullNameHint;
  String get passwordStrengthVeryWeak;
  String get passwordStrengthWeak;
  String get passwordStrengthMedium;
  String get passwordStrengthStrong;
  String get reqChars;
  String get reqUpper;
  String get reqNumber;
  String get reqSpecial;
  String get acceptTermsPart1;
  String get termsAndConditions;
  String get acceptPrivacyPart1;
  String get loginLink;
  String get requiredBadge;
  String get consentManagementTitle;
  String get consentDescription;
  String get essentialDataTitle;
  String get essentialDataDesc;
  String get dataProcessingTitle;
  String get dataProcessingDesc;
  String get analyticsTitle;
  String get analyticsDesc;
  String get marketingTitle;
  String get marketingDesc;
  String get thirdPartyTitle;
  String get thirdPartyDesc;
  String get personalizationTitle;
  String get personalizationDesc;
  String get policySummaryTitle;
  String get gdprComplianceText;
  String get lastUpdateText;
  String get acceptTermsButton;
  String get acceptPrivacyButton;

  // ── Forgot Password ────────────────────────────────────────────────────────
  String get forgotPasswordTitle;
  String get forgotPasswordSubtitle;
  String get emailLabel;
  String get invalidEmail;
  String get sendLink;
  String get backToLogin;
  String get emailSentTitle;
  String get emailSentInstructions;

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
  String get gdprComplianceDesc;
  String get exportDataDesc;
  String get exportDataIncludesLabel;
  String get exportDataItem1;
  String get exportDataItem2;
  String get exportDataItem3;
  String get exportDataItem4;
  String get exportResultNote;
  String get nameLabel;
  String get transactionsLabel;
  String get registrationDateLabel;
  String get errorExportingData;
  String get errorDeletingAccount;
  String get deleteAccountWarningTitle;
  String get deleteAccountWarningItems;
  String get deleteAccountGdprNote;
  String get deleteConfirmInstruction;
  String get reasonOptionalHint;
  String get consentTypeEssential;
  String get consentTypeAnalytics;
  String get consentTypeMarketing;
  String get consentTypeThirdParty;
  String get consentTypePersonalization;
  String get consentTypeDataProcessing;
  String get actionInitialRegistration;
  String get actionConsentUpdated;
  String get actionConsentWithdrawn;

  // ── Dinero y Cuentas ───────────────────────────────────────────────────────
  String get cashMoney;
  String get howMuchCash;
  String get cashSetupInfo;
  String get transactionBalance;
  String get realData;
  String get bankAccounts;
  String get availableBalance;
  String get ibanLabel;
  String get synchronized;

  // ── Errores y Estados de Banco ─────────────────────────────────────────────
  String get connectionError;
  String get disconnectedAccessRevoked;
  String get accountDisconnectedAccessRevoked;
  String get accountsErrorPrefix;
  String psd2ExpiryMsg(int days);
  String get syncCompleteNoNews;
  String get bankSessionExpired;
  String get bankSessionExpiredMsg;
  String get bankReconnectInfo;
  String get notNow;
  String get reconnect;

  String get securityTitle;
  String get changePasswordHeading;
  String get passwordRequirementsInfo;
  String get currentPasswordLabel;
  String get enterCurrentPasswordError;
  String get minCharactersError;
  String get confirmNewPasswordLabel;
  String get passwordsDoNotMatchError;
  String get passwordUpdatedMsg;
  String get incorrectCurrentPasswordMsg;
  String get changePasswordErrorMsg;
  String get updatePasswordButton;

  String get editProfileTitle;
  String get publicInfoHeading;
  String get nameRequiredError;
  String get profileUpdatedMsg;
  String get profileUpdateErrorMsg;

  // ── Splash Screen ──────────────────────────────────────────────────────────
  String get splashSubtitle;

  // ── Exportación ────────────────────────────────────────────────────────────
  String get exportDataTitle;
  String get exportCsvTitle;
  String get exportCsvSubtitle;
  String get dateRangeLabel;
  String get fromLabel;
  String get toLabel;
  String get allTypeLabel;
  String get generatingLabel;
  String get exportAndShareCsv;
  String get exportPdfTitle;
  String get exportPdfSubtitle;
  String get periodLabel;
  String get periodMonth;
  String get periodYear;
  String get periodCustom;
  String get yearLabel;
  String get monthLabel;
  String get generateAndSharePdf;
  String get pdfFinancialReport;
  String get pdfGeneratedAt;
  String get pdfExecutiveSummary;
  String get pdfExpensesByCategory;
  String get pdfPeriodTransactions;
  String get pdfFooter;
  String get pdfDescription;
  String get errorExportCsv;
  String get errorGeneratePdf;
  String get exportExcel;
  String get exportExcelSubtitle;
  String get errorExportExcel;

  // Meses
  List<String> get monthNames;

  // ── Notificaciones ─────────────────────────────────────────────────────────
  String get notificationsTitle;
  String get settingsSavedMsg;
  String errorSavingSettingsMsg(String error);
  String get notificationsPermissionInfo;
  String get notificationTypesSection;
  String get newTransactionsTitle;
  String get newTransactionsSubtitle;
  String get budgetAlertsTitle;
  String get budgetAlertsSubtitle;
  String get goalProgressTitle;
  String get goalProgressSubtitle;
  String get filtersSection;
  String get minAmountTitle;
  String get minAmountSubtitle;
  String get noLimitLabel;
  String get quietHoursSection;
  String get quietHoursTitle;
  String get quietHoursSubtitle;
  String get startLabel;
  String get endLabel;
  String toggleStatusSemantics(String title, bool value);

  // ── Bank Selection (RF-10) ────────────────────────────────────────────────
  String accountsFromInstitution(String name);
  String get selectAccountsSubtitle;
  String confirmLinkAccounts(int count);
  String linkingAccounts(String label);
  String accountCountLabel(int count);

  // Mensajes del Overlay de Carga
  String get linkingStep1;
  String get linkingStep2;
  String get linkingStep3;
  String get linkingStep4;
  String get linkingStep5;
  String get linkingStep6;
  String get linkingStep7;
  String get linkingStep8;
  String get linkingStep9;

  // ── Bank Setup ─────────────────────────────────────────────────────────────
  String get newAccountTitle;
  String get accountNameLabel;
  String get accountNameHint;
  String get accountTypeLabel;
  String get accountTypeCurrent;
  String get accountTypeSavings;
  String get accountTypeInvestment;
  String get accountTypeOther;
  String get ibanOptional;
  String get ibanHint;
  String get cardsLabel;
  String get addBtn;
  String get noCardsOptional;
  String get cardTypeDebit;
  String get cardTypeCredit;
  String get cardTypePrepaid;
  String get addCardTitle;
  String get cardNameLabel;
  String get cardNameHint;
  String get lastFourDigitsLabel;
  String get importCsvLabel;
  String get csvImportDesc;
  String get csvFormatHelper;
  String get selectCsvFile;
  String csvMovementsDetected(int count);
  String csvImportResult(int imported, int skipped);
  String get csvReadError;
  String get cardAddError;
  String get csvImportError;
  String get saveAccountBtn;

  // ── Onboarding ─────────────────────────────────────────────────────────────
  String get skipButton;
  String get nextButton;
  String get startNowButton;
  String get skipIntroductionSemantics;

  String get onboardingStep1Title;
  String get onboardingStep1Subtitle;
  String get onboardingStep1Description;

  String get onboardingStep2Title;
  String get onboardingStep2Subtitle;
  String get onboardingStep2Description;

  String get onboardingStep3Title;
  String get onboardingStep3Subtitle;
  String get onboardingStep3Description;

  String get onboardingStep4Title;
  String get onboardingStep4Subtitle;
  String get onboardingStep4Description;

  // ── Transacciones ──────────────────────────────────────────────────────────
  String get transactionsTitle;
  String get searchHint;
  String get resultsCount;
  String get resultCount;
  String get filterAll;
  String get filterExpenses;
  String get filterIncomes;
  String get clearFilters;
  String accountFilterLabel(String name);
  String dateGroupLabel(int day, String month);
  String get advancedFiltersTitle;
  String get selectDate;
  String get paymentMethodLabel;
  String get applyFilters;
  String get noTransactionsYet;
  String get registerFirstTransaction;
  String get noResultsFound;
  String noResultsMatching(String query);
  String get noResultsWithFilters;
  String get transactionDeleted;
  String get undo;
  String get deleteConfirmTitle;
  String get deleteConfirmContent;
  String get pendingSync;
  String get moreItems;

  // Semantics
  String transactionSemantics({
    required bool isExpense,
    required String category,
    required String amount,
    required String? description,
    required String date,
    required bool pending,
  });

  // ── Plurales y Conteo (Dinámicos) ──────────────────────────────────────────
  String newLabel(int count);
  String transactionCountLabel(int count);
  String connectedLabel(int count);

  // ── PSD2 y Conexión ────────────────────────────────────────────────────────
  String get syncPsd2Info;
  String get connectAccount;
  String get noConnectedAccounts;
  String get connectBankForSync;
  String get totalBankBalance;
  String get disconnectBank;
  String get disconnectWarningTitle;
  String get disconnectHistoryKept;
  String get disconnectSyncStop;
  String get disconnectRevokeAccess;

  // ── Gráficos y Tiempos ─────────────────────────────────────────────────────
  String get usageByPaymentMethod;
  String get importingTransactions;
  String get syncingPsd2;
  String get justNow;
  String agoDays(int days);
  String agoMins(int mins);
  String agoHours(int hours);
  String get lastSync;
  String get synchronize;
  String get viewTransactions;
  String get editCards;

  // ── Tarjetas ───────────────────────────────────────────────────────────────
  String get noCardsAdd;
  String get exampleCardName;

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
  String get exampleOfDescription;
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
  String get noLinkedAccounts;
  String get cardBankAccount;
  String get noCardsInAccount;
  String get selectCardOptional;
  String get receiptPhoto;
  String get addReceiptPhoto;
  String get change;
  String get transactionRecorded;
  String get saveTransaction;

  // ── Métodos de Pago ────────────────────────────────────────────────────────
  String get paymentCash;
  String get paymentDebit;
  String get paymentCredit;
  String get paymentPrepaid;
  String get paymentTransfer;
  String get paymentDirectDebit;
  String get paymentCheque;
  String get paymentVoucher;
  String get paymentCrypto;

  // ── IA & Predicciones ──────────────────────────────────────────────────────
  String get aiPredictionsTitle;
  String get tabPrediction;
  String get tabSavings;
  String get tabAnomalies;
  String get tabSubscriptions;

  String get aiEmptyDataTitle;
  String get aiEmptyDataSubtitle;
  String get aiPredictionVsLastMonth;
  String get aiPreviousMonth;
  String aiPredictionSemantics(String category, String amount);
  String get aiTrendIncreasing;
  String get aiTrendDecreasing;
  String get aiTrendStable;
  String get aiNextMonthPrediction;
  String aiRangeLabel(String min, String max);
  String aiPreviousMonthLabel(String amount);
  String aiHistoryMonths(int count);
  String aiModelsLabel(String models);
  String aiAnalyzedMonths(int count);
  String get aiConfidenceLevel;

  // ── IA & Ahorro ──────────────────────────────────────────────────────────
  String get aiSavingsNoData;
  String get aiSavingsExcellentTitle;
  String get aiSavingsExcellentSubtitle;
  String get aiImprovementAreas;
  String get aiFinancialHealth;
  String get aiAvgIncome;
  String get aiAvgExpense;
  String get aiSavingsCapacity;
  String get aiSavingsPotential;
  String get aiCurrent;
  String get aiSuggested;

  // ── IA & Anomalías ─────────────────────────────────────────────────────────
  String get aiNoAnomaliesTitle;
  String get aiNoAnomaliesSubtitle;
  String get aiUnusualExpensesDetected;
  String get aiAnomaliesSummary;
  String get aiHighSeverity;
  String get aiAnalyzedCategories;
  String get aiAnomalyExplanation;
  String aiNormalAverage(String amount);

  // ── IA & Suscripciones ─────────────────────────────────────────────────────
  String get aiNoSubscriptionsTitle;
  String get aiNoSubscriptionsSubtitle;
  String get aiRecurringExpensesDetected;
  String aiAnnualCost(String amount);
  String aiDetectedCount(int count);
  String get aiUpcomingCharges;
  String get aiActiveSubscriptions;
  String aiOccurrences(int count);
  String get aiNextCharge;

  String get aiPeriodWeekly;
  String get aiPeriodMonthly;
  String get aiPeriodQuarterly;
  String get aiPeriodAnnual;

  // ── Errores IA ─────────────────────────────────────────────────────────────
  String get aiErrorLoading;
  String get aiServiceUnavailable;
  String get aiCurrentLabel;
  String get aiSuggestedLabel;
  String aiRecommendationSemantics(String category, String message);

  // ── Métodos de Pago ────────────────────────────────────────────────────────
  String get pmDebitCard;
  String get pmCreditCard;
  String get pmPrepaidCard;
  String get pmCard;
  String get pmBankTransfer;
  String get pmTransfer;
  String get pmSepa;
  String get pmWire;
  String get pmDirectDebit;
  String get pmVoucher;
  String get pmCrypto;

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
  String get dontCloseAppMsg;
  // ── Banco — tutorial ──────────────────────────────────────────────────────
  String get tutorialStep1Title;
  String get tutorialStep1Desc;
  String get tutorialStep2Title;
  String get tutorialStep2Desc;
  String get tutorialStep3Title;
  String get tutorialStep3Desc;
  String get tutorialStep4Title;
  String get tutorialStep4Desc;
  String get tutorialStep5Title;
  String get tutorialStep5Desc;
  String get skipTutorial;
  String get tutorialStart;
  // ── Banco — institution selector ──────────────────────────────────────────
  String get chooseBankTitle;
  String get securePsd2Connection;
  String get searchBankHint;
  String get errorLoadingBanks;
  String get noBanksFound;
  // ── Banco — PSD2 consent dialog ────────────────────────────────────────────
  String get tlsEncryptedLabel;
  String get noDataStoredLabel;
  String get bankAccountBalanceLabel;
  String get bankTransactionsLabel;
  String get bankAccountInfoLabel;
  String get authorizeContinue;
  String psd2SecureAccessTo(String bankName);
  String get psd2ConsentLabel;
  String get psd2RequestsAccess;
  String get psd2BalanceDesc;
  String get psd2TransactionsDesc;
  String get psd2AccountInfoDesc;
  String get psd2ConsentNote;
  // ── Banco — consent management ────────────────────────────────────────────
  String get bankConsentsTitle;
  String get bankConsentsLoadError;
  String get renewConsent;
  String renewConsentContent(String bankName);
  String consentRenewedMsg(String bankName);
  String get renew;
  String get revokeConsentTitle;
  String revokeConsentContent(String bankName);
  String consentRevokedMsg(String bankName);
  String get revokeAccess;
  String get statusRevoked;
  String get statusExpired;
  String get statusActive;
  String get renewalRequired;
  String get expiresInLabel;
  String get expiresAtLabel;
  String get grantedPermissionsLabel;
  String get readOnlyAccountsLabel;
  String get revokeLabel;
  String get noActiveConsents;
  String get noActiveConsentsDesc;
  String get psd2RenewalInfoMsg;
  String daysCount(int n);
  String consentExpiresWarning(int days);
  String get consentExpiredWarning;
  String get renew90Days;
  String get errorRenewing;
  String get errorRevoking;
  // ── Banco — connecting errors ─────────────────────────────────────────────
  String get bankFallbackName;
  String get chatOnFinoraLabel;
  String get bankTimeoutTitle;
  List<String> get bankTimeoutSteps;
  String get bankPermissionDeniedTitle;
  List<String> get bankPermissionDeniedSteps;
  String get bankNoInternetTitle;
  List<String> get bankNoInternetSteps;
  String get bankSessionExpiredTitle;
  List<String> get bankSessionExpiredSteps;
  String get bankServiceUnavailTitle;
  List<String> get bankServiceUnavailSteps;
  String get bankSyncFailedTitle;
  List<String> get bankSyncFailedSteps;
  String get bankCancelledTitle;
  List<String> get bankCancelledSteps;
  String get bankMaxAttemptsTitle;
  List<String> get bankMaxAttemptsSteps;
  String get bankUnknownErrorTitle;
  List<String> get bankUnknownErrorSteps;
  String get bankSupportContactMsg;
  String get aiAnalysisLabel;
  String get configureAccountMsg;
  String get creditCardType;
  String get debitCardType;
  String get prepaidCardType;
  String get lastFourDigitsOptional;
  String get enterAccountNameError;

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

  // ── Categorías — página ───────────────────────────────────────────────────
  String get categoriesTitle;
  String get noCategoriesExpense;
  String get noCategoriesIncome;
  String get createFirstCategory;
  String get errorLoadingCategories;
  String get predefined;
  String get newCategory;
  String get editCategory;
  String get deleteCategory;
  String get createCategory;
  String get saveChanges;
  String get icon;
  String get color;
  String deleteCategoryConfirm(String name);
  String get deleteCategoryWarning;
  String get nameTooLong;

  // ── Mensajes dinámicos (con parámetro) ────────────────────────────────────
  String categoryCreatedMsg(String name);
  String categoryUpdatedMsg(String name);
  String categoryDeletedMsg(String name);
  String get categoryDeleted;

  // ── Edit Transaction Page ─────────────────────────────────────────────────
  String get amountInvalidPositive;
  String get amountExceedsMax;
  String get ticketPhoto;
  String get camera;
  String get takePictureNow;
  String get gallery;
  String get selectFromGallery;
  String get deletePhoto;
  String get noChangesMsg;
  String get confirmChanges;
  String get confirmSaveChangesQuestion;
  String get modified;
  String get balanceRecalculateNote;
  String get selectCategoryHint;
  String recategorizeSimilarMsg(String category);
  String get recategorizeAll;
  String lastModified(String date);
  String get suggestedByHistory;
  String get descriptionHint;
  String get addTicketPhoto;
  String get transactionUpdated;
  String get deleteTransactionConfirmContent;
  String get permanentActionWarning;

  String goalCreatedMsg(String name);
  String budgetCreatedMsg(String name);
  String budgetUpdatedMsg(String name);
  String budgetDeletedMsg(String name);
  String accountDeletedMsg(String name);

  // ── Editar Perfil — campos adicionales ────────────────────────────────────
  String get phoneNumber;
  String get profileBio;
  String get languageAndCurrency;
  String get preferencesSectionTitle;

  // ── Biometría — mensajes de snackbar ──────────────────────────────────────
  String biometricActivatedMsg(String label);
  String get biometricCancelledMsg;
  String get biometricDeactivatedMsg;
  String biometricSetupDeviceMsg(String label);
  String get biometricErrorMsg;

  // ── Moneda — mensajes ─────────────────────────────────────────────────────
  String currencyChangedMsg(String code, String symbol);

  // ── Predictions intro cards ───────────────────────────────────────────────
  String get predictionIntroTitle;
  String get predictionIntroDesc;
  String get savingsIntroTitle;
  String get savingsIntroDesc;
  String get anomaliesIntroTitle;
  String get anomaliesIntroDesc;
  String get subscriptionsIntroTitle;
  String get subscriptionsIntroDesc;

  // ── Gemini ────────────────────────────────────────────────────────────────
  String get geminiKeyTitle;
  String get geminiKeyDescription;
  String get geminiKeyConfigured;
  String get geminiKeyRemoved;
  String get configureGeminiKey;
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
  String biometricEnabledStatus(String label) =>
      '$label activado — toca para desactivar';
  @override
  String biometricDisabledStatus(String label) =>
      'Activa el acceso rápido con $label';
  @override
  String get biometricNotAvailable => 'No disponible en este dispositivo';
  @override
  String get notAvailable => 'No disponible';
  @override
  String get biometricFaceId => 'Face ID';
  @override
  String get biometricFingerprint => 'Huella Digital';
  @override
  String get biometricGeneric => 'Biometría';

  @override
  String get hisorySuggestions => 'Sugeridas por historial';
  @override
  String get newTransaction => 'Nueva transacción';
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
  String get firstTransaction =>
      'Registra tu primera transacción para ver tu balance';
  @override
  String get registerFirst => 'Pulsa + para registrar tu primera transacción';

  @override
  String get finnWelcomeMessage =>
      '¡Hola! Soy **Finn**, tu asistente financiero de Finora.\n\n'
      'Puedo ayudarte a entender tus finanzas, analizar tus gastos '
      'y responder preguntas como *"¿cuánto gasté este mes?"* o '
      '*"¿puedo permitirme un viaje de 500€?"*.\n\n'
      '¿En qué puedo ayudarte hoy?';

  @override
  String get suggestionSpentMonth => '¿Cuánto gasté este mes?';
  @override
  String get suggestionTopCategory => '¿En qué categoría gasto más?';
  @override
  String get suggestionGoalsProgress => '¿Cómo van mis objetivos de ahorro?';
  @override
  String get suggestionAffordabilityExample =>
      '¿Puedo comprar un portátil de 800€?';
  @override
  String get suggestionSavingTips => 'Dame consejos para ahorrar';
  @override
  String get suggestionCurrentBalance => '¿Cuál es mi saldo actual?';

  @override
  List<String> get affordabilityKeywords => [
    'puedo comprar',
    'puedo permitir',
    'me puedo',
    'puedo pagar',
    'puedo darme',
    'puedo costear',
    'tengo para',
    'me alcanza',
  ];

  @override
  String get aiRecsHeader =>
      'Aquí tienes tus recomendaciones de optimización financiera:';
  @override
  String get aiRecsBalanced =>
      '\n✅ ¡Tus finanzas están bien equilibradas! No tengo recomendaciones urgentes.';
  @override
  String aiFinancialScore(int score) =>
      '\n📊 **Puntuación financiera: $score/100**';
  @override
  String aiPotentialSavingMonthly(String amount) =>
      '💰 Ahorro potencial: $amount/mes\n';
  @override
  String monthCountLabel(int count) => count == 1 ? 'mes' : 'meses';

  @override
  String get budgetsTitle => 'Presupuestos';
  @override
  String get budgetStatusTab => 'Estado actual';
  @override
  String get myBudgetsTab => 'Mis presupuestos';
  @override
  String get editBudgetTitle => 'Editar presupuesto';
  @override
  String get newBudgetTitle => 'Nuevo presupuesto';
  @override
  String get monthlyLimitLabel => 'Límite mensual (€)';
  @override
  String get invalidAmountError => 'Introduce un importe válido';
  @override
  String get budgetSavedMsg => 'Presupuesto guardado';
  @override
  String get deleteBudgetTitle => 'Eliminar presupuesto';
  @override
  String deleteBudgetConfirm(String category) =>
      '¿Eliminar el presupuesto de "$category"?';
  @override
  String get noBudgetsConfigured => 'Sin presupuestos configurados';
  @override
  String get createFirstBudgetInfo =>
      'Crea tu primer presupuesto para hacer seguimiento';
  @override
  String get budgetExceededLabel => 'Superado';
  @override
  String get budget80ReachedLabel => '80% alcanzado';
  @override
  String get remainingLabel => 'Restante';
  @override
  String get unbudgetedTitle => 'Sin presupuesto';
  @override
  String get addLimitLabel => 'Añadir límite';
  @override
  String activeAlertsMsg(int count) =>
      '$count presupuesto${count > 1 ? 's' : ''} con alerta activa';
  @override
  String get spentOfLabel => 'de';

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
  String get reset => 'Restablecer';
  @override
  String get expenseProgress => 'Progreso de gasto';
  @override
  String get ofIncome => 'de ingresos';
  @override
  String get yesterday => 'Ayer';
  @override
  String get objectiveLoadFailure => 'No se pudieron cargar los objetivos';
  @override
  String get ofText => 'de';
  @override
  String get today => 'Hoy';
  @override
  String get tomorrow => 'Mañana';
  @override
  String get inDays => 'En';
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
  String get user => 'Usuario';

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
  String get refreshPredictions => 'Actualizar predicciones';
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
  String get twoFaProtectionInfo =>
      'Tu cuenta está protegida con autenticación en dos pasos';
  @override
  String get twoFaActivatePrompt =>
      'Activa el 2FA para mayor seguridad en tu cuenta';
  @override
  String get twoFaIncorrectCode =>
      'Código incorrecto. Verifica que la hora de tu dispositivo sea correcta.';
  @override
  String get twoFaEnterPasswordDisable =>
      'Introduce tu contraseña para desactivar el 2FA';
  @override
  String get incorrectPassword => 'Contraseña incorrecta';
  @override
  String get howDoesItWork => '¿Cómo funciona?';
  @override
  String get installAuthApp =>
      'Instala una app autenticadora como Google Authenticator o Authy';
  @override
  String get sessionRequirement2fa =>
      'En cada inicio de sesión se pedirá el código temporal';
  @override
  String get openAuthAppPrompt =>
      'Abre Google Authenticator o Authy y escanea este código:';
  @override
  String get manualKeyPrompt =>
      '¿No puedes escanear el QR? Introduce la clave manual:';
  @override
  String get active2faInfo => '2FA activo. Se pedirá código al iniciar sesión.';
  @override
  String get currentPassword => 'Contraseña actual';
  @override
  String get saveCodesWarning =>
      '¡Guarda estos códigos ahora! Solo se muestran una vez. Úsalos si pierdes acceso a tu autenticador.';

  @override
  String get nutrition => 'Alimentación';
  @override
  String get transport => 'Transporte';
  @override
  String get leisure => 'Ocio';
  @override
  String get salary => 'Salario';
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
  String get resetPasswordTitle => 'Restablecer Contraseña';
  @override
  String get resetPasswordSubtitle =>
      'Ingresa tu nueva contraseña. Asegúrate de que cumple con los requisitos de seguridad.';
  @override
  String get newPasswordLabel => 'Nueva Contraseña';
  @override
  String get confirmPasswordLabel => 'Confirmar Contraseña';
  @override
  String get confirmPasswordRequired => 'Debes confirmar la contraseña';
  @override
  String get resetPasswordButton => 'Restablecer Contraseña';
  @override
  String get successTitle => '¡Éxito!';
  @override
  String get passwordRequirementsHeader => 'Requisitos de contraseña:';

  // ── Contenido Legal: Términos y Condiciones ────────────────────────────────
  @override
  String get termsSection1Title => '1. Aceptación de los Términos';
  @override
  String get termsSection1Body =>
      'Al registrarse y utilizar Finora, usted acepta estos Términos y Condiciones y se compromete a cumplirlos. Si no está de acuerdo, no debe utilizar el servicio.';
  @override
  String get termsSection2Title => '2. Descripción del Servicio';
  @override
  String get termsSection2Body =>
      'Finora es una aplicación de gestión financiera personal que permite registrar transacciones, visualizar estadísticas y gestionar categorías de gastos e ingresos.';
  @override
  String get termsSection3Title => '3. Cuenta de Usuario';
  @override
  String get termsSection3Body =>
      'Usted es responsable de mantener la confidencialidad de su cuenta y contraseña. Debe proporcionar información veraz y actualizada.';
  @override
  String get termsSection4Title => '4. Uso Aceptable';
  @override
  String get termsSection4Body =>
      'El servicio debe usarse solo para fines legales y de gestión financiera personal. Queda prohibido cualquier uso fraudulento o ilegal.';
  @override
  String get termsSection5Title => '5. Protección de Datos';
  @override
  String get termsSection5Body =>
      'Sus datos se tratan conforme al GDPR. Consulte nuestra Política de Privacidad para más información sobre el tratamiento de datos personales.';
  @override
  String get termsSection6Title => '6. Limitación de Responsabilidad';
  @override
  String get termsSection6Body =>
      'Finora no se responsabiliza de decisiones financieras tomadas en base a la información proporcionada por la aplicación. El servicio es orientativo.';
  @override
  String get termsSection7Title => '7. Modificaciones';
  @override
  String get termsSection7Body =>
      'Nos reservamos el derecho de modificar estos términos. Se notificará a los usuarios sobre cambios significativos.';

  // ── Contenido Legal: Privacidad ────────────────────────────────────────────
  @override
  String get privacyPolicyContact => 'Contacto: privacy@finora.app';
  @override
  String get gdprComplianceFull =>
      'Finora cumple con el GDPR de la UE. Tus datos están protegidos y tienes control total sobre ellos. Puedes modificar estos ajustes en cualquier momento desde Ajustes > Privacidad.';

  @override
  String get fullName => 'Nombre completo';
  @override
  String get nameRequired => 'El nombre es requerido';
  @override
  String get nameHint => 'Juan García';
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
  String goalInProgress(int n) => 'En progreso ($n)';
  @override
  String goalCompletedCount(int n) => 'Completados ($n)';
  @override
  String goalAmountOf(String current, String target) => '$current de $target';
  @override
  String goalDeadlineDate(String date) => 'Meta: $date';
  @override
  String goalRemainingAmount(String amount) => 'Faltan $amount';
  @override
  String get goalNameRequired => 'El nombre es obligatorio';
  @override
  String get goalTargetAmountLabel => 'Cantidad objetivo *';
  @override
  String get goalAmountRequired => 'La cantidad es obligatoria';
  @override
  String get goalAmountPositive => 'Introduce una cantidad positiva';
  @override
  String get goalIconLabel => 'Icono';
  @override
  String get goalDeadlineOptional => 'Fecha límite (opcional)';
  @override
  String get goalNoDeadline => 'Sin fecha límite';
  @override
  String get goalCategoryOptional => 'Categoría (opcional)';
  @override
  String get goalSelectCategory => 'Seleccionar categoría';
  @override
  String get goalNoteOptional => 'Nota (opcional)';
  @override
  String get goalNoteHint => '¿Por qué es importante este objetivo?';
  @override
  String get goalAiHint =>
      'La IA analizará tus ingresos y gastos para evaluar '
      'la viabilidad del objetivo y sugerir una aportación mensual.';
  @override
  String get goalAnalyzeAndCreate => 'Analizar y crear objetivo';
  @override
  String get goalFeasibleLabel => '¡Objetivo viable!';
  @override
  String get goalDifficultLabel => 'Objetivo difícil';
  @override
  String get goalNotViableLabel => 'Objetivo muy ambicioso';
  @override
  String goalMonthlySuggested(String amount) =>
      'Aportación mensual sugerida: $amount €';
  @override
  List<String> get goalCategoriesList => [
        'Vivienda',
        'Transporte',
        'Vacaciones',
        'Educación',
        'Emergencia',
        'Salud',
        'Tecnología',
        'Negocio',
        'Otro',
      ];
  @override
  String get cancelGoal => 'Cancelar objetivo';
  @override
  String get contributionAdded => 'Aportación añadida correctamente';
  @override
  String get contributions => 'Aportaciones';
  @override
  String get labelSaved => 'Ahorrado';
  @override
  String get labelProjection => 'Proyección';
  @override
  String get contributionLabel => 'Aportación';
  @override
  String get cashAccountName => 'Efectivo';
  @override
  String get noLinkedBankAccount => 'Sin cuenta bancaria';
  @override
  String get enterAmount => 'Introduce una cantidad';
  @override
  String get enterPositiveAmount => 'Introduce una cantidad positiva';
  @override
  String get originAccount => 'Cuenta de origen';
  @override
  String get analyzingLabel => 'Analizando...';
  @override
  String get analyzeWithAI => 'Analizar con IA';
  @override
  String get confirmContribution => 'Confirmar aportación';
  @override
  String get noContributionsYet =>
      'Todavía no hay aportaciones.\nToca "Añadir aportación" para empezar.';
  @override
  String get deleteContributionTitle => '¿Eliminar aportación?';
  @override
  String get no => 'No';
  @override
  String get cancelGoalTitle => '¿Cancelar objetivo?';
  @override
  String cancelGoalContent(String name) =>
      'Se cancelará el objetivo "$name". El historial de aportaciones se conservará.';
  @override
  String get cancelGoalConfirm => 'Sí, cancelar';

  @override
  String get transactionType => 'Tipo de transacción';
  @override
  String get selectCategory => 'Seleccionar categoría';
  @override
  String get selectACategory => 'Seleccionar categoría';
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
  String get deleteAllData => 'Borrar todos los datos';
  @override
  String get downloadData => 'Descargar mis datos';

  @override
  String get registerTitle => 'Crear cuenta';
  @override
  String get registerSubtitle =>
      'Comienza a gestionar tus finanzas de forma inteligente';
  @override
  String get nameTooShort => 'El nombre debe tener al menos 2 caracteres';
  @override
  String get passwordTooShort => 'Mínimo 8 caracteres';
  @override
  String get passwordUppercase => 'Debe contener al menos una mayúscula';
  @override
  String get passwordNumber => 'Debe contener al menos un número';
  @override
  String get passwordSpecial => 'Debe contener al menos un carácter especial';
  @override
  String get passwordsDontMatch => 'Las contraseñas no coinciden';
  @override
  String get acceptTermsPrivacyError =>
      'Debes aceptar los términos y la política de privacidad';
  @override
  String get registerSuccessTitle => '¡Registro Exitoso!';
  @override
  String get verificationEmailSent =>
      'Te hemos enviado un correo de verificación.';
  @override
  String get checkInboxVerify =>
      'Revisa tu bandeja de entrada y haz clic en el enlace para verificar tu cuenta.';
  @override
  String get verificationWarning =>
      'No podrás iniciar sesión hasta verificar tu email.';
  @override
  String get goToLogin => 'Ir a Iniciar Sesión';
  @override
  String get fullNameLabel => 'Nombre completo';
  @override
  String get fullNameHint => 'Ej: Juan García';
  @override
  String get passwordStrengthVeryWeak => 'Muy débil';
  @override
  String get passwordStrengthWeak => 'Débil';
  @override
  String get passwordStrengthMedium => 'Media';
  @override
  String get passwordStrengthStrong => 'Fuerte';
  @override
  String get reqChars => '8+ caracteres';
  @override
  String get reqUpper => 'Mayúscula';
  @override
  String get reqNumber => 'Número';
  @override
  String get reqSpecial => 'Especial';
  @override
  String get acceptTermsPart1 => 'Acepto los ';
  @override
  String get termsAndConditions => 'Términos y Condiciones';
  @override
  String get acceptPrivacyPart1 => 'He leído y acepto la ';
  @override
  String get loginLink => 'Inicia sesión';
  @override
  String get requiredBadge => 'Requerido';
  @override
  String get consentManagementTitle => 'Gestión de Consentimientos';
  @override
  String get consentDescription =>
      'Selecciona qué tipos de datos deseas permitirnos procesar. Los marcados como "Requerido" son necesarios para usar el servicio.';
  @override
  String get essentialDataTitle => 'Cookies y datos esenciales';
  @override
  String get essentialDataDesc =>
      'Necesarios para el funcionamiento básico de la aplicación.';
  @override
  String get dataProcessingTitle => 'Procesamiento de datos financieros';
  @override
  String get dataProcessingDesc =>
      'Procesar tus transacciones para ofrecerte análisis financiero.';
  @override
  String get analyticsTitle => 'Análisis y mejora del servicio';
  @override
  String get analyticsDesc =>
      'Nos permite analizar cómo usas la app para mejorar la experiencia.';
  @override
  String get marketingTitle => 'Comunicaciones de marketing';
  @override
  String get marketingDesc =>
      'Te enviaremos ofertas, novedades y consejos financieros.';
  @override
  String get thirdPartyTitle => 'Compartir datos con terceros';
  @override
  String get thirdPartyDesc =>
      'Compartir información con socios para productos relevantes.';
  @override
  String get personalizationTitle => 'Personalización del servicio';
  @override
  String get personalizationDesc =>
      'Usar tus datos para personalizar recomendaciones y alertas.';
  @override
  String get policySummaryTitle => 'Resumen de la Política';
  @override
  String get gdprComplianceText =>
      'Finora cumple con el GDPR de la UE. Tus datos están protegidos y tienes control total sobre ellos.';
  @override
  String get lastUpdateText => 'Última actualización: Febrero 2026';
  @override
  String get acceptTermsButton => 'Aceptar Términos';
  @override
  String get acceptPrivacyButton => 'Aceptar Política de Privacidad';

  @override
  String get forgotPasswordTitle => '¿Olvidaste tu contraseña?';
  @override
  String get forgotPasswordSubtitle =>
      'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.';
  @override
  String get emailLabel => 'Correo Electrónico';
  @override
  String get invalidEmail => 'Ingresa un correo electrónico válido';
  @override
  String get sendLink => 'Enviar Enlace';
  @override
  String get backToLogin => 'Volver al inicio de sesión';
  @override
  String get emailSentTitle => 'Email Enviado';
  @override
  String get emailSentInstructions =>
      'Revisa tu bandeja de entrada y haz clic en el enlace para restablecer tu contraseña.';

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
  String get gdprComplianceDesc =>
      'Finora cumple con el Reglamento General de Protección de Datos (GDPR) '
      'de la Unión Europea. Tus datos están protegidos y tienes control total sobre ellos.';
  @override
  String get exportDataDesc =>
      'Se generará un archivo con todos tus datos personales '
      'según el Artículo 20 del GDPR (Derecho de Portabilidad).';
  @override
  String get exportDataIncludesLabel => 'El archivo incluirá:';
  @override
  String get exportDataItem1 => '- Información personal';
  @override
  String get exportDataItem2 => '- Historial de consentimientos';
  @override
  String get exportDataItem3 => '- Transacciones financieras';
  @override
  String get exportDataItem4 => '- Categorías personalizadas';
  @override
  String get exportResultNote =>
      'Los datos completos en formato JSON han sido generados correctamente.';
  @override
  String get nameLabel => 'Nombre';
  @override
  String get transactionsLabel => 'Transacciones';
  @override
  String get registrationDateLabel => 'Registro';
  @override
  String get errorExportingData => 'Error al exportar datos';
  @override
  String get errorDeletingAccount => 'Error al eliminar la cuenta';
  @override
  String get deleteAccountWarningTitle =>
      '¿Estás seguro de que deseas eliminar tu cuenta?';
  @override
  String get deleteAccountWarningItems =>
      'Esta acción es IRREVERSIBLE y eliminará PERMANENTEMENTE:\n'
      '- Toda tu información personal\n'
      '- Historial de transacciones\n'
      '- Categorías personalizadas\n'
      '- Registros de consentimiento';
  @override
  String get deleteAccountGdprNote =>
      'Según el Artículo 17 del GDPR (Derecho al Olvido), '
      'todos tus datos serán eliminados de nuestros servidores.';
  @override
  String get deleteConfirmInstruction =>
      'Para confirmar, escribe "ELIMINAR" en el campo de abajo:';
  @override
  String get reasonOptionalHint => 'No especificada';
  @override
  String get consentTypeEssential => 'Datos esenciales';
  @override
  String get consentTypeAnalytics => 'Análisis';
  @override
  String get consentTypeMarketing => 'Marketing';
  @override
  String get consentTypeThirdParty => 'Terceros';
  @override
  String get consentTypePersonalization => 'Personalización';
  @override
  String get consentTypeDataProcessing => 'Procesamiento datos';
  @override
  String get actionInitialRegistration => 'Registro inicial';
  @override
  String get actionConsentUpdated => 'Actualizado';
  @override
  String get actionConsentWithdrawn => 'Retirado';

  @override
  String get cashMoney => 'Dinero en efectivo';
  @override
  String get howMuchCash => '¿Cuánto efectivo tienes ahora mismo?';
  @override
  String get cashSetupInfo =>
      'A partir de aquí, Finora irá sumando tus ingresos y restando tus gastos en efectivo.';
  @override
  String get transactionBalance => 'Balance de transacciones';
  @override
  String get realData => 'Datos reales';
  @override
  String get bankAccounts => 'Cuentas bancarias';
  @override
  String get availableBalance => 'Saldo disponible';
  @override
  String get ibanLabel => 'IBAN';
  @override
  String get synchronized => 'Sincronizado';

  @override
  String get connectionError => 'Error al conectar';
  @override
  String get disconnectedAccessRevoked => 'desconectada. Acceso revocado';
  @override
  String get accountDisconnectedAccessRevoked =>
      'Cuenta desconectada. Acceso revocado';
  @override
  String get accountsErrorPrefix => 'Error cuentas:';
  @override
  String psd2ExpiryMsg(int days) =>
      'El consentimiento PSD2 expira en $days días. Renuévalo en Ajustes.';
  @override
  String get syncCompleteNoNews => 'Sincronización completada - sin novedades';
  @override
  String get bankSessionExpired => 'Sesión bancaria expirada';
  @override
  String get bankSessionExpiredMsg => 'Tu sesión con el banco ha caducado.';
  @override
  String get bankReconnectInfo =>
      'Reconecta la cuenta para seguir importando transacciones automáticamente';
  @override
  String get notNow => 'Ahora no';
  @override
  String get reconnect => 'Reconectar';

  @override
  String get securityTitle => 'Seguridad';
  @override
  String get changePasswordHeading => 'Cambiar contraseña';
  @override
  String get passwordRequirementsInfo =>
      'Tu nueva contraseña debe tener al menos 8 caracteres e incluir números o símbolos.';
  @override
  String get currentPasswordLabel => 'Contraseña actual';
  @override
  String get enterCurrentPasswordError => 'Introduce tu contraseña actual';
  @override
  String get minCharactersError => 'Mínimo 8 caracteres';
  @override
  String get confirmNewPasswordLabel => 'Confirmar nueva contraseña';
  @override
  String get passwordsDoNotMatchError => 'Las contraseñas no coinciden';
  @override
  String get passwordUpdatedMsg => 'Contraseña actualizada';
  @override
  String get incorrectCurrentPasswordMsg => 'Contraseña actual incorrecta';
  @override
  String get changePasswordErrorMsg => 'Error al cambiar contraseña';
  @override
  String get updatePasswordButton => 'Actualizar contraseña';

  @override
  String get editProfileTitle => 'Editar perfil';
  @override
  String get publicInfoHeading => 'Información pública';
  @override
  String get nameRequiredError => 'El nombre es requerido';
  @override
  String get profileUpdatedMsg => 'Perfil actualizado';
  @override
  String get profileUpdateErrorMsg => 'Error al actualizar el perfil';

  @override
  String get splashSubtitle => 'Tu gestor financiero personal';

  @override
  String get exportDataTitle => 'Exportar datos';
  @override
  String get exportCsvTitle => 'Exportar a CSV';
  @override
  String get exportCsvSubtitle => 'Ideal para Excel u otras hojas de cálculo';
  @override
  String get dateRangeLabel => 'Rango de fechas';
  @override
  String get fromLabel => 'Desde';
  @override
  String get toLabel => 'Hasta';
  @override
  String get allTypeLabel => 'Todos';
  @override
  String get generatingLabel => 'Generando...';
  @override
  String get exportAndShareCsv => 'Exportar y compartir CSV';
  @override
  String get exportPdfTitle => 'Informe PDF';
  @override
  String get exportPdfSubtitle => 'Informe profesional con resumen y tablas';
  @override
  String get periodLabel => 'Período';
  @override
  String get periodMonth => 'Mes';
  @override
  String get periodYear => 'Año';
  @override
  String get periodCustom => 'Personalizado';
  @override
  String get yearLabel => 'Año';
  @override
  String get monthLabel => 'Mes';
  @override
  String get generateAndSharePdf => 'Generar y compartir PDF';
  @override
  String get pdfFinancialReport => 'Informe Financiero';
  @override
  String get pdfGeneratedAt => 'Generado';
  @override
  String get pdfExecutiveSummary => 'Resumen Ejecutivo';
  @override
  String get pdfExpensesByCategory => 'Gastos por Categoría';
  @override
  String get pdfPeriodTransactions => 'Transacciones del Período';
  @override
  String get pdfFooter => 'Finora — Tu gestor financiero personal';
  @override
  String get pdfDescription => 'Descripción';
  @override
  String get errorExportCsv => 'Error al exportar CSV';
  @override
  String get errorGeneratePdf => 'Error al generar PDF';
  @override
  String get exportExcel => 'Exportar Excel (.xlsx)';
  @override
  String get exportExcelSubtitle => 'Informe con gráficas y tablas formateadas';
  @override
  String get errorExportExcel => 'Error al exportar Excel';

  @override
  List<String> get monthNames => [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Sept.',
    'Octubre',
    'Nov.',
    'Dic.',
  ];

  @override
  String get notificationsTitle => 'Notificaciones';
  @override
  String get settingsSavedMsg => 'Configuración guardada';
  @override
  String errorSavingSettingsMsg(String error) => 'Error al guardar: $error';
  @override
  String get notificationsPermissionInfo =>
      'Las notificaciones requieren permisos en tu dispositivo. Asegúrate de haberlos concedido en Ajustes del sistema.';
  @override
  String get notificationTypesSection => 'Tipos de notificación';
  @override
  String get newTransactionsTitle => 'Nuevas transacciones';
  @override
  String get newTransactionsSubtitle =>
      'Notificación al detectar una nueva transacción bancaria';
  @override
  String get budgetAlertsTitle => 'Alertas de presupuesto';
  @override
  String get budgetAlertsSubtitle =>
      'Aviso al superar el 80% y 100% de un presupuesto';
  @override
  String get goalProgressTitle => 'Progreso de objetivos';
  @override
  String get goalProgressSubtitle =>
      'Recordatorio semanal del avance de tus metas de ahorro';
  @override
  String get filtersSection => 'Filtros';
  @override
  String get minAmountTitle => 'Importe mínimo';
  @override
  String get minAmountSubtitle =>
      'No notificar transacciones por debajo de este importe';
  @override
  String get noLimitLabel => 'Sin límite';
  @override
  String get quietHoursSection => 'Horario silencioso';
  @override
  String get quietHoursTitle => 'Horas de silencio';
  @override
  String get quietHoursSubtitle =>
      'No recibir notificaciones durante este horario';
  @override
  String get startLabel => 'Inicio';
  @override
  String get endLabel => 'Fin';
  @override
  String toggleStatusSemantics(String title, bool value) =>
      '$title: ${value ? "activado" : "desactivado"}';

  @override
  String accountsFromInstitution(String name) => 'Cuentas de $name';
  @override
  String get selectAccountsSubtitle =>
      'Elige qué cuentas quieres vincular a Finora. Los saldos se muestran convertidos a EUR.';
  @override
  String confirmLinkAccounts(int count) =>
      'Vincular $count cuenta${count == 1 ? '' : 's'}';
  @override
  String linkingAccounts(String label) => 'Vinculando $label';
  @override
  String accountCountLabel(int count) =>
      '$count cuenta${count == 1 ? '' : 's'}';

  @override
  String get linkingStep1 => 'Conectando con tu banco...';
  @override
  String get linkingStep2 => 'Obteniendo información de tus cuentas...';
  @override
  String get linkingStep3 => 'Generando historial de transacciones...';
  @override
  String get linkingStep4 => 'Analizando tus movimientos con IA...';
  @override
  String get linkingStep5 => 'Categorizando transacciones automáticamente...';
  @override
  String get linkingStep6 => 'Calculando tus patrones de gasto...';
  @override
  String get linkingStep7 => 'Detectando suscripciones recurrentes...';
  @override
  String get linkingStep8 => 'Preparando tu perfil financiero...';
  @override
  String get linkingStep9 => 'Casi listo, un momento más...';

  @override
  String get newAccountTitle => 'Nueva cuenta';
  @override
  String get accountNameLabel => 'Nombre de la cuenta';
  @override
  String get accountNameHint => 'Ej. BBVA Principal';
  @override
  String get accountTypeLabel => 'Tipo de cuenta';
  @override
  String get accountTypeCurrent => 'Cuenta corriente';
  @override
  String get accountTypeSavings => 'Cuenta de ahorro';
  @override
  String get accountTypeInvestment => 'Inversión';
  @override
  String get accountTypeOther => 'Otro';
  @override
  String get ibanOptional => 'IBAN (opcional)';
  @override
  String get ibanHint => 'ES91 2100 0418 4502 0005 1332';
  @override
  String get cardsLabel => 'Tarjetas';
  @override
  String get addBtn => 'Añadir';
  @override
  String get noCardsOptional => 'No hay tarjetas (opcional)';
  @override
  String get cardTypeDebit => 'Débito';
  @override
  String get cardTypeCredit => 'Crédito';
  @override
  String get cardTypePrepaid => 'Prepago';
  @override
  String get addCardTitle => 'Añadir tarjeta';
  @override
  String get cardNameLabel => 'Nombre';
  @override
  String get cardNameHint => 'Ej. Visa BBVA';
  @override
  String get lastFourDigitsLabel => 'Últimos 4 dígitos (opcional)';
  @override
  String get importCsvLabel => 'Importar movimientos (CSV)';
  @override
  String get csvImportDesc =>
      'Si tienes un archivo con movimientos antiguos, puedes subirlo ahora.';
  @override
  String get csvFormatHelper =>
      'Formato: fecha,descripción,importe,tipo (income/expense)';
  @override
  String get selectCsvFile => 'Seleccionar archivo CSV';
  @override
  String csvMovementsDetected(int count) => '$count movimientos detectados';
  @override
  String csvImportResult(int imported, int skipped) =>
      'CSV importado: $imported nuevas, $skipped duplicadas';
  @override
  String get csvReadError => 'Error al leer CSV';
  @override
  String get cardAddError => 'Error al añadir tarjeta';
  @override
  String get csvImportError => 'Error al importar CSV';
  @override
  String get saveAccountBtn => 'Guardar cuenta';

  @override
  String get skipButton => 'Saltar';
  @override
  String get nextButton => 'Siguiente';
  @override
  String get startNowButton => '¡Empezar ahora!';
  @override
  String get skipIntroductionSemantics => 'Saltar introducción';

  @override
  String get onboardingStep1Title => 'Bienvenido a Finora';
  @override
  String get onboardingStep1Subtitle =>
      'Tu gestor financiero personal inteligente';
  @override
  String get onboardingStep1Description =>
      'Controla tus ingresos, gastos y objetivos de ahorro en un solo lugar. Finora te ayuda a tomar mejores decisiones financieras con la ayuda de IA.';

  @override
  String get onboardingStep2Title => 'Registra transacciones fácilmente';
  @override
  String get onboardingStep2Subtitle => 'Manual o conectando tu banco';
  @override
  String get onboardingStep2Description =>
      'Añade gastos e ingresos en segundos. Conecta tu cuenta bancaria para sincronización automática. La IA categoriza cada transacción por ti.';

  @override
  String get onboardingStep3Title => 'Visualiza tus finanzas';
  @override
  String get onboardingStep3Subtitle => 'Gráficos interactivos y predicciones';
  @override
  String get onboardingStep3Description =>
      'Analiza tus gastos por categoría, visualiza tendencias temporales y recibe predicciones de tus gastos del próximo mes con machine learning.';

  @override
  String get onboardingStep4Title => 'Alcanza tus metas';
  @override
  String get onboardingStep4Subtitle =>
      'Objetivos de ahorro con recomendaciones IA';
  @override
  String get onboardingStep4Description =>
      'Crea objetivos de ahorro con fechas límite y visualiza tu progreso. El asistente de IA te da recomendaciones personalizadas para ahorrar más.';

  @override
  String get transactionsTitle => 'Transacciones';
  @override
  String get searchHint => 'Buscar por comercio, descripción o categoría...';
  @override
  String get resultsCount => 'resultados';
  @override
  String get resultCount => 'resultado';
  @override
  String get filterAll => 'Todas';
  @override
  String get filterExpenses => 'Gastos';
  @override
  String get filterIncomes => 'Ingresos';
  @override
  String get clearFilters => 'Limpiar';
  @override
  String accountFilterLabel(String name) => 'Cuenta: $name';
  @override
  String dateGroupLabel(int day, String month) => '$day de $month';
  @override
  String get advancedFiltersTitle => 'Filtros avanzados';
  @override
  String get selectDate => 'Seleccionar';
  @override
  String get paymentMethodLabel => 'Método de pago';
  @override
  String get applyFilters => 'Aplicar filtros';
  @override
  String get noTransactionsYet => 'Sin transacciones aún';
  @override
  String get registerFirstTransaction =>
      'Registra tu primera transacción\npulsando el botón +';
  @override
  String get noResultsFound => 'No hay resultados';
  @override
  String noResultsMatching(String query) =>
      'No se encontraron transacciones\nque coincidan con "$query"';
  @override
  String get noResultsWithFilters =>
      'No se encontraron transacciones\ncon los filtros seleccionados';
  @override
  String get transactionDeleted => 'Transacción eliminada';
  @override
  String get undo => 'Deshacer';
  @override
  String get deleteConfirmTitle => 'Eliminar';
  @override
  String get deleteConfirmContent =>
      '¿Eliminar esta transacción? Esta acción no se puede deshacer.';
  @override
  String get pendingSync => 'Pendiente';
  @override
  String get moreItems => 'más...';

  @override
  String transactionSemantics({
    required bool isExpense,
    required String category,
    required String amount,
    required String? description,
    required String date,
    required bool pending,
  }) =>
      '${isExpense ? 'Gasto' : 'Ingreso'} en $category: ${isExpense ? 'menos' : 'más'} $amount euros. '
      '${description?.isNotEmpty == true ? '$description. ' : ''}$date.'
      '${pending ? ' Pendiente de sincronizar.' : ''}';

  @override
  String newLabel(int count) => count == 1 ? 'nueva' : 'nuevas';
  @override
  String transactionCountLabel(int count) =>
      count == 1 ? 'transacción' : 'transacciones';
  @override
  String connectedLabel(int count) => count == 1 ? 'conectada' : 'conectadas';

  @override
  String get syncPsd2Info =>
      'Sincroniza automáticamente tus cuentas bancarias mediante Open Banking PSD2.';
  @override
  String get connectAccount => 'Conectar cuenta';
  @override
  String get noConnectedAccounts => 'Sin cuentas conectadas';
  @override
  String get connectBankForSync =>
      'Conecta tu banco para sincronizar automáticamente tus movimientos';
  @override
  String get totalBankBalance => 'Balance bancario total';
  @override
  String get disconnectBank => 'Desconectar banco';
  @override
  String get disconnectWarningTitle => '¿Qué ocurre al desconectar?';
  @override
  String get disconnectHistoryKept =>
      'El historial de transacciones se conserva';
  @override
  String get disconnectSyncStop => 'La sincronización automática se detendrá';
  @override
  String get disconnectRevokeAccess =>
      'Se revocan los permisos de acceso al banco';

  @override
  String get usageByPaymentMethod => 'Uso por método de pago';
  @override
  String get importingTransactions => 'Importando transacciones';
  @override
  String get syncingPsd2 =>
      'Sincronizando con tu banco mediante Open Banking PSD2';
  @override
  String get justNow => 'hace un momento';
  @override
  String agoDays(int days) => 'hace $days días';
  @override
  String agoMins(int min) => 'hace $days min.';
  @override
  String agoHours(int hour) => 'hace $days h.';

  @override
  String get lastSync => 'Última sync';
  @override
  String get synchronize => 'Sincronizar';
  @override
  String get viewTransactions => 'Ver transacciones';
  @override
  String get editCards => 'Editar tarjetas';

  @override
  String get noCardsAdd => 'Sin tarjetas - pulsa añadir';
  @override
  String get exampleCardName => 'Ej. Visa BBVA';

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
  String get exampleOfDescription => 'Ej: Compra semanal del supermercado';
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
  String get noLinkedAccounts => 'Sin cuentas bancarias vinculadas';
  @override
  String get cardBankAccount => 'Cuenta bancaria de la tarjeta';
  @override
  String get noCardsInAccount => 'Sin tarjetas en esta cuenta';
  @override
  String get selectCardOptional => 'Seleccionar tarjeta (opcional)';
  @override
  String get receiptPhoto => 'Foto del ticket';
  @override
  String get addReceiptPhoto => 'Añadir foto del ticket';
  @override
  String get change => 'Cambiar';
  @override
  String get transactionRecorded => 'Transacción registrada';
  @override
  String get saveTransaction => 'Guardar transacción';

  @override
  String get paymentCash => 'Efectivo';
  @override
  String get paymentDebit => 'Débito';
  @override
  String get paymentCredit => 'Crédito';
  @override
  String get paymentPrepaid => 'Prepago';
  @override
  String get paymentTransfer => 'Transfer.';
  @override
  String get paymentDirectDebit => 'Recibo';
  @override
  String get paymentCheque => 'Cheque';
  @override
  String get paymentVoucher => 'Vale';
  @override
  String get paymentCrypto => 'Cripto';

  @override
  String get aiPredictionsTitle => 'Predicciones IA';
  @override
  String get tabPrediction => 'Predicción';
  @override
  String get tabSavings => 'Ahorro';
  @override
  String get tabAnomalies => 'Anomalías';
  @override
  String get tabSubscriptions => 'Suscripciones';

  @override
  String get aiEmptyDataTitle => 'Sin datos suficientes';
  @override
  String get aiEmptyDataSubtitle =>
      'Necesitas al menos 2 meses de transacciones para generar predicciones.';
  @override
  String get aiPredictionVsLastMonth => 'Predicción vs mes anterior (top 5)';
  @override
  String get aiPreviousMonth => 'Anterior';
  @override
  String aiPredictionSemantics(String category, String amount) =>
      'Predicción $category: $amount euros';
  @override
  String get aiTrendIncreasing => 'Tendencia al alza';
  @override
  String get aiTrendDecreasing => 'Tendencia a la baja';
  @override
  String get aiTrendStable => 'Tendencia estable';
  @override
  String get aiNextMonthPrediction => 'Predicción próximo mes';
  @override
  String aiRangeLabel(String min, String max) => 'Rango: $min – $max €';
  @override
  String aiPreviousMonthLabel(String amount) => 'Mes anterior: $amount €';
  @override
  String aiHistoryMonths(int count) => '$count meses de historial';
  @override
  String aiModelsLabel(String models) => 'Modelos: $models';
  @override
  String aiAnalyzedMonths(int count) => '$count meses analizados';
  @override
  String get aiConfidenceLevel => 'Nivel de confianza';

  @override
  String get aiSavingsNoData => 'No se pudieron calcular las recomendaciones.';
  @override
  String get aiSavingsExcellentTitle => '¡Excelente!';
  @override
  String get aiSavingsExcellentSubtitle =>
      'Tu distribución de gastos es saludable. No hay áreas de mejora identificadas.';
  @override
  String get aiImprovementAreas => 'Áreas de mejora';
  @override
  String get aiFinancialHealth => 'Salud financiera';
  @override
  String get aiAvgIncome => 'Ingreso prom.';
  @override
  String get aiAvgExpense => 'Gasto prom.';
  @override
  String get aiSavingsCapacity => 'Capacidad ahorro';
  @override
  String get aiSavingsPotential => 'Ahorro potencial';
  @override
  String get aiCurrent => 'Actual';
  @override
  String get aiSuggested => 'Sugerido';

  @override
  String get aiNoAnomaliesTitle => 'Sin anomalías detectadas';
  @override
  String get aiNoAnomaliesSubtitle =>
      'Tus gastos están dentro de los rangos habituales. ¡Excelente control!';
  @override
  String get aiUnusualExpensesDetected => 'Gastos inusuales detectados';
  @override
  String get aiAnomaliesSummary => 'Resumen de anomalías';
  @override
  String get aiHighSeverity => 'Alta severidad';
  @override
  String get aiAnalyzedCategories => 'Categorías analizadas';
  @override
  String get aiAnomalyExplanation =>
      'Los gastos inusuales superan 2 desviaciones estándar respecto a tu media histórica en esa categoría.';
  @override
  String aiNormalAverage(String amount) => 'Media habitual: $amount €';

  @override
  String get aiNoSubscriptionsTitle => 'Sin suscripciones detectadas';
  @override
  String get aiNoSubscriptionsSubtitle =>
      'No se encontraron pagos recurrentes con periodicidad regular en los últimos 6 meses.';
  @override
  String get aiRecurringExpensesDetected => 'Gastos recurrentes detectados';
  @override
  String aiAnnualCost(String amount) => '$amount € al año';
  @override
  String aiDetectedCount(int count) => '$count detectadas';
  @override
  String get aiUpcomingCharges => 'Próximos cargos (7 días)';
  @override
  String get aiActiveSubscriptions => 'Suscripciones activas detectadas';
  @override
  String aiOccurrences(int count) => '${count}x detectado';
  @override
  String get aiNextCharge => 'Próximo cargo';

  @override
  String get aiPeriodWeekly => 'Semanal';
  @override
  String get aiPeriodMonthly => 'Mensual';
  @override
  String get aiPeriodQuarterly => 'Trimestral';
  @override
  String get aiPeriodAnnual => 'Anual';

  @override
  String get aiErrorLoading => 'Error al cargar datos';
  @override
  String get aiServiceUnavailable =>
      'El servicio de IA no está disponible temporalmente.';
  @override
  String get aiCurrentLabel => 'Actual';
  @override
  String get aiSuggestedLabel => 'Sugerido';
  @override
  String aiRecommendationSemantics(String category, String message) =>
      'Recomendación de ahorro en $category: $message';

  @override
  String get pmDebitCard => 'Tarjeta de débito';
  @override
  String get pmCreditCard => 'Tarjeta de crédito';
  @override
  String get pmPrepaidCard => 'Tarjeta prepago';
  @override
  String get pmCard => 'Tarjeta';
  @override
  String get pmBankTransfer => 'Transferencia bancaria';
  @override
  String get pmTransfer => 'Transferencia';
  @override
  String get pmSepa => 'Transferencia SEPA';
  @override
  String get pmWire => 'Transferencia internacional';
  @override
  String get pmDirectDebit => 'Domiciliación/Recibo';
  @override
  String get pmVoucher => 'Cupón/Vale';
  @override
  String get pmCrypto => 'Criptomonedas';

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
  String get dontCloseAppMsg => 'No cierres la aplicación durante este proceso';
  @override
  String get tutorialStep1Title => 'Conecta tu banco de forma segura';
  @override
  String get tutorialStep1Desc =>
      'Finora usa la tecnología Open Banking PSD2 para conectarse a tu banco. '
      'Es la misma tecnología que usan las apps bancarias oficiales.';
  @override
  String get tutorialStep2Title => 'Elige tu banco';
  @override
  String get tutorialStep2Desc =>
      'Busca tu banco entre los disponibles. Soportamos los principales '
      'bancos españoles y europeos. Si no aparece el tuyo, puedes añadirlo manualmente.';
  @override
  String get tutorialStep3Title => 'Autoriza el acceso';
  @override
  String get tutorialStep3Desc =>
      'Serás redirigido a la página segura de tu banco para autorizar el acceso. '
      'Finora NUNCA ve tus credenciales bancarias.';
  @override
  String get tutorialStep4Title => 'Sincronización automática';
  @override
  String get tutorialStep4Desc =>
      'Una vez conectado, Finora sincronizará tus movimientos cada 6-12 horas '
      'automáticamente. También puedes sincronizar manualmente arrastrando hacia abajo.';
  @override
  String get tutorialStep5Title => 'Acceso de solo lectura';
  @override
  String get tutorialStep5Desc =>
      'Finora NUNCA puede hacer transferencias ni modificar tus cuentas. '
      'Solo tiene acceso de lectura a saldos y movimientos.';
  @override
  String get skipTutorial => 'Saltar tutorial';
  @override
  String get tutorialStart => 'Empezar';
  @override
  String get chooseBankTitle => 'Elige tu banco';
  @override
  String get securePsd2Connection => 'Conexión segura PSD2 / Open Banking';
  @override
  String get searchBankHint => 'Buscar banco...';
  @override
  String get errorLoadingBanks => 'Error al cargar bancos';
  @override
  String get noBanksFound => 'No se encontraron bancos';
  @override
  String get tlsEncryptedLabel => 'Cifrado TLS';
  @override
  String get noDataStoredLabel => 'Sin datos guardados';
  @override
  String get bankAccountBalanceLabel => 'Saldo de tus cuentas';
  @override
  String get bankTransactionsLabel => 'Movimientos bancarios';
  @override
  String get bankAccountInfoLabel => 'Información de la cuenta';
  @override
  String get authorizeContinue => 'Autorizar y continuar';
  @override
  String psd2SecureAccessTo(String bankName) => 'Acceso seguro a $bankName';
  @override
  String get psd2ConsentLabel => 'Consentimiento PSD2';
  @override
  String get psd2RequestsAccess => 'Finora solicitará acceso a:';
  @override
  String get psd2BalanceDesc =>
      'Finora lee tu saldo actual para calcular tu balance total. '
      'No puede mover ni modificar fondos.';
  @override
  String get psd2TransactionsDesc =>
      'Se importan los últimos 90 días de transacciones para '
      'categorizar tus gastos automáticamente.';
  @override
  String get psd2AccountInfoDesc =>
      'Nombre del banco, IBAN (enmascarado) y tipo de cuenta '
      'para identificar correctamente cada cuenta.';
  @override
  String get psd2ConsentNote =>
      'Este consentimiento es válido durante 90 días según '
      'la normativa PSD2. Puedes revocarlo en cualquier '
      'momento desde Ajustes → Bancos → Consentimientos.';
  @override
  String get bankConsentsTitle => 'Consentimientos bancarios';
  @override
  String get bankConsentsLoadError =>
      'No se pudieron cargar los consentimientos. Inténtalo de nuevo.';
  @override
  String get renewConsent => 'Renovar consentimiento';
  @override
  String renewConsentContent(String bankName) =>
      'Se renovará el acceso de Finora a $bankName por 90 días más (PSD2).\n\n'
      'No se modificarán tus datos ni transacciones.';
  @override
  String consentRenewedMsg(String bankName) =>
      'Consentimiento de $bankName renovado por 90 días';
  @override
  String get renew => 'Renovar';
  @override
  String get revokeConsentTitle => 'Revocar consentimiento';
  @override
  String revokeConsentContent(String bankName) =>
      '¿Seguro que quieres revocar el acceso de Finora a $bankName?\n\n'
      'Esto desconectará el banco y dejará de sincronizarse. '
      'Tus transacciones existentes se conservarán.';
  @override
  String consentRevokedMsg(String bankName) =>
      'Acceso a $bankName revocado. Banco desconectado.';
  @override
  String get revokeAccess => 'Revocar acceso';
  @override
  String get statusRevoked => 'Revocado';
  @override
  String get statusExpired => 'Expirado';
  @override
  String get statusActive => 'Activo';
  @override
  String get renewalRequired => 'Renovación requerida';
  @override
  String get expiresInLabel => 'Expira en';
  @override
  String get expiresAtLabel => 'Fecha de expiración';
  @override
  String get grantedPermissionsLabel => 'Permisos concedidos';
  @override
  String get readOnlyAccountsLabel => 'Solo lectura (cuentas + transacciones)';
  @override
  String get revokeLabel => 'Revocar';
  @override
  String get noActiveConsents => 'Sin consentimientos activos';
  @override
  String get noActiveConsentsDesc =>
      'Cuando conectes un banco, aquí aparecerá el consentimiento PSD2 '
      'con su estado y fecha de expiración.';
  @override
  String get psd2RenewalInfoMsg =>
      'PSD2 (Directiva de Servicios de Pago) exige renovar el '
      'consentimiento bancario cada 90 días. Finora te avisará '
      'con 14 días de antelación.';
  @override
  String daysCount(int n) => '$n días';
  @override
  String consentExpiresWarning(int days) =>
      'El consentimiento expira en $days días. Renuévalo para seguir sincronizando.';
  @override
  String get consentExpiredWarning =>
      'El consentimiento ha expirado. Renuévalo para reactivar la sincronización.';
  @override
  String get renew90Days => 'Renovar 90 días';
  @override
  String get errorRenewing => 'Error al renovar';
  @override
  String get errorRevoking => 'Error al revocar';
  @override
  String get bankFallbackName => 'Banco';
  @override
  String get chatOnFinoraLabel => 'Chat en la web de Finora';
  @override
  String get bankTimeoutTitle => 'Tiempo de espera agotado';
  @override
  List<String> get bankTimeoutSteps => [
        'La autorización del banco tarda un máximo de 3 minutos.',
        'Asegúrate de tener buena conexión a Internet o usa WiFi.',
        'Completa el proceso en el navegador lo antes posible.',
        'Si el banco pide un código SMS, tenlo preparado antes de empezar.',
      ];
  @override
  String get bankPermissionDeniedTitle => 'Permisos no concedidos';
  @override
  List<String> get bankPermissionDeniedSteps => [
        'Parece que no autorizaste el acceso desde la web de tu banco.',
        'Finora solo necesita permisos de lectura — nunca realizará pagos.',
        'Pulsa "Reintentar" y acepta todos los permisos cuando te los pida tu banco.',
        'Si tienes dudas, consulta la sección PSD2 en la web de tu banco.',
      ];
  @override
  String get bankNoInternetTitle => 'Sin conexión a Internet';
  @override
  List<String> get bankNoInternetSteps => [
        'Comprueba que tu dispositivo tiene conexión a Internet.',
        'Prueba a desactivar y volver a activar el WiFi o los datos móviles.',
        'Desactiva la VPN si tienes una activa.',
        'Si el problema persiste, inténtalo de nuevo más tarde.',
      ];
  @override
  String get bankSessionExpiredTitle => 'Sesión expirada';
  @override
  List<String> get bankSessionExpiredSteps => [
        'Tu sesión en Finora ha expirado por inactividad.',
        'Cierra esta pantalla y vuelve a iniciar sesión en Finora.',
        'Luego podrás conectar tu banco de nuevo.',
      ];
  @override
  String get bankServiceUnavailTitle => 'Servicio no disponible';
  @override
  List<String> get bankServiceUnavailSteps => [
        'El servicio de conexión bancaria está temporalmente no disponible.',
        'Espera unos minutos e inténtalo de nuevo.',
        'Puede ser una interrupción temporal del banco o de Open Banking.',
        'Si el problema persiste más de 1 hora, contacta con soporte.',
      ];
  @override
  String get bankSyncFailedTitle => 'Error al importar cuentas';
  @override
  List<String> get bankSyncFailedSteps => [
        'La autorización fue exitosa pero no se pudieron importar las cuentas.',
        'Tus datos se sincronizarán automáticamente en unos minutos.',
        'También puedes forzar la sincronización desde la pantalla de cuentas.',
        'Si ves las cuentas en tu banco pero no aquí, espera unos minutos.',
      ];
  @override
  String get bankCancelledTitle => 'Conexión cancelada';
  @override
  List<String> get bankCancelledSteps => [
        'Has cancelado el proceso antes de completar la autorización.',
        'Puedes volver a intentarlo cuando quieras.',
        'Si tienes dudas sobre la seguridad, revisa la sección PSD2 antes de continuar.',
      ];
  @override
  String get bankMaxAttemptsTitle => 'Demasiados intentos fallidos';
  @override
  List<String> get bankMaxAttemptsSteps => [
        'Has alcanzado el límite de 3 intentos fallidos para este banco.',
        'Por seguridad, debes esperar 1 hora antes de volver a intentarlo.',
        'Si crees que es un error, contacta con soporte.',
        'Prueba a conectar un banco diferente mientras esperas.',
      ];
  @override
  String get bankUnknownErrorTitle => 'Error al conectar banco';
  @override
  List<String> get bankUnknownErrorSteps => [
        'Se produjo un error inesperado durante la conexión.',
        'Comprueba tu conexión a Internet e inténtalo de nuevo.',
        'Si el error persiste, prueba a reiniciar la app.',
        'Puedes contactar con soporte si el problema continúa.',
      ];
  @override
  String get bankSupportContactMsg => 'Si el problema persiste, puedes contactarnos:';
  @override
  String get aiAnalysisLabel => 'Análisis IA';
  @override
  String get configureAccountMsg => 'Configura tu cuenta para empezar';
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
  String get categoriesTitle => 'Categorías';
  @override
  String get noCategoriesExpense => 'Sin categorías de gastos';
  @override
  String get noCategoriesIncome => 'Sin categorías de ingresos';
  @override
  String get createFirstCategory => 'Crear primera categoría';
  @override
  String get errorLoadingCategories => 'Error al cargar categorías';
  @override
  String get predefined => 'Predefinida';
  @override
  String get newCategory => 'Nueva categoría';
  @override
  String get editCategory => 'Editar categoría';
  @override
  String get deleteCategory => 'Eliminar categoría';
  @override
  String get createCategory => 'Crear categoría';
  @override
  String get saveChanges => 'Guardar cambios';
  @override
  String get icon => 'Icono';
  @override
  String get color => 'Color';
  @override
  String deleteCategoryConfirm(String name) => '¿Eliminar la categoría "$name"?';
  @override
  String get deleteCategoryWarning =>
      'Las transacciones con esta categoría no se eliminarán, pero quedarán sin categoría asignada.';
  @override
  String get nameTooLong => 'El nombre no puede superar 100 caracteres';

  @override
  String categoryCreatedMsg(String name) => 'Categoría "$name" creada';
  @override
  String categoryUpdatedMsg(String name) => 'Categoría "$name" actualizada';
  @override
  String categoryDeletedMsg(String name) => 'Categoría "$name" eliminada';
  @override
  String get categoryDeleted => 'Categoría eliminada';
  @override
  String get amountInvalidPositive => 'Introduce una cantidad válida mayor que 0';
  @override
  String get amountExceedsMax => 'La cantidad no puede exceder €999.999,99';
  @override
  String get ticketPhoto => 'Foto del ticket';
  @override
  String get camera => 'Cámara';
  @override
  String get takePictureNow => 'Hacer una foto ahora';
  @override
  String get gallery => 'Galería';
  @override
  String get selectFromGallery => 'Seleccionar de la galería';
  @override
  String get deletePhoto => 'Eliminar foto';
  @override
  String get noChangesMsg => 'No has realizado ningún cambio';
  @override
  String get confirmChanges => 'Confirmar cambios';
  @override
  String get confirmSaveChangesQuestion => '¿Deseas guardar los siguientes cambios?';
  @override
  String get modified => 'Modificada';
  @override
  String get balanceRecalculateNote =>
      'El balance y las estadísticas se recalcularán automáticamente.';
  @override
  String get selectCategoryHint => '* Selecciona una categoría';
  @override
  String recategorizeSimilarMsg(String category) =>
      '¿Recategorizar todas las transacciones similares a "$category"?';
  @override
  String get recategorizeAll => 'Recategorizar todas';
  @override
  String lastModified(String date) => 'Última modificación: $date';
  @override
  String get suggestedByHistory => 'Sugeridas por historial';
  @override
  String get descriptionHint => 'Ej: Compra semanal del supermercado';
  @override
  String get addTicketPhoto => 'Añadir foto del ticket';
  @override
  String get transactionUpdated => 'Transacción actualizada';
  @override
  String get deleteTransactionConfirmContent =>
      '¿Estás seguro de que deseas eliminar esta transacción?';
  @override
  String get permanentActionWarning =>
      'Esta acción es permanente y no se puede deshacer.';
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

  @override
  String get phoneNumber => 'Número de teléfono';
  @override
  String get profileBio => 'Descripción';
  @override
  String get languageAndCurrency => 'Idioma y moneda';
  @override
  String get preferencesSectionTitle => 'Preferencias';
  @override
  String biometricActivatedMsg(String label) =>
      '$label activado. Próximo inicio de sesión más rápido.';
  @override
  String get biometricCancelledMsg => 'Activación cancelada';
  @override
  String get biometricDeactivatedMsg => 'Inicio de sesión biométrico desactivado';
  @override
  String biometricSetupDeviceMsg(String label) =>
      'Configura $label en los ajustes del dispositivo primero.';
  @override
  String get biometricErrorMsg => 'Error al activar la biometría';
  @override
  String currencyChangedMsg(String code, String symbol) =>
      'Moneda cambiada a $code ($symbol)';

  // ── Predictions intro cards ───────────────────────────────────────────────
  @override
  String get predictionIntroTitle => 'Predicción de gastos';
  @override
  String get predictionIntroDesc =>
      'Análisis basado en tus últimos meses de historial. Te mostramos cuánto gastarás el próximo mes por categoría.';
  @override
  String get savingsIntroTitle => 'Oportunidades de ahorro';
  @override
  String get savingsIntroDesc =>
      'Identifica dónde puedes reducir gastos. Basado en tu patrón de gasto habitual.';
  @override
  String get anomaliesIntroTitle => 'Gastos inusuales detectados';
  @override
  String get anomaliesIntroDesc =>
      'Gastos que se salen de tu patrón normal. Pueden indicar errores o gastos inesperados.';
  @override
  String get subscriptionsIntroTitle => 'Suscripciones activas';
  @override
  String get subscriptionsIntroDesc =>
      'Pagos recurrentes detectados automáticamente. Revisa cuáles necesitas realmente.';

  // ── Gemini ────────────────────────────────────────────────────────────────
  @override
  String get geminiKeyTitle => 'Configurar Gemini API';
  @override
  String get geminiKeyDescription =>
      'Pega tu clave de API de Google Gemini para usar la IA directamente. '
      'Si no tienes clave, el asistente usará el servidor de Finora.';
  @override
  String get geminiKeyConfigured => 'Clave de Gemini configurada ✓';
  @override
  String get geminiKeyRemoved => 'Clave de Gemini eliminada';
  @override
  String get configureGeminiKey => 'Configurar Gemini';
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
  String biometricEnabledStatus(String label) =>
      '$label enabled — tap to disable';
  @override
  String biometricDisabledStatus(String label) =>
      'Enable quick access with $label';
  @override
  String get biometricNotAvailable => 'Not available on this device';
  @override
  String get notAvailable => 'Not available';
  @override
  String get biometricFaceId => 'Face ID';
  @override
  String get biometricFingerprint => 'Fingerprint';
  @override
  String get biometricGeneric => 'Biometrics';

  @override
  String get hisorySuggestions => 'History suggestions';
  @override
  String get newTransaction => 'New transaction';
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
  String get firstTransaction =>
      'Record your first transaction to see your balance';
  @override
  String get registerFirst => 'Press + to record your first transaction';

  @override
  String get finnWelcomeMessage =>
      'Hi! I am **Finn**, your Finora financial assistant.\n\n'
      'I can help you understand your finances, analyze your spending '
      'and answer questions like *"how much did I spend this month?"* or '
      '*"can I afford a 500€ trip?"*.\n\n'
      'How can I help you today?';

  @override
  String get suggestionSpentMonth => 'How much did I spend this month?';
  @override
  String get suggestionTopCategory => 'In which category do I spend most?';
  @override
  String get suggestionGoalsProgress => 'How are my savings goals doing?';
  @override
  String get suggestionAffordabilityExample => 'Can I afford an 800€ laptop?';
  @override
  String get suggestionSavingTips => 'Give me some saving tips';
  @override
  String get suggestionCurrentBalance => 'What is my current balance?';

  @override
  List<String> get affordabilityKeywords => [
    'can i afford',
    'can i buy',
    'can i pay',
    'can i get',
    'do i have enough',
    'is it affordable',
  ];

  @override
  String get aiRecsHeader =>
      'Here are your financial optimization recommendations:';
  @override
  String get aiRecsBalanced =>
      '\n✅ Your finances are well balanced! I have no urgent recommendations.';
  @override
  String aiFinancialScore(int score) => '\n📊 **Financial Score: $score/100**';
  @override
  String aiPotentialSavingMonthly(String amount) =>
      '💰 Potential saving: $amount/month\n';
  @override
  String monthCountLabel(int count) => count == 1 ? 'month' : 'months';

  @override
  String get budgetsTitle => 'Budgets';
  @override
  String get budgetStatusTab => 'Current status';
  @override
  String get myBudgetsTab => 'My budgets';
  @override
  String get editBudgetTitle => 'Edit budget';
  @override
  String get newBudgetTitle => 'New budget';
  @override
  String get monthlyLimitLabel => 'Monthly limit (€)';
  @override
  String get invalidAmountError => 'Enter a valid amount';
  @override
  String get budgetSavedMsg => 'Budget saved';
  @override
  String get deleteBudgetTitle => 'Delete budget';
  @override
  String deleteBudgetConfirm(String category) =>
      'Delete the budget for "$category"?';
  @override
  String get noBudgetsConfigured => 'No budgets configured';
  @override
  String get createFirstBudgetInfo =>
      'Create your first budget to start tracking';
  @override
  String get budgetExceededLabel => 'Exceeded';
  @override
  String get budget80ReachedLabel => '80% reached';
  @override
  String get remainingLabel => 'Remaining';
  @override
  String get unbudgetedTitle => 'No budget';
  @override
  String get addLimitLabel => 'Add limit';
  @override
  String activeAlertsMsg(int count) =>
      '$count budget${count > 1 ? 's' : ''} with active alert';
  @override
  String get spentOfLabel => 'of';

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
  String get reset => 'Reset';
  @override
  String get expenseProgress => 'Expense progress';
  @override
  String get ofIncome => 'of Income';
  @override
  String get yesterday => 'Yesterday';
  @override
  String get objectiveLoadFailure => 'Failed to load objectives';
  @override
  String get ofText => 'of';
  @override
  String get today => 'Today';
  @override
  String get tomorrow => 'Tomorrow';
  @override
  String get inDays => 'In';
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
  String get user => 'User';

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
  String get refreshPredictions => 'Refresh predictions';
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
  String get twoFaProtectionInfo =>
      'Your account is protected with two-step authentication';
  @override
  String get twoFaActivatePrompt =>
      'Activate 2FA for increased account security';
  @override
  String get twoFaIncorrectCode =>
      'Incorrect code. Please verify that your device time is correct.';
  @override
  String get twoFaEnterPasswordDisable => 'Enter your password to disable 2FA';
  @override
  String get incorrectPassword => 'Incorrect password';
  @override
  String get howDoesItWork => 'How does it work?';
  @override
  String get installAuthApp =>
      'Install an authenticator app like Google Authenticator or Authy';
  @override
  String get sessionRequirement2fa =>
      'A temporary code will be requested at every login';
  @override
  String get openAuthAppPrompt =>
      'Open Google Authenticator or Authy and scan this code:';
  @override
  String get manualKeyPrompt => 'Can\'t scan the QR? Enter the manual key:';
  @override
  String get active2faInfo =>
      '2FA active. A code will be requested when logging in.';
  @override
  String get currentPassword => 'Current password';
  @override
  String get saveCodesWarning =>
      'Save these codes now! They are only shown once. Use them if you lose access to your authenticator.';

  @override
  String get nutrition => 'Nutrition';
  @override
  String get transport => 'Transport';
  @override
  String get leisure => 'Leisure';
  @override
  String get salary => 'Salary';
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
  String get resetPasswordTitle => 'Reset Password';
  @override
  String get resetPasswordSubtitle =>
      'Enter your new password. Make sure it meets the security requirements.';
  @override
  String get newPasswordLabel => 'New Password';
  @override
  String get confirmPasswordLabel => 'Confirm Password';
  @override
  String get confirmPasswordRequired => 'You must confirm the password';
  @override
  String get resetPasswordButton => 'Reset Password';
  @override
  String get successTitle => 'Success!';
  @override
  String get passwordRequirementsHeader => 'Password requirements:';

  // ── Contenido Legal: Términos y Condiciones ────────────────────────────────
  @override
  String get termsSection1Title => '1. Acceptance of Terms';
  @override
  String get termsSection1Body =>
      'By registering and using Finora, you accept these Terms and Conditions and agree to comply with them. If you do not agree, you must not use the service.';
  @override
  String get termsSection2Title => '2. Service Description';
  @override
  String get termsSection2Body =>
      'Finora is a personal financial management application that allows you to record transactions, view statistics, and manage expense and income categories.';
  @override
  String get termsSection3Title => '3. User Account';
  @override
  String get termsSection3Body =>
      'You are responsible for maintaining the confidentiality of your account and password. You must provide accurate and up-to-date information.';
  @override
  String get termsSection4Title => '4. Acceptable Use';
  @override
  String get termsSection4Body =>
      'The service must be used only for legal purposes and personal financial management. Any fraudulent or illegal use is prohibited.';
  @override
  String get termsSection5Title => '5. Data Protection';
  @override
  String get termsSection5Body =>
      'Your data is treated in accordance with the GDPR. Please consult our Privacy Policy for more information on the processing of personal data.';
  @override
  String get termsSection6Title => '6. Limitation of Liability';
  @override
  String get termsSection6Body =>
      'Finora is not responsible for financial decisions made based on the information provided by the application. The service is for guidance only.';
  @override
  String get termsSection7Title => '7. Modifications';
  @override
  String get termsSection7Body =>
      'We reserve the right to modify these terms. Users will be notified of significant changes.';

  // ── Contenido Legal: Privacidad ────────────────────────────────────────────
  @override
  String get privacyPolicyContact => 'Contact: privacy@finora.app';
  @override
  String get gdprComplianceFull =>
      'Finora complies with the EU GDPR. Your data is protected and you have full control over it. You can modify these settings at any time from Settings > Privacy.';

  @override
  String get fullName => 'Full name';
  @override
  String get nameRequired => 'Name is required';
  @override
  String get nameHint => 'John Smith';
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
  String goalInProgress(int n) => 'In progress ($n)';
  @override
  String goalCompletedCount(int n) => 'Completed ($n)';
  @override
  String goalAmountOf(String current, String target) => '$current of $target';
  @override
  String goalDeadlineDate(String date) => 'Goal: $date';
  @override
  String goalRemainingAmount(String amount) => '$amount remaining';
  @override
  String get goalNameRequired => 'Name is required';
  @override
  String get goalTargetAmountLabel => 'Target amount *';
  @override
  String get goalAmountRequired => 'Amount is required';
  @override
  String get goalAmountPositive => 'Enter a positive amount';
  @override
  String get goalIconLabel => 'Icon';
  @override
  String get goalDeadlineOptional => 'Deadline (optional)';
  @override
  String get goalNoDeadline => 'No deadline';
  @override
  String get goalCategoryOptional => 'Category (optional)';
  @override
  String get goalSelectCategory => 'Select category';
  @override
  String get goalNoteOptional => 'Note (optional)';
  @override
  String get goalNoteHint => 'Why is this goal important to you?';
  @override
  String get goalAiHint =>
      'AI will analyze your income and expenses to evaluate '
      'goal feasibility and suggest a monthly contribution.';
  @override
  String get goalAnalyzeAndCreate => 'Analyze and create goal';
  @override
  String get goalFeasibleLabel => 'Viable goal!';
  @override
  String get goalDifficultLabel => 'Difficult goal';
  @override
  String get goalNotViableLabel => 'Very ambitious goal';
  @override
  String goalMonthlySuggested(String amount) =>
      'Suggested monthly contribution: $amount';
  @override
  List<String> get goalCategoriesList => [
        'Housing',
        'Transport',
        'Vacation',
        'Education',
        'Emergency',
        'Health',
        'Technology',
        'Business',
        'Other',
      ];
  @override
  String get cancelGoal => 'Cancel goal';
  @override
  String get contributionAdded => 'Contribution added successfully';
  @override
  String get contributions => 'Contributions';
  @override
  String get labelSaved => 'Saved';
  @override
  String get labelProjection => 'Projection';
  @override
  String get contributionLabel => 'Contribution';
  @override
  String get cashAccountName => 'Cash';
  @override
  String get noLinkedBankAccount => 'No linked bank account';
  @override
  String get enterAmount => 'Enter an amount';
  @override
  String get enterPositiveAmount => 'Enter a positive amount';
  @override
  String get originAccount => 'Origin account';
  @override
  String get analyzingLabel => 'Analyzing...';
  @override
  String get analyzeWithAI => 'Analyze with AI';
  @override
  String get confirmContribution => 'Confirm contribution';
  @override
  String get noContributionsYet =>
      'No contributions yet.\nTap "Add contribution" to get started.';
  @override
  String get deleteContributionTitle => 'Delete contribution?';
  @override
  String get no => 'No';
  @override
  String get cancelGoalTitle => 'Cancel goal?';
  @override
  String cancelGoalContent(String name) =>
      'The goal "$name" will be cancelled. Contribution history will be kept.';
  @override
  String get cancelGoalConfirm => 'Yes, cancel';

  @override
  String get transactionType => 'Transaction type';
  @override
  String get selectCategory => 'Select category';
  @override
  String get selectACategory => 'Select a category';
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
  String get deleteAllData => 'Delete all data';
  @override
  String get downloadData => 'Download my data';

  @override
  String get registerTitle => 'Create account';
  @override
  String get registerSubtitle => 'Start managing your finances the smart way';
  @override
  String get nameTooShort => 'Name must be at least 2 characters long';
  @override
  String get passwordTooShort => 'Minimum 8 characters';
  @override
  String get passwordUppercase => 'Must contain at least one uppercase letter';
  @override
  String get passwordNumber => 'Must contain at least one number';
  @override
  String get passwordSpecial => 'Must contain at least one special character';
  @override
  String get passwordsDontMatch => 'Passwords do not match';
  @override
  String get acceptTermsPrivacyError =>
      'You must accept the terms and the privacy policy';
  @override
  String get registerSuccessTitle => 'Registration Successful!';
  @override
  String get verificationEmailSent => 'We have sent you a verification email.';
  @override
  String get checkInboxVerify =>
      'Check your inbox and click the link to verify your account.';
  @override
  String get verificationWarning =>
      'You will not be able to log in until your email is verified.';
  @override
  String get goToLogin => 'Go to Login';
  @override
  String get fullNameLabel => 'Full Name';
  @override
  String get fullNameHint => 'e.g., John Doe';
  @override
  String get passwordStrengthVeryWeak => 'Very weak';
  @override
  String get passwordStrengthWeak => 'Weak';
  @override
  String get passwordStrengthMedium => 'Medium';
  @override
  String get passwordStrengthStrong => 'Strong';
  @override
  String get reqChars => '8+ characters';
  @override
  String get reqUpper => 'Uppercase';
  @override
  String get reqNumber => 'Number';
  @override
  String get reqSpecial => 'Special';
  @override
  String get acceptTermsPart1 => 'I accept the ';
  @override
  String get termsAndConditions => 'Terms and Conditions';
  @override
  String get acceptPrivacyPart1 => 'I have read and accept the ';
  @override
  String get loginLink => 'Sign in';
  @override
  String get requiredBadge => 'Required';
  @override
  String get consentManagementTitle => 'Consent Management';
  @override
  String get consentDescription =>
      'Select which types of data processing you wish to allow. Items marked as "Required" are necessary to use the service.';
  @override
  String get essentialDataTitle => 'Essential cookies and data';
  @override
  String get essentialDataDesc =>
      'Necessary for the basic operation of the application.';
  @override
  String get dataProcessingTitle => 'Financial data processing';
  @override
  String get dataProcessingDesc =>
      'Process your transactions to offer financial analysis.';
  @override
  String get analyticsTitle => 'Analytics and service improvement';
  @override
  String get analyticsDesc =>
      'Allows us to analyze how you use the app to improve the experience.';
  @override
  String get marketingTitle => 'Marketing communications';
  @override
  String get marketingDesc =>
      'We will send you offers, news, and financial tips.';
  @override
  String get thirdPartyTitle => 'Share data with third parties';
  @override
  String get thirdPartyDesc =>
      'Share information with partners for relevant products.';
  @override
  String get personalizationTitle => 'Service personalization';
  @override
  String get personalizationDesc =>
      'Use your data to personalize recommendations and alerts.';
  @override
  String get policySummaryTitle => 'Policy Summary';
  @override
  String get gdprComplianceText =>
      'Finora complies with the EU GDPR. Your data is protected and you have full control over it.';
  @override
  String get lastUpdateText => 'Last updated: February 2026';
  @override
  String get acceptTermsButton => 'Accept Terms';
  @override
  String get acceptPrivacyButton => 'Accept Privacy Policy';

  @override
  String get forgotPasswordTitle => 'Forgot your password?';
  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we will send you a link to reset your password.';
  @override
  String get emailLabel => 'Email Address';
  @override
  String get invalidEmail => 'Enter a valid email';
  @override
  String get sendLink => 'Send Link';
  @override
  String get backToLogin => 'Back to login';
  @override
  String get emailSentTitle => 'Email Sent';
  @override
  String get emailSentInstructions =>
      'Check your inbox and click the link to reset your password.';

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
  String get gdprComplianceDesc =>
      'Finora complies with the General Data Protection Regulation (GDPR) '
      'of the European Union. Your data is protected and you have full control over it.';
  @override
  String get exportDataDesc =>
      'A file will be generated with all your personal data '
      'under Article 20 of the GDPR (Right to Data Portability).';
  @override
  String get exportDataIncludesLabel => 'The file will include:';
  @override
  String get exportDataItem1 => '- Personal information';
  @override
  String get exportDataItem2 => '- Consent history';
  @override
  String get exportDataItem3 => '- Financial transactions';
  @override
  String get exportDataItem4 => '- Custom categories';
  @override
  String get exportResultNote =>
      'The full data in JSON format has been generated successfully.';
  @override
  String get nameLabel => 'Name';
  @override
  String get transactionsLabel => 'Transactions';
  @override
  String get registrationDateLabel => 'Registered';
  @override
  String get errorExportingData => 'Error exporting data';
  @override
  String get errorDeletingAccount => 'Error deleting account';
  @override
  String get deleteAccountWarningTitle =>
      'Are you sure you want to delete your account?';
  @override
  String get deleteAccountWarningItems =>
      'This action is IRREVERSIBLE and will PERMANENTLY delete:\n'
      '- All your personal information\n'
      '- Transaction history\n'
      '- Custom categories\n'
      '- Consent records';
  @override
  String get deleteAccountGdprNote =>
      'Under Article 17 of the GDPR (Right to Erasure), '
      'all your data will be deleted from our servers.';
  @override
  String get deleteConfirmInstruction =>
      'To confirm, type "DELETE" in the field below:';
  @override
  String get reasonOptionalHint => 'Not specified';
  @override
  String get consentTypeEssential => 'Essential data';
  @override
  String get consentTypeAnalytics => 'Analytics';
  @override
  String get consentTypeMarketing => 'Marketing';
  @override
  String get consentTypeThirdParty => 'Third parties';
  @override
  String get consentTypePersonalization => 'Personalisation';
  @override
  String get consentTypeDataProcessing => 'Data processing';
  @override
  String get actionInitialRegistration => 'Initial registration';
  @override
  String get actionConsentUpdated => 'Updated';
  @override
  String get actionConsentWithdrawn => 'Withdrawn';

  @override
  String get cashMoney => 'Cash money';
  @override
  String get howMuchCash => 'How much cash do you have right now?';
  @override
  String get cashSetupInfo =>
      'From here on, Finora will add your income and subtract your cash expenses.';
  @override
  String get transactionBalance => 'Transaction balance';
  @override
  String get realData => 'Real data';
  @override
  String get bankAccounts => 'Bank accounts';
  @override
  String get availableBalance => 'Available balance';
  @override
  String get ibanLabel => 'IBAN';
  @override
  String get synchronized => 'Synchronized';

  @override
  String get connectionError => 'Connection error';
  @override
  String get disconnectedAccessRevoked => 'disconnected. Access revoked';
  @override
  String get accountDisconnectedAccessRevoked =>
      'Account disconnected. Access revoked';
  @override
  String get accountsErrorPrefix => 'Accounts error:';
  @override
  String psd2ExpiryMsg(int days) =>
      'PSD2 consent expires in $days days. Renew it in Settings.';
  @override
  String get syncCompleteNoNews => 'Sync completed - no updates';
  @override
  String get bankSessionExpired => 'Bank session expired';
  @override
  String get bankSessionExpiredMsg => 'Your session with the bank has expired.';
  @override
  String get bankReconnectInfo =>
      'Reconnect the account to continue importing transactions automatically';
  @override
  String get notNow => 'Not now';
  @override
  String get reconnect => 'Reconnect';

  @override
  String get securityTitle => 'Security';
  @override
  String get changePasswordHeading => 'Change password';
  @override
  String get passwordRequirementsInfo =>
      'Your new password must be at least 8 characters long and include numbers or symbols.';
  @override
  String get currentPasswordLabel => 'Current password';
  @override
  String get enterCurrentPasswordError => 'Enter your current password';
  @override
  String get minCharactersError => 'Minimum 8 characters';
  @override
  String get confirmNewPasswordLabel => 'Confirm new password';
  @override
  String get passwordsDoNotMatchError => 'Passwords do not match';
  @override
  String get passwordUpdatedMsg => 'Password updated';
  @override
  String get incorrectCurrentPasswordMsg => 'Incorrect current password';
  @override
  String get changePasswordErrorMsg => 'Error changing password';
  @override
  String get updatePasswordButton => 'Update password';

  @override
  String get editProfileTitle => 'Edit profile';
  @override
  String get publicInfoHeading => 'Public information';
  @override
  String get nameRequiredError => 'Name is required';
  @override
  String get profileUpdatedMsg => 'Profile updated';
  @override
  String get profileUpdateErrorMsg => 'Error updating profile';

  @override
  String get splashSubtitle => 'Your personal financial manager';

  @override
  String get exportDataTitle => 'Export data';
  @override
  String get exportCsvTitle => 'Export to CSV';
  @override
  String get exportCsvSubtitle => 'Ideal for Excel or other spreadsheets';
  @override
  String get dateRangeLabel => 'Date range';
  @override
  String get fromLabel => 'From';
  @override
  String get toLabel => 'To';
  @override
  String get allTypeLabel => 'All';
  @override
  String get generatingLabel => 'Generating...';
  @override
  String get exportAndShareCsv => 'Export and share CSV';
  @override
  String get exportPdfTitle => 'PDF Report';
  @override
  String get exportPdfSubtitle => 'Professional report with summary and tables';
  @override
  String get periodLabel => 'Period';
  @override
  String get periodMonth => 'Month';
  @override
  String get periodYear => 'Year';
  @override
  String get periodCustom => 'Custom';
  @override
  String get yearLabel => 'Year';
  @override
  String get monthLabel => 'Month';
  @override
  String get generateAndSharePdf => 'Generate and share PDF';
  @override
  String get pdfFinancialReport => 'Financial Report';
  @override
  String get pdfGeneratedAt => 'Generated';
  @override
  String get pdfExecutiveSummary => 'Executive Summary';
  @override
  String get pdfExpensesByCategory => 'Expenses by Category';
  @override
  String get pdfPeriodTransactions => 'Period Transactions';
  @override
  String get pdfFooter => 'Finora — Your personal financial manager';
  @override
  String get pdfDescription => 'Description';
  @override
  String get errorExportCsv => 'Error exporting CSV';
  @override
  String get errorGeneratePdf => 'Error generating PDF';
  @override
  String get exportExcel => 'Export Excel (.xlsx)';
  @override
  String get exportExcelSubtitle => 'Report with charts and formatted tables';
  @override
  String get errorExportExcel => 'Error exporting Excel';

  @override
  List<String> get monthNames => [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'Sept.',
    'October',
    'November',
    'December',
  ];

  @override
  String get notificationsTitle => 'Notifications';
  @override
  String get settingsSavedMsg => 'Settings saved';
  @override
  String errorSavingSettingsMsg(String error) => 'Error saving: $error';
  @override
  String get notificationsPermissionInfo =>
      'Notifications require permissions on your device. Make sure you have granted them in System Settings.';
  @override
  String get notificationTypesSection => 'Notification types';
  @override
  String get newTransactionsTitle => 'New transactions';
  @override
  String get newTransactionsSubtitle =>
      'Notification when a new bank transaction is detected';
  @override
  String get budgetAlertsTitle => 'Budget alerts';
  @override
  String get budgetAlertsSubtitle =>
      'Alert when reaching 80% and 100% of a budget';
  @override
  String get goalProgressTitle => 'Goal progress';
  @override
  String get goalProgressSubtitle =>
      'Weekly reminder of your savings goals progress';
  @override
  String get filtersSection => 'Filters';
  @override
  String get minAmountTitle => 'Minimum amount';
  @override
  String get minAmountSubtitle =>
      'Do not notify transactions below this amount';
  @override
  String get noLimitLabel => 'No limit';
  @override
  String get quietHoursSection => 'Quiet hours';
  @override
  String get quietHoursTitle => 'Quiet hours';
  @override
  String get quietHoursSubtitle =>
      'Do not receive notifications during this time';
  @override
  String get startLabel => 'Start';
  @override
  String get endLabel => 'End';
  @override
  String toggleStatusSemantics(String title, bool value) =>
      '$title: ${value ? "enabled" : "disabled"}';

  @override
  String accountsFromInstitution(String name) => '$name Accounts';
  @override
  String get selectAccountsSubtitle =>
      'Choose which accounts you want to link to Finora. Balances are shown converted to EUR.';
  @override
  String confirmLinkAccounts(int count) =>
      'Link $count account${count == 1 ? '' : 's'}';
  @override
  String linkingAccounts(String label) => 'Linking $label';
  @override
  String accountCountLabel(int count) =>
      '$count account${count == 1 ? '' : 's'}';

  @override
  String get linkingStep1 => 'Connecting to your bank...';
  @override
  String get linkingStep2 => 'Fetching account information...';
  @override
  String get linkingStep3 => 'Generating transaction history...';
  @override
  String get linkingStep4 => 'Analyzing your movements with AI...';
  @override
  String get linkingStep5 => 'Automatically categorizing transactions...';
  @override
  String get linkingStep6 => 'Calculating your spending patterns...';
  @override
  String get linkingStep7 => 'Detecting recurring subscriptions...';
  @override
  String get linkingStep8 => 'Preparing your financial profile...';
  @override
  String get linkingStep9 => 'Almost ready, one more moment...';

  @override
  String get newAccountTitle => 'New Account';
  @override
  String get accountNameLabel => 'Account Name';
  @override
  String get accountNameHint => 'e.g., Main Bank Account';
  @override
  String get accountTypeLabel => 'Account Type';
  @override
  String get accountTypeCurrent => 'Current Account';
  @override
  String get accountTypeSavings => 'Savings Account';
  @override
  String get accountTypeInvestment => 'Investment';
  @override
  String get accountTypeOther => 'Other';
  @override
  String get ibanOptional => 'IBAN (optional)';
  @override
  String get ibanHint => 'IBAN format...';
  @override
  String get cardsLabel => 'Cards';
  @override
  String get addBtn => 'Add';
  @override
  String get noCardsOptional => 'No cards (optional)';
  @override
  String get cardTypeDebit => 'Debit';
  @override
  String get cardTypeCredit => 'Credit';
  @override
  String get cardTypePrepaid => 'Prepaid';
  @override
  String get addCardTitle => 'Add Card';
  @override
  String get cardNameLabel => 'Name';
  @override
  String get cardNameHint => 'e.g., BBVA Visa';
  @override
  String get lastFourDigitsLabel => 'Last 4 digits (optional)';
  @override
  String get importCsvLabel => 'Import transactions (CSV)';
  @override
  String get csvImportDesc =>
      'If you have a file with old transactions, you can upload it now.';
  @override
  String get csvFormatHelper =>
      'Format: date,description,amount,type (income/expense)';
  @override
  String get selectCsvFile => 'Select CSV file';
  @override
  String csvMovementsDetected(int count) => '$count transactions detected';
  @override
  String csvImportResult(int imported, int skipped) =>
      'CSV imported: $imported new, $skipped duplicates';
  @override
  String get csvReadError => 'Error reading CSV';
  @override
  String get cardAddError => 'Error adding card';
  @override
  String get csvImportError => 'Error importing CSV';
  @override
  String get saveAccountBtn => 'Save Account';

  @override
  String get skipButton => 'Skip';
  @override
  String get nextButton => 'Next';
  @override
  String get startNowButton => 'Start now!';
  @override
  String get skipIntroductionSemantics => 'Skip introduction';

  @override
  String get onboardingStep1Title => 'Welcome to Finora';
  @override
  String get onboardingStep1Subtitle => 'Your smart personal financial manager';
  @override
  String get onboardingStep1Description =>
      'Track your income, expenses, and savings goals in one place. Finora helps you make better financial decisions with the help of AI.';

  @override
  String get onboardingStep2Title => 'Record transactions easily';
  @override
  String get onboardingStep2Subtitle => 'Manual or by connecting your bank';
  @override
  String get onboardingStep2Description =>
      'Add expenses and income in seconds. Connect your bank account for automatic synchronization. AI categorizes every transaction for you.';

  @override
  String get onboardingStep3Title => 'Visualize your finances';
  @override
  String get onboardingStep3Subtitle => 'Interactive charts and predictions';
  @override
  String get onboardingStep3Description =>
      'Analyze your spending by category, view time trends, and receive predictions of your next month\'s expenses with machine learning.';

  @override
  String get onboardingStep4Title => 'Reach your goals';
  @override
  String get onboardingStep4Subtitle => 'Savings goals with AI recommendations';
  @override
  String get onboardingStep4Description =>
      'Create savings goals with deadlines and visualize your progress. The AI assistant gives you personalized recommendations to save more.';

  @override
  String get transactionsTitle => 'Transactions';
  @override
  String get searchHint => 'Search by merchant, description or category...';
  @override
  String get resultsCount => 'results';
  @override
  String get resultCount => 'result';
  @override
  String get filterAll => 'All';
  @override
  String get filterExpenses => 'Expenses';
  @override
  String get filterIncomes => 'Incomes';
  @override
  String get clearFilters => 'Clear';
  @override
  String accountFilterLabel(String name) => 'Account: $name';
  @override
  String dateGroupLabel(int day, String month) => '$month $day';
  @override
  String get advancedFiltersTitle => 'Advanced filters';
  @override
  String get selectDate => 'Select';
  @override
  String get paymentMethodLabel => 'Payment method';
  @override
  String get applyFilters => 'Apply filters';
  @override
  String get noTransactionsYet => 'No transactions yet';
  @override
  String get registerFirstTransaction =>
      'Register your first transaction\nby pressing the + button';
  @override
  String get noResultsFound => 'No results found';
  @override
  String noResultsMatching(String query) =>
      'No transactions found\nmatching "$query"';
  @override
  String get noResultsWithFilters =>
      'No transactions found\nwith the selected filters';
  @override
  String get transactionDeleted => 'Transaction deleted';
  @override
  String get undo => 'Undo';
  @override
  String get deleteConfirmTitle => 'Delete';
  @override
  String get deleteConfirmContent =>
      'Delete this transaction? This action cannot be undone.';
  @override
  String get pendingSync => 'Pending';
  @override
  String get moreItems => 'more...';

  @override
  String transactionSemantics({
    required bool isExpense,
    required String category,
    required String amount,
    required String? description,
    required String date,
    required bool pending,
  }) =>
      '${isExpense ? 'Expense' : 'Income'} in $category: ${isExpense ? 'minus' : 'plus'} $amount euros. '
      '${description?.isNotEmpty == true ? '$description. ' : ''}$date.'
      '${pending ? ' Pending synchronization.' : ''}';

  @override
  String newLabel(int count) => 'new'; // En inglés 'new' no varía
  @override
  String transactionCountLabel(int count) =>
      count == 1 ? 'transaction' : 'transactions';
  @override
  String connectedLabel(int count) => count == 1 ? 'connected' : 'connected';

  @override
  String get syncPsd2Info =>
      'Automatically sync your bank accounts via PSD2 Open Banking.';
  @override
  String get connectAccount => 'Connect account';
  @override
  String get noConnectedAccounts => 'No connected accounts';
  @override
  String get connectBankForSync =>
      'Connect your bank to automatically sync your movements';
  @override
  String get totalBankBalance => 'Total bank balance';
  @override
  String get disconnectBank => 'Disconnect bank';
  @override
  String get disconnectWarningTitle => 'What happens when you disconnect?';
  @override
  String get disconnectHistoryKept => 'Transaction history is preserved';
  @override
  String get disconnectSyncStop => 'Automatic synchronization will stop';
  @override
  String get disconnectRevokeAccess => 'Bank access permissions are revoked';

  @override
  String get usageByPaymentMethod => 'Usage by payment method';
  @override
  String get importingTransactions => 'Importing transactions';
  @override
  String get syncingPsd2 => 'Syncing with your bank via PSD2 Open Banking';
  @override
  String get justNow => 'just now';
  @override
  String agoDays(int days) => '$days days ago';
  @override
  String agoMins(int min) => '$days min. ago';
  @override
  String agoHours(int hour) => '$days h. ago';
  @override
  String get lastSync => 'Last sync';
  @override
  String get synchronize => 'Synchronize';
  @override
  String get viewTransactions => 'View transactions';
  @override
  String get editCards => 'Edit cards';

  @override
  String get noCardsAdd => 'No cards - tap to add';
  @override
  String get exampleCardName => 'e.g. Visa Chase';

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
  String get exampleOfDescription => 'Ex: Weekly supermarket purchase';
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
  String get noLinkedAccounts => 'No linked bank accounts';
  @override
  String get cardBankAccount => 'Card bank account';
  @override
  String get noCardsInAccount => 'No cards associated with this account';
  @override
  String get selectCardOptional => 'Select card (optional)';
  @override
  String get receiptPhoto => 'Receipt photo';
  @override
  String get addReceiptPhoto => 'Add receipt photo';
  @override
  String get change => 'Change';
  @override
  String get transactionRecorded => 'Transaction recorded';
  @override
  String get saveTransaction => 'Save transaction';

  @override
  String get paymentCash => 'Cash';
  @override
  String get paymentDebit => 'Debit';
  @override
  String get paymentCredit => 'Credit';
  @override
  String get paymentPrepaid => 'Prepaid';
  @override
  String get paymentTransfer => 'Transf.';
  @override
  String get paymentDirectDebit => 'Debit';
  @override
  String get paymentCheque => 'Check';
  @override
  String get paymentVoucher => 'Voucher';
  @override
  String get paymentCrypto => 'Crypto';

  @override
  String get aiPredictionsTitle => 'AI Predictions';
  @override
  String get tabPrediction => 'Prediction';
  @override
  String get tabSavings => 'Savings';
  @override
  String get tabAnomalies => 'Anomalies';
  @override
  String get tabSubscriptions => 'Subscriptions';

  @override
  String get aiEmptyDataTitle => 'Insufficient data';
  @override
  String get aiEmptyDataSubtitle =>
      'You need at least 2 months of transactions to generate predictions.';
  @override
  String get aiPredictionVsLastMonth => 'Prediction vs last month (top 5)';
  @override
  String get aiPreviousMonth => 'Previous';
  @override
  String aiPredictionSemantics(String category, String amount) =>
      'Prediction $category: $amount euros';
  @override
  String get aiTrendIncreasing => 'Upward trend';
  @override
  String get aiTrendDecreasing => 'Downward trend';
  @override
  String get aiTrendStable => 'Stable trend';
  @override
  String get aiNextMonthPrediction => 'Next month prediction';
  @override
  String aiRangeLabel(String min, String max) => 'Range: $min – $max €';
  @override
  String aiPreviousMonthLabel(String amount) => 'Last month: $amount €';
  @override
  String aiHistoryMonths(int count) => '$count months of history';
  @override
  String aiModelsLabel(String models) => 'Models: $models';
  @override
  String aiAnalyzedMonths(int count) => '$count months analyzed';
  @override
  String get aiConfidenceLevel => 'Confidence level';

  @override
  String get aiSavingsNoData => 'Could not calculate recommendations.';
  @override
  String get aiSavingsExcellentTitle => 'Excellent!';
  @override
  String get aiSavingsExcellentSubtitle =>
      'Your spending distribution is healthy. No areas for improvement identified.';
  @override
  String get aiImprovementAreas => 'Areas for improvement';
  @override
  String get aiFinancialHealth => 'Financial health';
  @override
  String get aiAvgIncome => 'Avg Income';
  @override
  String get aiAvgExpense => 'Avg Expense';
  @override
  String get aiSavingsCapacity => 'Savings capacity';
  @override
  String get aiSavingsPotential => 'Potential savings';
  @override
  String get aiCurrent => 'Current';
  @override
  String get aiSuggested => 'Suggested';

  @override
  String get aiNoAnomaliesTitle => 'No anomalies detected';
  @override
  String get aiNoAnomaliesSubtitle =>
      'Your expenses are within usual ranges. Excellent control!';
  @override
  String get aiUnusualExpensesDetected => 'Unusual expenses detected';
  @override
  String get aiAnomaliesSummary => 'Anomalies summary';
  @override
  String get aiHighSeverity => 'High severity';
  @override
  String get aiAnalyzedCategories => 'Categories analyzed';
  @override
  String get aiAnomalyExplanation =>
      'Unusual expenses exceed 2 standard deviations from your historical average in that category.';
  @override
  String aiNormalAverage(String amount) => 'Habitual average: $amount €';

  @override
  String get aiNoSubscriptionsTitle => 'No subscriptions detected';
  @override
  String get aiNoSubscriptionsSubtitle =>
      'No recurring payments with regular periodicity found in the last 6 months.';
  @override
  String get aiRecurringExpensesDetected => 'Recurring expenses detected';
  @override
  String aiAnnualCost(String amount) => '$amount € per year';
  @override
  String aiDetectedCount(int count) => '$count detected';
  @override
  String get aiUpcomingCharges => 'Upcoming charges (7 days)';
  @override
  String get aiActiveSubscriptions => 'Active subscriptions detected';
  @override
  String aiOccurrences(int count) => '${count}x detected';
  @override
  String get aiNextCharge => 'Next charge';

  @override
  String get aiPeriodWeekly => 'Weekly';
  @override
  String get aiPeriodMonthly => 'Monthly';
  @override
  String get aiPeriodQuarterly => 'Quarterly';
  @override
  String get aiPeriodAnnual => 'Annual';

  @override
  String get aiErrorLoading => 'Error loading data';
  @override
  String get aiServiceUnavailable =>
      'The AI service is temporarily unavailable.';
  @override
  String get aiCurrentLabel => 'Current';
  @override
  String get aiSuggestedLabel => 'Suggested';
  @override
  String aiRecommendationSemantics(String category, String message) =>
      'Savings recommendation in $category: $message';

  @override
  String get pmDebitCard => 'Debit Card';
  @override
  String get pmCreditCard => 'Credit Card';
  @override
  String get pmPrepaidCard => 'Prepaid Card';
  @override
  String get pmCard => 'Card';
  @override
  String get pmBankTransfer => 'Bank Transfer';
  @override
  String get pmTransfer => 'Transfer';
  @override
  String get pmSepa => 'SEPA Transfer';
  @override
  String get pmWire => 'Wire Transfer';
  @override
  String get pmDirectDebit => 'Direct Debit';
  @override
  String get pmVoucher => 'Voucher';
  @override
  String get pmCrypto => 'Cryptocurrencies';

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
  String get dontCloseAppMsg => "Don't close the app during this process";
  @override
  String get tutorialStep1Title => 'Connect your bank securely';
  @override
  String get tutorialStep1Desc =>
      'Finora uses Open Banking PSD2 technology to connect to your bank. '
      'It is the same technology used by official banking apps.';
  @override
  String get tutorialStep2Title => 'Choose your bank';
  @override
  String get tutorialStep2Desc =>
      'Search your bank among the available ones. We support the main '
      'Spanish and European banks. If yours is not listed, you can add it manually.';
  @override
  String get tutorialStep3Title => 'Authorize access';
  @override
  String get tutorialStep3Desc =>
      'You will be redirected to your bank\'s secure page to authorize access. '
      'Finora NEVER sees your banking credentials.';
  @override
  String get tutorialStep4Title => 'Automatic sync';
  @override
  String get tutorialStep4Desc =>
      'Once connected, Finora will sync your transactions every 6-12 hours '
      'automatically. You can also sync manually by pulling down.';
  @override
  String get tutorialStep5Title => 'Read-only access';
  @override
  String get tutorialStep5Desc =>
      'Finora can NEVER make transfers or modify your accounts. '
      'It only has read access to balances and transactions.';
  @override
  String get skipTutorial => 'Skip tutorial';
  @override
  String get tutorialStart => 'Start';
  @override
  String get chooseBankTitle => 'Choose your bank';
  @override
  String get securePsd2Connection => 'Secure PSD2 / Open Banking connection';
  @override
  String get searchBankHint => 'Search bank...';
  @override
  String get errorLoadingBanks => 'Error loading banks';
  @override
  String get noBanksFound => 'No banks found';
  @override
  String get tlsEncryptedLabel => 'TLS Encryption';
  @override
  String get noDataStoredLabel => 'No data stored';
  @override
  String get bankAccountBalanceLabel => 'Your account balance';
  @override
  String get bankTransactionsLabel => 'Bank transactions';
  @override
  String get bankAccountInfoLabel => 'Account information';
  @override
  String get authorizeContinue => 'Authorize and continue';
  @override
  String psd2SecureAccessTo(String bankName) => 'Secure access to $bankName';
  @override
  String get psd2ConsentLabel => 'PSD2 Consent';
  @override
  String get psd2RequestsAccess => 'Finora will request access to:';
  @override
  String get psd2BalanceDesc =>
      'Finora reads your current balance to calculate your total net worth. '
      'It cannot move or modify funds.';
  @override
  String get psd2TransactionsDesc =>
      'The last 90 days of transactions are imported to '
      'automatically categorise your expenses.';
  @override
  String get psd2AccountInfoDesc =>
      'Bank name, IBAN (masked) and account type '
      'to correctly identify each account.';
  @override
  String get psd2ConsentNote =>
      'This consent is valid for 90 days under PSD2 regulations. '
      'You can revoke it at any time from '
      'Settings → Banks → Consents.';
  @override
  String get bankConsentsTitle => 'Bank consents';
  @override
  String get bankConsentsLoadError =>
      'Could not load consents. Please try again.';
  @override
  String get renewConsent => 'Renew consent';
  @override
  String renewConsentContent(String bankName) =>
      "Finora's access to $bankName will be renewed for 90 more days (PSD2).\n\n"
      'Your data and transactions will not be modified.';
  @override
  String consentRenewedMsg(String bankName) =>
      '$bankName consent renewed for 90 days';
  @override
  String get renew => 'Renew';
  @override
  String get revokeConsentTitle => 'Revoke consent';
  @override
  String revokeConsentContent(String bankName) =>
      'Are you sure you want to revoke Finora\'s access to $bankName?\n\n'
      'This will disconnect the bank and stop syncing. '
      'Your existing transactions will be kept.';
  @override
  String consentRevokedMsg(String bankName) =>
      'Access to $bankName revoked. Bank disconnected.';
  @override
  String get revokeAccess => 'Revoke access';
  @override
  String get statusRevoked => 'Revoked';
  @override
  String get statusExpired => 'Expired';
  @override
  String get statusActive => 'Active';
  @override
  String get renewalRequired => 'Renewal required';
  @override
  String get expiresInLabel => 'Expires in';
  @override
  String get expiresAtLabel => 'Expiry date';
  @override
  String get grantedPermissionsLabel => 'Granted permissions';
  @override
  String get readOnlyAccountsLabel => 'Read only (accounts + transactions)';
  @override
  String get revokeLabel => 'Revoke';
  @override
  String get noActiveConsents => 'No active consents';
  @override
  String get noActiveConsentsDesc =>
      'When you connect a bank, the PSD2 consent will appear here '
      'with its status and expiry date.';
  @override
  String get psd2RenewalInfoMsg =>
      'PSD2 (Payment Services Directive) requires renewing bank '
      'consent every 90 days. Finora will notify you 14 days in advance.';
  @override
  String daysCount(int n) => '$n days';
  @override
  String consentExpiresWarning(int days) =>
      'Consent expires in $days days. Renew it to keep syncing.';
  @override
  String get consentExpiredWarning =>
      'Consent has expired. Renew it to reactivate synchronisation.';
  @override
  String get renew90Days => 'Renew 90 days';
  @override
  String get errorRenewing => 'Error renewing';
  @override
  String get errorRevoking => 'Error revoking';
  @override
  String get bankFallbackName => 'Bank';
  @override
  String get chatOnFinoraLabel => "Chat on Finora's website";
  @override
  String get bankTimeoutTitle => 'Connection timed out';
  @override
  List<String> get bankTimeoutSteps => [
        'Bank authorization takes a maximum of 3 minutes.',
        'Make sure you have a good internet connection or use WiFi.',
        'Complete the process in the browser as soon as possible.',
        'If your bank asks for an SMS code, have it ready before starting.',
      ];
  @override
  String get bankPermissionDeniedTitle => 'Permissions not granted';
  @override
  List<String> get bankPermissionDeniedSteps => [
        'It seems you did not authorize access from your bank\'s website.',
        'Finora only needs read permissions — it will never make payments.',
        'Tap "Retry" and accept all permissions when your bank requests them.',
        'If in doubt, check the PSD2 section on your bank\'s website.',
      ];
  @override
  String get bankNoInternetTitle => 'No internet connection';
  @override
  List<String> get bankNoInternetSteps => [
        'Check that your device has an internet connection.',
        'Try turning WiFi or mobile data off and on again.',
        'Disable VPN if you have one active.',
        'If the problem persists, try again later.',
      ];
  @override
  String get bankSessionExpiredTitle => 'Session expired';
  @override
  List<String> get bankSessionExpiredSteps => [
        'Your Finora session has expired due to inactivity.',
        'Close this screen and sign in to Finora again.',
        'Then you can connect your bank again.',
      ];
  @override
  String get bankServiceUnavailTitle => 'Service unavailable';
  @override
  List<String> get bankServiceUnavailSteps => [
        'The bank connection service is temporarily unavailable.',
        'Wait a few minutes and try again.',
        'It may be a temporary interruption from the bank or Open Banking.',
        'If the problem persists for more than 1 hour, contact support.',
      ];
  @override
  String get bankSyncFailedTitle => 'Error importing accounts';
  @override
  List<String> get bankSyncFailedSteps => [
        'Authorization was successful but accounts could not be imported.',
        'Your data will sync automatically in a few minutes.',
        'You can also force sync from the accounts screen.',
        'If you see accounts in your bank but not here, wait a few minutes.',
      ];
  @override
  String get bankCancelledTitle => 'Connection cancelled';
  @override
  List<String> get bankCancelledSteps => [
        'You cancelled the process before completing authorization.',
        'You can try again whenever you want.',
        'If you have security concerns, review the PSD2 section before continuing.',
      ];
  @override
  String get bankMaxAttemptsTitle => 'Too many failed attempts';
  @override
  List<String> get bankMaxAttemptsSteps => [
        'You have reached the limit of 3 failed attempts for this bank.',
        'For security, you must wait 1 hour before trying again.',
        'If you think this is an error, contact support.',
        'Try connecting a different bank while you wait.',
      ];
  @override
  String get bankUnknownErrorTitle => 'Error connecting bank';
  @override
  List<String> get bankUnknownErrorSteps => [
        'An unexpected error occurred during the connection.',
        'Check your internet connection and try again.',
        'If the error persists, try restarting the app.',
        'You can contact support if the problem continues.',
      ];
  @override
  String get bankSupportContactMsg => 'If the problem persists, you can contact us:';
  @override
  String get aiAnalysisLabel => 'AI Analysis';
  @override
  String get configureAccountMsg => 'Configure your account to get started';
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
  String get categoriesTitle => 'Categories';
  @override
  String get noCategoriesExpense => 'No expense categories';
  @override
  String get noCategoriesIncome => 'No income categories';
  @override
  String get createFirstCategory => 'Create first category';
  @override
  String get errorLoadingCategories => 'Error loading categories';
  @override
  String get predefined => 'Predefined';
  @override
  String get newCategory => 'New category';
  @override
  String get editCategory => 'Edit category';
  @override
  String get deleteCategory => 'Delete category';
  @override
  String get createCategory => 'Create category';
  @override
  String get saveChanges => 'Save changes';
  @override
  String get icon => 'Icon';
  @override
  String get color => 'Colour';
  @override
  String deleteCategoryConfirm(String name) => 'Delete category "$name"?';
  @override
  String get deleteCategoryWarning =>
      'Transactions with this category will not be deleted, but will be left uncategorised.';
  @override
  String get nameTooLong => 'Name cannot exceed 100 characters';

  @override
  String categoryCreatedMsg(String name) => 'Category "$name" created';
  @override
  String categoryUpdatedMsg(String name) => 'Category "$name" updated';
  @override
  String categoryDeletedMsg(String name) => 'Category "$name" deleted';
  @override
  String get categoryDeleted => 'Category deleted';
  @override
  String get amountInvalidPositive => 'Enter a valid amount greater than 0';
  @override
  String get amountExceedsMax => 'Amount cannot exceed €999,999.99';
  @override
  String get ticketPhoto => 'Ticket photo';
  @override
  String get camera => 'Camera';
  @override
  String get takePictureNow => 'Take a picture now';
  @override
  String get gallery => 'Gallery';
  @override
  String get selectFromGallery => 'Select from gallery';
  @override
  String get deletePhoto => 'Delete photo';
  @override
  String get noChangesMsg => 'No changes made';
  @override
  String get confirmChanges => 'Confirm changes';
  @override
  String get confirmSaveChangesQuestion => 'Do you want to save the following changes?';
  @override
  String get modified => 'Modified';
  @override
  String get balanceRecalculateNote =>
      'Balance and statistics will be recalculated automatically.';
  @override
  String get selectCategoryHint => '* Select a category';
  @override
  String recategorizeSimilarMsg(String category) =>
      'Recategorize all transactions similar to "$category"?';
  @override
  String get recategorizeAll => 'Recategorize all';
  @override
  String lastModified(String date) => 'Last modified: $date';
  @override
  String get suggestedByHistory => 'Suggested by history';
  @override
  String get descriptionHint => 'E.g.: Weekly supermarket shop';
  @override
  String get addTicketPhoto => 'Add ticket photo';
  @override
  String get transactionUpdated => 'Transaction updated';
  @override
  String get deleteTransactionConfirmContent =>
      'Are you sure you want to delete this transaction?';
  @override
  String get permanentActionWarning =>
      'This action is permanent and cannot be undone.';
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

  @override
  String get phoneNumber => 'Phone number';
  @override
  String get profileBio => 'Bio';
  @override
  String get languageAndCurrency => 'Language & Currency';
  @override
  String get preferencesSectionTitle => 'Preferences';
  @override
  String biometricActivatedMsg(String label) =>
      '$label activated. Next login will be faster.';
  @override
  String get biometricCancelledMsg => 'Activation cancelled';
  @override
  String get biometricDeactivatedMsg => 'Biometric login disabled';
  @override
  String biometricSetupDeviceMsg(String label) =>
      'Set up $label in device settings first.';
  @override
  String get biometricErrorMsg => 'Error activating biometrics';
  @override
  String currencyChangedMsg(String code, String symbol) =>
      'Currency changed to $code ($symbol)';

  // ── Predictions intro cards ───────────────────────────────────────────────
  @override
  String get predictionIntroTitle => 'Expense Prediction';
  @override
  String get predictionIntroDesc =>
      'Analysis based on your spending history. See how much you\'ll spend next month by category.';
  @override
  String get savingsIntroTitle => 'Savings Opportunities';
  @override
  String get savingsIntroDesc =>
      'Identify where you can cut spending. Based on your usual spending patterns.';
  @override
  String get anomaliesIntroTitle => 'Unusual Expenses Detected';
  @override
  String get anomaliesIntroDesc =>
      'Expenses outside your normal pattern. These may indicate mistakes or unexpected costs.';
  @override
  String get subscriptionsIntroTitle => 'Active Subscriptions';
  @override
  String get subscriptionsIntroDesc =>
      'Recurring payments detected automatically. Review which ones you really need.';

  // ── Gemini ────────────────────────────────────────────────────────────────
  @override
  String get geminiKeyTitle => 'Configure Gemini API';
  @override
  String get geminiKeyDescription =>
      'Paste your Google Gemini API key to use AI directly. '
      'If you don\'t have a key, the assistant will use the Finora server.';
  @override
  String get geminiKeyConfigured => 'Gemini key configured ✓';
  @override
  String get geminiKeyRemoved => 'Gemini key removed';
  @override
  String get configureGeminiKey => 'Configure Gemini';
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
