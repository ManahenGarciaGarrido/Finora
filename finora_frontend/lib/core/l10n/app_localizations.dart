/// RNF-13: AppLocalizations — puente entre Flutter's localization system y AppStrings.
///
/// Uso en widgets:
/// ```dart
/// final s = AppLocalizations.of(context);
/// Text(s.home)  // 'Inicio' o 'Home' según el locale actual
/// ```
library;

import 'package:flutter/material.dart';
import 'app_strings.dart';

/// Clase que expone las traducciones al árbol de widgets vía context.
class AppLocalizations extends AppStringsBase {
  final AppStringsBase _strings;

  AppLocalizations(this._strings);

  /// Accede a las traducciones del locale actual desde cualquier widget.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(AppStrings.forLocale('es'));
  }

  /// Delegate que registra este sistema con MaterialApp.
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── Delegación a _strings ─────────────────────────────────────────────────
  @override
  String get hi => _strings.hi;
  @override
  String get goodMorning => _strings.goodMorning;
  @override
  String get goodAfternoon => _strings.goodAfternoon;
  @override
  String get goodNight => _strings.goodNight;

  @override
  String get january => _strings.january;
  @override
  String get february => _strings.february;
  @override
  String get march => _strings.march;
  @override
  String get april => _strings.april;
  @override
  String get may => _strings.may;
  @override
  String get june => _strings.june;
  @override
  String get july => _strings.july;
  @override
  String get august => _strings.august;
  @override
  String get september => _strings.september;
  @override
  String get october => _strings.october;
  @override
  String get november => _strings.november;
  @override
  String get december => _strings.december;
  @override
  String get jan => _strings.jan;
  @override
  String get feb => _strings.feb;
  @override
  String get mar => _strings.mar;
  @override
  String get apr => _strings.apr;
  @override
  String get mayy => _strings.may;
  @override
  String get jun => _strings.jun;
  @override
  String get jul => _strings.jul;
  @override
  String get aug => _strings.aug;
  @override
  String get sep => _strings.sep;
  @override
  String get oct => _strings.oct;
  @override
  String get nov => _strings.nov;
  @override
  String get dec => _strings.dec;

  @override
  String get home => _strings.home;
  @override
  String get transactions => _strings.transactions;
  @override
  String get statistics => _strings.statistics;
  @override
  String get goals => _strings.goals;
  @override
  String get settings => _strings.settings;
  @override
  String get accounts => _strings.accounts;
  @override
  String get analysis => _strings.analysis;

  @override
  String get login => _strings.login;
  @override
  String get logout => _strings.logout;
  @override
  String get register => _strings.register;
  @override
  String get email => _strings.email;
  @override
  String get password => _strings.password;
  @override
  String get confirmPassword => _strings.confirmPassword;
  @override
  String get forgotPassword => _strings.forgotPassword;
  @override
  String get biometricLogin => _strings.biometricLogin;
  @override
  String get twoFactorAuth => _strings.twoFactorAuth;

  @override
  String biometricEnabledStatus(String label) =>
      _strings.biometricEnabledStatus(label);
  @override
  String biometricDisabledStatus(String label) =>
      _strings.biometricDisabledStatus(label);

  @override
  String get newTransaction => _strings.newTransaction;
  @override
  String get hisorySuggestions => _strings.hisorySuggestions;
  @override
  String get addTransaction => _strings.addTransaction;
  @override
  String get editTransaction => _strings.editTransaction;
  @override
  String get deleteTransaction => _strings.deleteTransaction;
  @override
  String get income => _strings.income;
  @override
  String get expense => _strings.expense;
  @override
  String get category => _strings.category;
  @override
  String get description => _strings.description;
  @override
  String get amount => _strings.amount;
  @override
  String get date => _strings.date;
  @override
  String get paymentMethod => _strings.paymentMethod;
  @override
  String get noTransactions => _strings.noTransactions;
  @override
  String get history => _strings.history;
  @override
  String get monthlySummary => _strings.monthlySummary;
  @override
  String get firstTransaction => _strings.firstTransaction;
  @override
  String get registerFirst => _strings.registerFirst;

  @override
  String get finnWelcomeMessage => _strings.finnWelcomeMessage;
  @override
  String get suggestionSpentMonth => _strings.suggestionSpentMonth;
  @override
  String get suggestionTopCategory => _strings.suggestionTopCategory;
  @override
  String get suggestionGoalsProgress => _strings.suggestionGoalsProgress;
  @override
  String get suggestionAffordabilityExample =>
      _strings.suggestionAffordabilityExample;
  @override
  String get suggestionSavingTips => _strings.suggestionSavingTips;
  @override
  String get suggestionCurrentBalance => _strings.suggestionCurrentBalance;
  @override
  List<String> get affordabilityKeywords => _strings.affordabilityKeywords;
  @override
  String get aiRecsHeader => _strings.aiRecsHeader;
  @override
  String get aiRecsBalanced => _strings.aiRecsBalanced;
  @override
  String aiFinancialScore(int score) => _strings.aiFinancialScore(score);
  @override
  String aiPotentialSavingMonthly(String amount) =>
      _strings.aiPotentialSavingMonthly(amount);
  @override
  String monthCountLabel(int count) => _strings.monthCountLabel(count);

  @override
  String get budgetsTitle => _strings.budgetsTitle;
  @override
  String get budgetStatusTab => _strings.budgetStatusTab;
  @override
  String get myBudgetsTab => _strings.myBudgetsTab;
  @override
  String get editBudgetTitle => _strings.editBudgetTitle;
  @override
  String get newBudgetTitle => _strings.newBudgetTitle;
  @override
  String get monthlyLimitLabel => _strings.monthlyLimitLabel;
  @override
  String get invalidAmountError => _strings.invalidAmountError;
  @override
  String get budgetSavedMsg => _strings.budgetSavedMsg;
  @override
  String get deleteBudgetTitle => _strings.deleteBudgetTitle;
  @override
  String deleteBudgetConfirm(String category) =>
      _strings.deleteBudgetConfirm(category);
  @override
  String get noBudgetsConfigured => _strings.noBudgetsConfigured;
  @override
  String get createFirstBudgetInfo => _strings.createFirstBudgetInfo;
  @override
  String get budgetExceededLabel => _strings.budgetExceededLabel;
  @override
  String get budget80ReachedLabel => _strings.budget80ReachedLabel;
  @override
  String get remainingLabel => _strings.remainingLabel;
  @override
  String get unbudgetedTitle => _strings.unbudgetedTitle;
  @override
  String get addLimitLabel => _strings.addLimitLabel;
  @override
  String activeAlertsMsg(int count) => _strings.activeAlertsMsg(count);
  @override
  String get spentOfLabel => _strings.spentOfLabel;

  @override
  String get spendingByCategory => _strings.spendingByCategory;
  @override
  String get monthlyComparative => _strings.monthlyComparative;
  @override
  String get topMonthlyExpenses => _strings.topMonthlyExpenses;
  @override
  String get nextExpenses => _strings.nextExpenses;
  @override
  String get temporalEvolution => _strings.temporalEvolution;
  @override
  String get period => _strings.period;
  @override
  String get reset => _strings.reset;
  @override
  String get expenseProgress => _strings.expenseProgress;
  @override
  String get ofIncome => _strings.ofIncome;
  @override
  String get yesterday => _strings.yesterday;
  @override
  String get objectiveLoadFailure => _strings.objectiveLoadFailure;
  @override
  String get ofText => _strings.ofText;
  @override
  String get today => _strings.today;
  @override
  String get tomorrow => _strings.tomorrow;
  @override
  String get inDays => _strings.inDays;
  @override
  String get days => _strings.days;
  @override
  String get monthPeriod => _strings.monthPeriod;
  @override
  String get thisMonth => _strings.thisMonth;
  @override
  String get sixMonths => _strings.sixMonths;
  @override
  String get yearPeriod => _strings.yearPeriod;

  @override
  String get savingsGoals => _strings.savingsGoals;
  @override
  String get seeAll => _strings.seeAll;
  @override
  String get createGoal => _strings.createGoal;
  @override
  String get targetAmount => _strings.targetAmount;
  @override
  String get currentAmount => _strings.currentAmount;
  @override
  String get deadline => _strings.deadline;
  @override
  String get progress => _strings.progress;
  @override
  String get addContribution => _strings.addContribution;
  @override
  String get noGoals => _strings.noGoals;

  @override
  String get budgets => _strings.budgets;
  @override
  String get newBudget => _strings.newBudget;
  @override
  String get monthlyLimit => _strings.monthlyLimit;
  @override
  String get budgetStatus => _strings.budgetStatus;
  @override
  String get overBudget => _strings.overBudget;
  @override
  String get nearLimit => _strings.nearLimit;

  @override
  String get exportData => _strings.exportData;
  @override
  String get exportCsv => _strings.exportCsv;
  @override
  String get exportPdf => _strings.exportPdf;
  @override
  String get dateRange => _strings.dateRange;
  @override
  String get from => _strings.from;
  @override
  String get to => _strings.to;
  @override
  String get inc => _strings.inc;
  @override
  String get exp => _strings.exp;
  @override
  String get share => _strings.share;
  @override
  String get generating => _strings.generating;

  @override
  String get notifications => _strings.notifications;
  @override
  String get pushTransactions => _strings.pushTransactions;
  @override
  String get pushBudgetAlerts => _strings.pushBudgetAlerts;
  @override
  String get pushGoalReminders => _strings.pushGoalReminders;
  @override
  String get minAmount => _strings.minAmount;
  @override
  String get quietHours => _strings.quietHours;
  @override
  String get noNotifications => _strings.noNotifications;

  @override
  String get security => _strings.security;
  @override
  String get changePassword => _strings.changePassword;
  @override
  String get biometricAuth => _strings.biometricAuth;
  @override
  String get setup2fa => _strings.setup2fa;
  @override
  String get scan2faQr => _strings.scan2faQr;
  @override
  String get verifyCode => _strings.verifyCode;
  @override
  String get recoveryCodes => _strings.recoveryCodes;
  @override
  String get disable2fa => _strings.disable2fa;
  @override
  String get user => _strings.user;

  @override
  String get save => _strings.save;
  @override
  String get cancel => _strings.cancel;
  @override
  String get delete => _strings.delete;
  @override
  String get edit => _strings.edit;
  @override
  String get confirm => _strings.confirm;
  @override
  String get loading => _strings.loading;
  @override
  String get error => _strings.error;
  @override
  String get retry => _strings.retry;
  @override
  String get search => _strings.search;
  @override
  String get filter => _strings.filter;
  @override
  String get all => _strings.all;
  @override
  String get noData => _strings.noData;
  @override
  String get comingSoon => _strings.comingSoon;
  @override
  String get language => _strings.language;
  @override
  String get spanish => _strings.spanish;
  @override
  String get english => _strings.english;

  @override
  String get onboardingSkip => _strings.onboardingSkip;
  @override
  String get onboardingNext => _strings.onboardingNext;
  @override
  String get onboardingStart => _strings.onboardingStart;
  @override
  String get onboarding1Title => _strings.onboarding1Title;
  @override
  String get onboarding1Subtitle => _strings.onboarding1Subtitle;
  @override
  String get onboarding2Title => _strings.onboarding2Title;
  @override
  String get registerTransactions => _strings.registerTransactions;
  @override
  String get emptyTopExpenses => _strings.emptyTopExpenses;
  @override
  String get onboarding2Subtitle => _strings.onboarding2Subtitle;
  @override
  String get onboarding3Title => _strings.onboarding3Title;
  @override
  String get onboarding3Subtitle => _strings.onboarding3Subtitle;
  @override
  String get withoutRecurringExpenses => _strings.withoutRecurringExpenses;
  @override
  String get recurringTimeLeft => _strings.recurringTimeLeft;
  @override
  String get onboarding4Title => _strings.onboarding4Title;
  @override
  String get onboarding4Subtitle => _strings.onboarding4Subtitle;

  @override
  String get networkError => _strings.networkError;
  @override
  String get authError => _strings.authError;
  @override
  String get unknownError => _strings.unknownError;
  @override
  String get sessionExpired => _strings.sessionExpired;

  @override
  String get twoFaProtectionInfo => _strings.twoFaProtectionInfo;
  @override
  String get twoFaActivatePrompt => _strings.twoFaActivatePrompt;
  @override
  String get twoFaIncorrectCode => _strings.twoFaIncorrectCode;
  @override
  String get twoFaEnterPasswordDisable => _strings.twoFaEnterPasswordDisable;
  @override
  String get incorrectPassword => _strings.incorrectPassword;
  @override
  String get howDoesItWork => _strings.howDoesItWork;
  @override
  String get installAuthApp => _strings.installAuthApp;
  @override
  String get sessionRequirement2fa => _strings.sessionRequirement2fa;
  @override
  String get openAuthAppPrompt => _strings.openAuthAppPrompt;
  @override
  String get manualKeyPrompt => _strings.manualKeyPrompt;
  @override
  String get active2faInfo => _strings.active2faInfo;
  @override
  String get currentPassword => _strings.currentPassword;
  @override
  String get saveCodesWarning => _strings.saveCodesWarning;

  @override
  String get nutrition => _strings.nutrition;
  @override
  String get transport => _strings.transport;
  @override
  String get leisure => _strings.leisure;
  @override
  String get salary => _strings.salary;
  @override
  String get health => _strings.health;
  @override
  String get housing => _strings.housing;
  @override
  String get services => _strings.services;
  @override
  String get education => _strings.education;
  @override
  String get clothing => _strings.clothing;
  @override
  String get other => _strings.other;
  @override
  String get saving => _strings.saving;

  @override
  String get sectionGeneral => _strings.sectionGeneral;
  @override
  String get sectionSecurity => _strings.sectionSecurity;
  @override
  String get sectionData => _strings.sectionData;
  @override
  String get settingsCategories => _strings.settingsCategories;
  @override
  String get settingsCategoriesSubtitle => _strings.settingsCategoriesSubtitle;
  @override
  String get settingsNotifications => _strings.settingsNotifications;
  @override
  String get settingsNotificationsSubtitle =>
      _strings.settingsNotificationsSubtitle;
  @override
  String get settingsBudgets => _strings.settingsBudgets;
  @override
  String get settingsBudgetsSubtitle => _strings.settingsBudgetsSubtitle;
  @override
  String get settingsCurrency => _strings.settingsCurrency;
  @override
  String get settingsChangePassword => _strings.settingsChangePassword;
  @override
  String get settingsChangePasswordSubtitle =>
      _strings.settingsChangePasswordSubtitle;
  @override
  String get settingsBiometric2fa => _strings.settingsBiometric2fa;
  @override
  String get settingsDataPrivacy => _strings.settingsDataPrivacy;
  @override
  String get settingsExportData => _strings.settingsExportData;
  @override
  String get settingsExportDataSubtitle => _strings.settingsExportDataSubtitle;
  @override
  String get settingsPsd2 => _strings.settingsPsd2;
  @override
  String get settingsPsd2Subtitle => _strings.settingsPsd2Subtitle;
  @override
  String get settingsPrivacy => _strings.settingsPrivacy;
  @override
  String get settingsPrivacySubtitle => _strings.settingsPrivacySubtitle;
  @override
  String get settingsLogout => _strings.settingsLogout;
  @override
  String get changingLanguage => _strings.changingLanguage;

  @override
  String get locale => _strings.locale;
  @override
  String get currencySymbol => _strings.currencySymbol;
  @override
  String get dateFormat => _strings.dateFormat;

  // ── Contenido Legal: Términos y Condiciones ────────────────────────────────
  @override
  String get termsSection1Title => _strings.termsSection1Title;
  @override
  String get termsSection1Body => _strings.termsSection1Body;
  @override
  String get termsSection2Title => _strings.termsSection2Title;
  @override
  String get termsSection2Body => _strings.termsSection2Body;
  @override
  String get termsSection3Title => _strings.termsSection3Title;
  @override
  String get termsSection3Body => _strings.termsSection3Body;
  @override
  String get termsSection4Title => _strings.termsSection4Title;
  @override
  String get termsSection4Body => _strings.termsSection4Body;
  @override
  String get termsSection5Title => _strings.termsSection5Title;
  @override
  String get termsSection5Body => _strings.termsSection5Body;
  @override
  String get termsSection6Title => _strings.termsSection6Title;
  @override
  String get termsSection6Body => _strings.termsSection6Body;
  @override
  String get termsSection7Title => _strings.termsSection7Title;
  @override
  String get termsSection7Body => _strings.termsSection7Body;

  // ── Contenido Legal: Privacidad ────────────────────────────────────────────
  @override
  String get privacyPolicyContact => _strings.privacyPolicyContact;
  @override
  String get gdprComplianceFull => _strings.gdprComplianceFull;

  @override
  String get welcomeBack => _strings.welcomeBack;
  @override
  String get signInToContinue => _strings.signInToContinue;
  @override
  String get emailRequired => _strings.emailRequired;
  @override
  String get emailInvalid => _strings.emailInvalid;
  @override
  String get passwordRequired => _strings.passwordRequired;
  @override
  String get emailVerificationPending => _strings.emailVerificationPending;
  @override
  String get emailNotVerifiedMsg => _strings.emailNotVerifiedMsg;
  @override
  String get checkInboxMsg => _strings.checkInboxMsg;
  @override
  String get resendEmail => _strings.resendEmail;
  @override
  String get spendingTrend => _strings.spendingTrend;
  @override
  String get understood => _strings.understood;
  @override
  String get authenticating => _strings.authenticating;
  @override
  String get accessWith => _strings.accessWith;
  @override
  String get noAccountYet => _strings.noAccountYet;
  @override
  String get emailHint => _strings.emailHint;

  @override
  String get resetPasswordTitle => _strings.resetPasswordTitle;
  @override
  String get resetPasswordSubtitle => _strings.resetPasswordSubtitle;
  @override
  String get newPasswordLabel => _strings.newPasswordLabel;
  @override
  String get confirmPasswordLabel => _strings.confirmPasswordLabel;
  @override
  String get confirmPasswordRequired => _strings.confirmPasswordRequired;
  @override
  String get resetPasswordButton => _strings.resetPasswordButton;
  @override
  String get successTitle => _strings.successTitle;
  @override
  String get passwordRequirementsHeader => _strings.passwordRequirementsHeader;

  @override
  String get fullName => _strings.fullName;
  @override
  String get nameRequired => _strings.nameRequired;
  @override
  String get nameHint => _strings.nameHint;
  @override
  String get passwordsDoNotMatch => _strings.passwordsDoNotMatch;
  @override
  String get alreadyHaveAccount => _strings.alreadyHaveAccount;
  @override
  String get passwordMinLength => _strings.passwordMinLength;

  @override
  String get ok => _strings.ok;
  @override
  String get fieldRequired => _strings.fieldRequired;
  @override
  String get amountRequired => _strings.amountRequired;
  @override
  String get amountInvalid => _strings.amountInvalid;

  @override
  String get incomes => _strings.incomes;
  @override
  String get balance => _strings.balance;
  @override
  String get expenses => _strings.expenses;
  @override
  String get noDataForPeriod => _strings.noDataForPeriod;
  @override
  String get threeMonths => _strings.threeMonths;
  @override
  String get totalIncome => _strings.totalIncome;
  @override
  String get totalExpenses => _strings.totalExpenses;
  @override
  String get netBalance => _strings.netBalance;

  @override
  String get totalBalance => _strings.totalBalance;
  @override
  String get addAccount => _strings.addAccount;
  @override
  String get noAccounts => _strings.noAccounts;
  @override
  String get linkedBanks => _strings.linkedBanks;
  @override
  String get addBankAccount => _strings.addBankAccount;
  @override
  String get disconnect => _strings.disconnect;
  @override
  String get manualAccount => _strings.manualAccount;
  @override
  String get bankAccountLabel => _strings.bankAccountLabel;
  @override
  String get accountName => _strings.accountName;
  @override
  String get initialBalance => _strings.initialBalance;
  @override
  String get connectBank => _strings.connectBank;
  @override
  String get bankConnected => _strings.bankConnected;

  @override
  String get noCategories => _strings.noCategories;
  @override
  String get addCategory => _strings.addCategory;
  @override
  String get categoryName => _strings.categoryName;
  @override
  String get selectIcon => _strings.selectIcon;
  @override
  String get selectColor => _strings.selectColor;
  @override
  String get categoryType => _strings.categoryType;

  @override
  String get enableNotifications => _strings.enableNotifications;
  @override
  String get notificationFilters => _strings.notificationFilters;
  @override
  String get fromTime => _strings.fromTime;
  @override
  String get toTime => _strings.toTime;

  @override
  String get noBudgets => _strings.noBudgets;
  @override
  String get addBudget => _strings.addBudget;
  @override
  String get spent => _strings.spent;
  @override
  String get remaining => _strings.remaining;
  @override
  String get ofAmount => _strings.ofAmount;
  @override
  String get budgetProgress => _strings.budgetProgress;

  @override
  String get enableBiometric => _strings.enableBiometric;
  @override
  String get biometricNotAvailable => _strings.biometricNotAvailable;
  @override
  String get notAvailable => _strings.notAvailable;
  @override
  String get biometricFaceId => _strings.biometricFaceId;
  @override
  String get biometricFingerprint => _strings.biometricFingerprint;
  @override
  String get biometricGeneric => _strings.biometricGeneric;
  @override
  String get biometricDescription => _strings.biometricDescription;
  @override
  String get disableBiometric => _strings.disableBiometric;

  @override
  String get enter2faCode => _strings.enter2faCode;
  @override
  String get code2faHint => _strings.code2faHint;
  @override
  String get enable2fa => _strings.enable2fa;
  @override
  String get twoFaEnabled => _strings.twoFaEnabled;
  @override
  String get twoFaDisabled => _strings.twoFaDisabled;
  @override
  String get copyCode => _strings.copyCode;
  @override
  String get codeCopied => _strings.codeCopied;

  @override
  String get consents => _strings.consents;
  @override
  String get consentExpires => _strings.consentExpires;
  @override
  String get revokeConsent => _strings.revokeConsent;
  @override
  String get active => _strings.active;
  @override
  String get expired => _strings.expired;
  @override
  String get noConsents => _strings.noConsents;
  @override
  String get consentStatus => _strings.consentStatus;

  @override
  String get goalName => _strings.goalName;
  @override
  String get goalNameHint => _strings.goalNameHint;
  @override
  String get noGoalsYet => _strings.noGoalsYet;
  @override
  String get createFirstGoal => _strings.createFirstGoal;
  @override
  String get contributionAmount => _strings.contributionAmount;
  @override
  String get goalProgress => _strings.goalProgress;
  @override
  String get daysLeft => _strings.daysLeft;
  @override
  String get completed => _strings.completed;

  @override
  String get transactionType => _strings.transactionType;
  @override
  String get selectCategory => _strings.selectCategory;
  @override
  String get selectACategory => _strings.selectACategory;
  @override
  String get note => _strings.note;
  @override
  String get noteHint => _strings.noteHint;
  @override
  String get recentTransactions => _strings.recentTransactions;

  @override
  String get privacyPolicy => _strings.privacyPolicy;
  @override
  String get termsOfService => _strings.termsOfService;
  @override
  String get dataConsent => _strings.dataConsent;
  @override
  String get deleteAccount => _strings.deleteAccount;
  @override
  String get deleteAllData => _strings.deleteAllData;
  @override
  String get downloadData => _strings.downloadData;

  @override
  String get registerTitle => _strings.registerTitle;
  @override
  String get registerSubtitle => _strings.registerSubtitle;
  @override
  String get nameTooShort => _strings.nameTooShort;
  @override
  String get passwordTooShort => _strings.passwordTooShort;
  @override
  String get passwordUppercase => _strings.passwordUppercase;
  @override
  String get passwordNumber => _strings.passwordNumber;
  @override
  String get passwordSpecial => _strings.passwordSpecial;
  @override
  String get passwordsDontMatch => _strings.passwordsDontMatch;
  @override
  String get acceptTermsPrivacyError => _strings.acceptTermsPrivacyError;
  @override
  String get registerSuccessTitle => _strings.registerSuccessTitle;
  @override
  String get verificationEmailSent => _strings.verificationEmailSent;
  @override
  String get checkInboxVerify => _strings.checkInboxVerify;
  @override
  String get verificationWarning => _strings.verificationWarning;
  @override
  String get goToLogin => _strings.goToLogin;
  @override
  String get fullNameLabel => _strings.fullNameLabel;
  @override
  String get fullNameHint => _strings.fullNameHint;
  @override
  String get passwordStrengthVeryWeak => _strings.passwordStrengthVeryWeak;
  @override
  String get passwordStrengthWeak => _strings.passwordStrengthWeak;
  @override
  String get passwordStrengthMedium => _strings.passwordStrengthMedium;
  @override
  String get passwordStrengthStrong => _strings.passwordStrengthStrong;
  @override
  String get reqChars => _strings.reqChars;
  @override
  String get reqUpper => _strings.reqUpper;
  @override
  String get reqNumber => _strings.reqNumber;
  @override
  String get reqSpecial => _strings.reqSpecial;
  @override
  String get acceptTermsPart1 => _strings.acceptTermsPart1;
  @override
  String get termsAndConditions => _strings.termsAndConditions;
  @override
  String get acceptPrivacyPart1 => _strings.acceptPrivacyPart1;
  @override
  String get loginLink => _strings.loginLink;
  @override
  String get requiredBadge => _strings.requiredBadge;
  @override
  String get consentManagementTitle => _strings.consentManagementTitle;
  @override
  String get consentDescription => _strings.consentDescription;
  @override
  String get essentialDataTitle => _strings.essentialDataTitle;
  @override
  String get essentialDataDesc => _strings.essentialDataDesc;
  @override
  String get dataProcessingTitle => _strings.dataProcessingTitle;
  @override
  String get dataProcessingDesc => _strings.dataProcessingDesc;
  @override
  String get analyticsTitle => _strings.analyticsTitle;
  @override
  String get analyticsDesc => _strings.analyticsDesc;
  @override
  String get marketingTitle => _strings.marketingTitle;
  @override
  String get marketingDesc => _strings.marketingDesc;
  @override
  String get thirdPartyTitle => _strings.thirdPartyTitle;
  @override
  String get thirdPartyDesc => _strings.thirdPartyDesc;
  @override
  String get personalizationTitle => _strings.personalizationTitle;
  @override
  String get personalizationDesc => _strings.personalizationDesc;
  @override
  String get policySummaryTitle => _strings.policySummaryTitle;
  @override
  String get gdprComplianceText => _strings.gdprComplianceText;
  @override
  String get lastUpdateText => _strings.lastUpdateText;
  @override
  String get acceptTermsButton => _strings.acceptTermsButton;
  @override
  String get acceptPrivacyButton => _strings.acceptPrivacyButton;

  @override
  String get forgotPasswordTitle => _strings.forgotPasswordTitle;
  @override
  String get forgotPasswordSubtitle => _strings.forgotPasswordSubtitle;
  @override
  String get emailLabel => _strings.emailLabel;
  @override
  String get invalidEmail => _strings.invalidEmail;
  @override
  String get sendLink => _strings.sendLink;
  @override
  String get backToLogin => _strings.backToLogin;
  @override
  String get emailSentTitle => _strings.emailSentTitle;
  @override
  String get emailSentInstructions => _strings.emailSentInstructions;

  @override
  String get appVersion => _strings.appVersion;
  @override
  String get close => _strings.close;
  @override
  String get next => _strings.next;
  @override
  String get back => _strings.back;
  @override
  String get skip => _strings.skip;
  @override
  String get done => _strings.done;
  @override
  String get add => _strings.add;
  @override
  String get name => _strings.name;
  @override
  String get type => _strings.type;
  @override
  String get optional => _strings.optional;
  @override
  String get required => _strings.required;
  @override
  String get enabled => _strings.enabled;
  @override
  String get disabled => _strings.disabled;
  @override
  String get on => _strings.on;
  @override
  String get off => _strings.off;

  @override
  String categoryCreatedMsg(String name) => _strings.categoryCreatedMsg(name);
  @override
  String categoryUpdatedMsg(String name) => _strings.categoryUpdatedMsg(name);
  @override
  String categoryDeletedMsg(String name) => _strings.categoryDeletedMsg(name);
  @override
  String goalCreatedMsg(String name) => _strings.goalCreatedMsg(name);
  @override
  String budgetCreatedMsg(String name) => _strings.budgetCreatedMsg(name);
  @override
  String budgetUpdatedMsg(String name) => _strings.budgetUpdatedMsg(name);
  @override
  String budgetDeletedMsg(String name) => _strings.budgetDeletedMsg(name);
  @override
  String accountDeletedMsg(String name) => _strings.accountDeletedMsg(name);

  @override
  String get privacyAndData => _strings.privacyAndData;
  @override
  String get gdprCompliance => _strings.gdprCompliance;
  @override
  String get viewPrivacyPolicy => _strings.viewPrivacyPolicy;
  @override
  String get consentManagement => _strings.consentManagement;
  @override
  String get consentManagementSubtitle => _strings.consentManagementSubtitle;
  @override
  String get savePreferences => _strings.savePreferences;
  @override
  String get gdprRights => _strings.gdprRights;
  @override
  String get dangerZone => _strings.dangerZone;
  @override
  String get dangerZoneDesc => _strings.dangerZoneDesc;
  @override
  String get deleteMyAccount => _strings.deleteMyAccount;
  @override
  String get preferencesSavedSuccess => _strings.preferencesSavedSuccess;
  @override
  String get exportMyData => _strings.exportMyData;
  @override
  String get dataExportedTitle => _strings.dataExportedTitle;
  @override
  String get dataSummary => _strings.dataSummary;
  @override
  String get deleteAccountConfirmTitle => _strings.deleteAccountConfirmTitle;
  @override
  String get confirmDeletionTitle => _strings.confirmDeletionTitle;
  @override
  String get deleteDefinitely => _strings.deleteDefinitely;
  @override
  String get deleteConfirmHint => _strings.deleteConfirmHint;
  @override
  String get deleteReasonHint => _strings.deleteReasonHint;
  @override
  String get typeDeleteToConfirmError => _strings.typeDeleteToConfirmError;
  @override
  String get accountPermanentlyDeleted => _strings.accountPermanentlyDeleted;
  @override
  String get editProfileComingSoon => _strings.editProfileComingSoon;
  @override
  String get noConsentChanges => _strings.noConsentChanges;
  @override
  String get privacyPolicyTitle => _strings.privacyPolicyTitle;
  @override
  String get acceptedStatus => _strings.acceptedStatus;
  @override
  String get rejectedStatus => _strings.rejectedStatus;
  @override
  String get consentHistoryTitle => _strings.consentHistoryTitle;
  @override
  String get consentHistoryDesc => _strings.consentHistoryDesc;
  @override
  String get dataProcessingInfoTitle => _strings.dataProcessingInfoTitle;
  @override
  String get dataProcessingInfoDesc => _strings.dataProcessingInfoDesc;
  @override
  String get rightOfAccess => _strings.rightOfAccess;
  @override
  String get rightOfAccessDesc => _strings.rightOfAccessDesc;
  @override
  String get rightOfRectification => _strings.rightOfRectification;
  @override
  String get rightOfRectificationDesc => _strings.rightOfRectificationDesc;

  @override
  String get cashMoney => _strings.cashMoney;
  @override
  String get howMuchCash => _strings.howMuchCash;
  @override
  String get cashSetupInfo => _strings.cashSetupInfo;
  @override
  String get transactionBalance => _strings.transactionBalance;
  @override
  String get realData => _strings.realData;
  @override
  String get bankAccounts => _strings.bankAccounts;
  @override
  String get availableBalance => _strings.availableBalance;
  @override
  String get ibanLabel => _strings.ibanLabel;
  @override
  String get synchronized => _strings.synchronized;

  @override
  String get connectionError => _strings.connectionError;
  @override
  String get disconnectedAccessRevoked => _strings.disconnectedAccessRevoked;
  @override
  String get accountDisconnectedAccessRevoked =>
      _strings.accountDisconnectedAccessRevoked;
  @override
  String get accountsErrorPrefix => _strings.accountsErrorPrefix;
  @override
  String psd2ExpiryMsg(int days) => _strings.psd2ExpiryMsg(days);
  @override
  String get syncCompleteNoNews => _strings.syncCompleteNoNews;
  @override
  String get bankSessionExpired => _strings.bankSessionExpired;
  @override
  String get bankSessionExpiredMsg => _strings.bankSessionExpiredMsg;
  @override
  String get bankReconnectInfo => _strings.bankReconnectInfo;
  @override
  String get notNow => _strings.notNow;
  @override
  String get reconnect => _strings.reconnect;

  @override
  String get securityTitle => _strings.securityTitle;
  @override
  String get changePasswordHeading => _strings.changePasswordHeading;
  @override
  String get passwordRequirementsInfo => _strings.passwordRequirementsInfo;
  @override
  String get currentPasswordLabel => _strings.currentPasswordLabel;
  @override
  String get enterCurrentPasswordError => _strings.enterCurrentPasswordError;
  @override
  String get minCharactersError => _strings.minCharactersError;
  @override
  String get confirmNewPasswordLabel => _strings.confirmNewPasswordLabel;
  @override
  String get passwordsDoNotMatchError => _strings.passwordsDoNotMatchError;
  @override
  String get passwordUpdatedMsg => _strings.passwordUpdatedMsg;
  @override
  String get incorrectCurrentPasswordMsg =>
      _strings.incorrectCurrentPasswordMsg;
  @override
  String get changePasswordErrorMsg => _strings.changePasswordErrorMsg;
  @override
  String get updatePasswordButton => _strings.updatePasswordButton;

  @override
  String get editProfileTitle => _strings.editProfileTitle;
  @override
  String get publicInfoHeading => _strings.publicInfoHeading;
  @override
  String get nameRequiredError => _strings.nameRequiredError;
  @override
  String get profileUpdatedMsg => _strings.profileUpdatedMsg;
  @override
  String get profileUpdateErrorMsg => _strings.profileUpdateErrorMsg;

  @override
  String get splashSubtitle => _strings.splashSubtitle;

  @override
  String get exportDataTitle => _strings.exportDataTitle;
  @override
  String get exportCsvTitle => _strings.exportCsvTitle;
  @override
  String get exportCsvSubtitle => _strings.exportCsvSubtitle;
  @override
  String get dateRangeLabel => _strings.dateRangeLabel;
  @override
  String get fromLabel => _strings.fromLabel;
  @override
  String get toLabel => _strings.toLabel;
  @override
  String get allTypeLabel => _strings.allTypeLabel;
  @override
  String get generatingLabel => _strings.generatingLabel;
  @override
  String get exportAndShareCsv => _strings.exportAndShareCsv;
  @override
  String get exportPdfTitle => _strings.exportPdfTitle;
  @override
  String get exportPdfSubtitle => _strings.exportPdfSubtitle;
  @override
  String get periodLabel => _strings.periodLabel;
  @override
  String get periodMonth => _strings.periodMonth;
  @override
  String get periodYear => _strings.periodYear;
  @override
  String get periodCustom => _strings.periodCustom;
  @override
  String get yearLabel => _strings.yearLabel;
  @override
  String get monthLabel => _strings.monthLabel;
  @override
  String get generateAndSharePdf => _strings.generateAndSharePdf;
  @override
  String get pdfFinancialReport => _strings.pdfFinancialReport;
  @override
  String get pdfGeneratedAt => _strings.pdfGeneratedAt;
  @override
  String get pdfExecutiveSummary => _strings.pdfExecutiveSummary;
  @override
  String get pdfExpensesByCategory => _strings.pdfExpensesByCategory;
  @override
  String get pdfPeriodTransactions => _strings.pdfPeriodTransactions;
  @override
  String get pdfFooter => _strings.pdfFooter;
  @override
  String get pdfDescription => _strings.pdfDescription;
  @override
  String get errorExportCsv => _strings.errorExportCsv;
  @override
  String get errorGeneratePdf => _strings.errorGeneratePdf;
  @override
  List<String> get monthNames => _strings.monthNames;

  @override
  String get notificationsTitle => _strings.notificationsTitle;
  @override
  String get settingsSavedMsg => _strings.settingsSavedMsg;
  @override
  String errorSavingSettingsMsg(String error) =>
      _strings.errorSavingSettingsMsg(error);
  @override
  String get notificationsPermissionInfo =>
      _strings.notificationsPermissionInfo;
  @override
  String get notificationTypesSection => _strings.notificationTypesSection;
  @override
  String get newTransactionsTitle => _strings.newTransactionsTitle;
  @override
  String get newTransactionsSubtitle => _strings.newTransactionsSubtitle;
  @override
  String get budgetAlertsTitle => _strings.budgetAlertsTitle;
  @override
  String get budgetAlertsSubtitle => _strings.budgetAlertsSubtitle;
  @override
  String get goalProgressTitle => _strings.goalProgressTitle;
  @override
  String get goalProgressSubtitle => _strings.goalProgressSubtitle;
  @override
  String get filtersSection => _strings.filtersSection;
  @override
  String get minAmountTitle => _strings.minAmountTitle;
  @override
  String get minAmountSubtitle => _strings.minAmountSubtitle;
  @override
  String get noLimitLabel => _strings.noLimitLabel;
  @override
  String get quietHoursSection => _strings.quietHoursSection;
  @override
  String get quietHoursTitle => _strings.quietHoursTitle;
  @override
  String get quietHoursSubtitle => _strings.quietHoursSubtitle;
  @override
  String get startLabel => _strings.startLabel;
  @override
  String get endLabel => _strings.endLabel;
  @override
  String toggleStatusSemantics(String title, bool value) =>
      _strings.toggleStatusSemantics(title, value);

  @override
  String accountsFromInstitution(String name) =>
      _strings.accountsFromInstitution(name);
  @override
  String get selectAccountsSubtitle => _strings.selectAccountsSubtitle;
  @override
  String confirmLinkAccounts(int count) => _strings.confirmLinkAccounts(count);
  @override
  String linkingAccounts(String label) => _strings.linkingAccounts(label);
  @override
  String accountCountLabel(int count) => _strings.accountCountLabel(count);

  @override
  String get linkingStep1 => _strings.linkingStep1;
  @override
  String get linkingStep2 => _strings.linkingStep2;
  @override
  String get linkingStep3 => _strings.linkingStep3;
  @override
  String get linkingStep4 => _strings.linkingStep4;
  @override
  String get linkingStep5 => _strings.linkingStep5;
  @override
  String get linkingStep6 => _strings.linkingStep6;
  @override
  String get linkingStep7 => _strings.linkingStep7;
  @override
  String get linkingStep8 => _strings.linkingStep8;
  @override
  String get linkingStep9 => _strings.linkingStep9;

  @override
  String get newAccountTitle => _strings.newAccountTitle;
  @override
  String get accountNameLabel => _strings.accountNameLabel;
  @override
  String get accountNameHint => _strings.accountNameHint;
  @override
  String get accountTypeLabel => _strings.accountTypeLabel;
  @override
  String get accountTypeCurrent => _strings.accountTypeCurrent;
  @override
  String get accountTypeSavings => _strings.accountTypeSavings;
  @override
  String get accountTypeInvestment => _strings.accountTypeInvestment;
  @override
  String get accountTypeOther => _strings.accountTypeOther;
  @override
  String get ibanOptional => _strings.ibanOptional;
  @override
  String get ibanHint => _strings.ibanHint;
  @override
  String get cardsLabel => _strings.cardsLabel;
  @override
  String get addBtn => _strings.addBtn;
  @override
  String get noCardsOptional => _strings.noCardsOptional;
  @override
  String get cardTypeDebit => _strings.cardTypeDebit;
  @override
  String get cardTypeCredit => _strings.cardTypeCredit;
  @override
  String get cardTypePrepaid => _strings.cardTypePrepaid;
  @override
  String get addCardTitle => _strings.addCardTitle;
  @override
  String get cardNameLabel => _strings.cardNameLabel;
  @override
  String get cardNameHint => _strings.cardNameHint;
  @override
  String get lastFourDigitsLabel => _strings.lastFourDigitsLabel;
  @override
  String get importCsvLabel => _strings.importCsvLabel;
  @override
  String get csvImportDesc => _strings.csvImportDesc;
  @override
  String get csvFormatHelper => _strings.csvFormatHelper;
  @override
  String get selectCsvFile => _strings.selectCsvFile;
  @override
  String csvMovementsDetected(int count) =>
      _strings.csvMovementsDetected(count);
  @override
  String csvImportResult(int imported, int skipped) =>
      _strings.csvImportResult(imported, skipped);
  @override
  String get csvReadError => _strings.csvReadError;
  @override
  String get cardAddError => _strings.cardAddError;
  @override
  String get csvImportError => _strings.csvImportError;
  @override
  String get saveAccountBtn => _strings.saveAccountBtn;

  @override
  String get skipButton => _strings.skipButton;
  @override
  String get nextButton => _strings.nextButton;
  @override
  String get startNowButton => _strings.startNowButton;
  @override
  String get skipIntroductionSemantics => _strings.skipIntroductionSemantics;
  @override
  String get onboardingStep1Title => _strings.onboardingStep1Title;
  @override
  String get onboardingStep1Subtitle => _strings.onboardingStep1Subtitle;
  @override
  String get onboardingStep1Description => _strings.onboardingStep1Description;
  @override
  String get onboardingStep2Title => _strings.onboardingStep2Title;
  @override
  String get onboardingStep2Subtitle => _strings.onboardingStep2Subtitle;
  @override
  String get onboardingStep2Description => _strings.onboardingStep2Description;
  @override
  String get onboardingStep3Title => _strings.onboardingStep3Title;
  @override
  String get onboardingStep3Subtitle => _strings.onboardingStep3Subtitle;
  @override
  String get onboardingStep3Description => _strings.onboardingStep3Description;
  @override
  String get onboardingStep4Title => _strings.onboardingStep4Title;
  @override
  String get onboardingStep4Subtitle => _strings.onboardingStep4Subtitle;
  @override
  String get onboardingStep4Description => _strings.onboardingStep4Description;

  @override
  String get transactionsTitle => _strings.transactionsTitle;
  @override
  String get searchHint => _strings.searchHint;
  @override
  String get resultsCount => _strings.resultsCount;
  @override
  String get resultCount => _strings.resultCount;
  @override
  String get filterAll => _strings.filterAll;
  @override
  String get filterExpenses => _strings.filterExpenses;
  @override
  String get filterIncomes => _strings.filterIncomes;
  @override
  String get clearFilters => _strings.clearFilters;

  @override
  String accountFilterLabel(String name) => _strings.accountFilterLabel(name);

  @override
  String dateGroupLabel(int day, String month) =>
      _strings.dateGroupLabel(day, month);

  @override
  String get advancedFiltersTitle => _strings.advancedFiltersTitle;
  @override
  String get selectDate => _strings.selectDate;
  @override
  String get paymentMethodLabel => _strings.paymentMethodLabel;
  @override
  String get applyFilters => _strings.applyFilters;
  @override
  String get noTransactionsYet => _strings.noTransactionsYet;
  @override
  String get registerFirstTransaction => _strings.registerFirstTransaction;
  @override
  String get noResultsFound => _strings.noResultsFound;

  @override
  String noResultsMatching(String query) => _strings.noResultsMatching(query);

  @override
  String get noResultsWithFilters => _strings.noResultsWithFilters;
  @override
  String get transactionDeleted => _strings.transactionDeleted;
  @override
  String get undo => _strings.undo;
  @override
  String get deleteConfirmTitle => _strings.deleteConfirmTitle;
  @override
  String get deleteConfirmContent => _strings.deleteConfirmContent;
  @override
  String get pendingSync => _strings.pendingSync;
  @override
  String get moreItems => _strings.moreItems;

  @override
  String transactionSemantics({
    required bool isExpense,
    required String category,
    required String amount,
    required String? description,
    required String date,
    required bool pending,
  }) => _strings.transactionSemantics(
    isExpense: isExpense,
    category: category,
    amount: amount,
    description: description,
    date: date,
    pending: pending,
  );

  @override
  String newLabel(int count) => _strings.newLabel(count);
  @override
  String newLabelO(int count) => _strings.newLabelO(count);
  @override
  String transactionCountLabel(int count) =>
      _strings.transactionCountLabel(count);
  @override
  String connectedLabel(int count) => _strings.connectedLabel(count);

  @override
  String get syncPsd2Info => _strings.syncPsd2Info;
  @override
  String get connectAccount => _strings.connectAccount;
  @override
  String get noConnectedAccounts => _strings.noConnectedAccounts;
  @override
  String get connectBankForSync => _strings.connectBankForSync;
  @override
  String get totalBankBalance => _strings.totalBankBalance;
  @override
  String get disconnectBank => _strings.disconnectBank;
  @override
  String get disconnectWarningTitle => _strings.disconnectWarningTitle;
  @override
  String get disconnectHistoryKept => _strings.disconnectHistoryKept;
  @override
  String get disconnectSyncStop => _strings.disconnectSyncStop;
  @override
  String get disconnectRevokeAccess => _strings.disconnectRevokeAccess;

  @override
  String get usageByPaymentMethod => _strings.usageByPaymentMethod;
  @override
  String get importingTransactions => _strings.importingTransactions;
  @override
  String get syncingPsd2 => _strings.syncingPsd2;
  @override
  String get justNow => _strings.justNow;
  @override
  String agoDays(int days) => _strings.agoDays(days);
  @override
  String agoMins(int min) => _strings.agoMins(min);
  @override
  String agoHours(int hour) => _strings.agoHours(hour);
  @override
  String get lastSync => _strings.lastSync;
  @override
  String get synchronize => _strings.synchronize;
  @override
  String get viewTransactions => _strings.viewTransactions;
  @override
  String get editCards => _strings.editCards;

  @override
  String get noCardsAdd => _strings.noCardsAdd;
  @override
  String get exampleCardName => _strings.exampleCardName;

  @override
  String get assistantOnlineStatus => _strings.assistantOnlineStatus;
  @override
  String get pinchToZoom => _strings.pinchToZoom;
  @override
  String get seeRecommendations => _strings.seeRecommendations;
  @override
  String get typeYourQuestion => _strings.typeYourQuestion;
  @override
  String get assistantConnectionError => _strings.assistantConnectionError;
  @override
  String get affordabilityYes => _strings.affordabilityYes;
  @override
  String get affordabilityNo => _strings.affordabilityNo;
  @override
  String get affordabilityMaybe => _strings.affordabilityMaybe;
  @override
  String get availableBalanceLabel => _strings.availableBalanceLabel;
  @override
  String get balanceAfterPurchase => _strings.balanceAfterPurchase;
  @override
  String get exampleOfDescription => _strings.exampleOfDescription;
  @override
  String get monthlySurplusLabel => _strings.monthlySurplusLabel;
  @override
  String get couldSaveIn => _strings.couldSaveIn;
  @override
  String get impactOnGoalsLabel => _strings.impactOnGoalsLabel;
  @override
  String get noImpactLabel => _strings.noImpactLabel;
  @override
  String get alternativesLabel => _strings.alternativesLabel;
  @override
  String get predictionsAI => _strings.predictionsAI;
  @override
  String get subtitleAI => _strings.subtitleAI;
  @override
  String get finnAsisstant => _strings.finnAsisstant;
  @override
  String get subtitleFinn => _strings.subtitleFinn;
  @override
  String get lastTransactions => _strings.lastTransactions;
  @override
  String get noLinkedAccounts => _strings.noLinkedAccounts;
  @override
  String get cardBankAccount => _strings.cardBankAccount;
  @override
  String get noCardsInAccount => _strings.noCardsInAccount;
  @override
  String get selectCardOptional => _strings.selectCardOptional;
  @override
  String get receiptPhoto => _strings.receiptPhoto;
  @override
  String get addReceiptPhoto => _strings.addReceiptPhoto;
  @override
  String get change => _strings.change;
  @override
  String get transactionRecorded => _strings.transactionRecorded;
  @override
  String get saveTransaction => _strings.saveTransaction;

  @override
  String get paymentCash => _strings.paymentCash;
  @override
  String get paymentDebit => _strings.paymentDebit;
  @override
  String get paymentCredit => _strings.paymentCredit;
  @override
  String get paymentPrepaid => _strings.paymentPrepaid;
  @override
  String get paymentTransfer => _strings.paymentTransfer;
  @override
  String get paymentDirectDebit => _strings.paymentDirectDebit;
  @override
  String get paymentCheque => _strings.paymentCheque;
  @override
  String get paymentVoucher => _strings.paymentVoucher;
  @override
  String get paymentCrypto => _strings.paymentCrypto;

  @override
  String get aiPredictionsTitle => _strings.aiPredictionsTitle;
  @override
  String get tabPrediction => _strings.tabPrediction;
  @override
  String get tabSavings => _strings.tabSavings;
  @override
  String get tabAnomalies => _strings.tabAnomalies;
  @override
  String get tabSubscriptions => _strings.tabSubscriptions;
  @override
  String get aiEmptyDataTitle => _strings.aiEmptyDataTitle;
  @override
  String get aiEmptyDataSubtitle => _strings.aiEmptyDataSubtitle;
  @override
  String get aiPredictionVsLastMonth => _strings.aiPredictionVsLastMonth;
  @override
  String get aiPreviousMonth => _strings.aiPreviousMonth;
  @override
  String get aiTrendIncreasing => _strings.aiTrendIncreasing;
  @override
  String get aiTrendDecreasing => _strings.aiTrendDecreasing;
  @override
  String get aiTrendStable => _strings.aiTrendStable;
  @override
  String get aiNextMonthPrediction => _strings.aiNextMonthPrediction;
  @override
  String aiRangeLabel(String min, String max) =>
      _strings.aiRangeLabel(min, max);
  @override
  String aiPreviousMonthLabel(String amount) =>
      _strings.aiPreviousMonthLabel(amount);
  @override
  String aiHistoryMonths(int count) => _strings.aiHistoryMonths(count);
  @override
  String aiModelsLabel(String models) => _strings.aiModelsLabel(models);
  @override
  String aiAnalyzedMonths(int count) => _strings.aiAnalyzedMonths(count);
  @override
  String get aiConfidenceLevel => _strings.aiConfidenceLevel;
  @override
  String get aiSavingsNoData => _strings.aiSavingsNoData;
  @override
  String get aiSavingsExcellentTitle => _strings.aiSavingsExcellentTitle;
  @override
  String get aiSavingsExcellentSubtitle => _strings.aiSavingsExcellentSubtitle;
  @override
  String get aiImprovementAreas => _strings.aiImprovementAreas;
  @override
  String get aiFinancialHealth => _strings.aiFinancialHealth;
  @override
  String get aiAvgIncome => _strings.aiAvgIncome;
  @override
  String get aiAvgExpense => _strings.aiAvgExpense;
  @override
  String get aiSavingsCapacity => _strings.aiSavingsCapacity;
  @override
  String get aiSavingsPotential => _strings.aiSavingsPotential;
  @override
  String get aiCurrent => _strings.aiCurrent;
  @override
  String get aiSuggested => _strings.aiSuggested;
  @override
  String get aiNoAnomaliesTitle => _strings.aiNoAnomaliesTitle;
  @override
  String get aiNoAnomaliesSubtitle => _strings.aiNoAnomaliesSubtitle;
  @override
  String get aiUnusualExpensesDetected => _strings.aiUnusualExpensesDetected;
  @override
  String get aiAnomaliesSummary => _strings.aiAnomaliesSummary;
  @override
  String get aiHighSeverity => _strings.aiHighSeverity;
  @override
  String get aiAnalyzedCategories => _strings.aiAnalyzedCategories;
  @override
  String get aiAnomalyExplanation => _strings.aiAnomalyExplanation;
  @override
  String aiNormalAverage(String amount) => _strings.aiNormalAverage(amount);
  @override
  String get aiNoSubscriptionsTitle => _strings.aiNoSubscriptionsTitle;
  @override
  String get aiNoSubscriptionsSubtitle => _strings.aiNoSubscriptionsSubtitle;
  @override
  String get aiRecurringExpensesDetected =>
      _strings.aiRecurringExpensesDetected;
  @override
  String aiAnnualCost(String amount) => _strings.aiAnnualCost(amount);
  @override
  String aiDetectedCount(int count) => _strings.aiDetectedCount(count);
  @override
  String get aiUpcomingCharges => _strings.aiUpcomingCharges;
  @override
  String get aiActiveSubscriptions => _strings.aiActiveSubscriptions;
  @override
  String aiOccurrences(int count) => _strings.aiOccurrences(count);
  @override
  String get aiNextCharge => _strings.aiNextCharge;
  @override
  String get aiPeriodWeekly => _strings.aiPeriodWeekly;
  @override
  String get aiPeriodMonthly => _strings.aiPeriodMonthly;
  @override
  String get aiPeriodQuarterly => _strings.aiPeriodQuarterly;
  @override
  String get aiPeriodAnnual => _strings.aiPeriodAnnual;
  @override
  String get aiErrorLoading => _strings.aiErrorLoading;
  @override
  String get aiServiceUnavailable => _strings.aiServiceUnavailable;
  @override
  String get aiCurrentLabel => _strings.aiCurrentLabel;
  @override
  String get aiSuggestedLabel => _strings.aiSuggestedLabel;
  @override
  String aiRecommendationSemantics(String category, String message) =>
      _strings.aiRecommendationSemantics(category, message);

  @override
  String get pmDebitCard => _strings.pmDebitCard;
  @override
  String get pmCreditCard => _strings.pmCreditCard;
  @override
  String get pmPrepaidCard => _strings.pmPrepaidCard;
  @override
  String get pmCard => _strings.pmCard;
  @override
  String get pmBankTransfer => _strings.pmBankTransfer;
  @override
  String get pmTransfer => _strings.pmTransfer;
  @override
  String get pmSepa => _strings.pmSepa;
  @override
  String get pmWire => _strings.pmWire;
  @override
  String get pmDirectDebit => _strings.pmDirectDebit;
  @override
  String get pmVoucher => _strings.pmVoucher;
  @override
  String get pmCrypto => _strings.pmCrypto;

  @override
  String get selectAccounts => _strings.selectAccounts;
  @override
  String get selectAllAccounts => _strings.selectAllAccounts;
  @override
  String get deselectAccounts => _strings.deselectAccounts;
  @override
  String get selectAtLeastOneAccount => _strings.selectAtLeastOneAccount;
  @override
  String get linkVerb => _strings.linkVerb;
  @override
  String get encryptedConnectionLabel => _strings.encryptedConnectionLabel;
  @override
  String get readOnlyLabel => _strings.readOnlyLabel;
  @override
  String get psd2CertifiedLabel => _strings.psd2CertifiedLabel;
  @override
  String get connectingBankTitle => _strings.connectingBankTitle;
  @override
  String get openingBrowserMsg => _strings.openingBrowserMsg;
  @override
  String get bankOpeningTitle => _strings.bankOpeningTitle;
  @override
  String get bankWaitingAuthTitle => _strings.bankWaitingAuthTitle;
  @override
  String get bankAuthCompleteInBrowserMsg =>
      _strings.bankAuthCompleteInBrowserMsg;
  @override
  String get bankAuthReturnMsg => _strings.bankAuthReturnMsg;
  @override
  String get bankInitiatingConnectionMsg =>
      _strings.bankInitiatingConnectionMsg;
  @override
  String get technicalSupport => _strings.technicalSupport;
  @override
  String get bankRetryConnection => _strings.bankRetryConnection;
  @override
  String get bankChooseOtherBank => _strings.bankChooseOtherBank;
  @override
  String get bankContactSupport => _strings.bankContactSupport;
  @override
  String get bankWhatYouCanDo => _strings.bankWhatYouCanDo;
  @override
  String get dontCloseAppMsg => _strings.dontCloseAppMsg;
  @override
  String get aiAnalysisLabel => _strings.aiAnalysisLabel;
  @override
  String get configureAccountMsg => _strings.configureAccountMsg;
  @override
  String get creditCardType => _strings.creditCardType;
  @override
  String get debitCardType => _strings.debitCardType;
  @override
  String get prepaidCardType => _strings.prepaidCardType;
  @override
  String get lastFourDigitsOptional => _strings.lastFourDigitsOptional;
  @override
  String get enterAccountNameError => _strings.enterAccountNameError;

  // ── Editar Perfil — campos adicionales ────────────────────────────────────
  @override
  String get phoneNumber => _strings.phoneNumber;
  @override
  String get profileBio => _strings.profileBio;
  @override
  String get languageAndCurrency => _strings.languageAndCurrency;
  @override
  String get preferencesSectionTitle => _strings.preferencesSectionTitle;

  // ── Biometría — mensajes de snackbar ──────────────────────────────────────
  @override
  String biometricActivatedMsg(String label) =>
      _strings.biometricActivatedMsg(label);
  @override
  String get biometricCancelledMsg => _strings.biometricCancelledMsg;
  @override
  String get biometricDeactivatedMsg => _strings.biometricDeactivatedMsg;
  @override
  String biometricSetupDeviceMsg(String label) =>
      _strings.biometricSetupDeviceMsg(label);
  @override
  String get biometricErrorMsg => _strings.biometricErrorMsg;

  // ── Moneda — mensajes ─────────────────────────────────────────────────────
  @override
  String currencyChangedMsg(String code, String symbol) =>
      _strings.currencyChangedMsg(code, symbol);

  @override
  String get actionConsentUpdated => _strings.actionConsentUpdated;

  @override
  String get actionConsentWithdrawn => _strings.actionConsentWithdrawn;

  @override
  String get actionInitialRegistration => _strings.actionInitialRegistration;

  @override
  String get addTicketPhoto => _strings.addTicketPhoto;

  @override
  String aiPredictionSemantics(String category, String amount) =>
      _strings.aiPredictionSemantics(category, amount);

  @override
  String get amountExceedsMax => _strings.amountExceedsMax;

  @override
  String get amountInvalidPositive => _strings.amountInvalidPositive;

  @override
  String get analyzeWithAI => _strings.analyzeWithAI;

  @override
  String get analyzingLabel => _strings.analyzingLabel;

  @override
  String get anomaliesIntroDesc => _strings.anomaliesIntroDesc;

  @override
  String get anomaliesIntroTitle => _strings.anomaliesIntroTitle;

  @override
  String get authorizeContinue => _strings.authorizeContinue;

  @override
  String get balanceRecalculateNote => _strings.balanceRecalculateNote;

  @override
  String get bankAccountBalanceLabel => _strings.bankAccountBalanceLabel;

  @override
  String get bankAccountInfoLabel => _strings.bankAccountInfoLabel;

  @override
  List<String> get bankCancelledSteps => _strings.bankCancelledSteps;

  @override
  String get bankCancelledTitle => _strings.bankCancelledTitle;

  @override
  String get bankConsentsLoadError => _strings.bankConsentsLoadError;

  @override
  String get bankConsentsTitle => _strings.bankConsentsTitle;

  @override
  String get bankFallbackName => _strings.bankFallbackName;

  @override
  List<String> get bankMaxAttemptsSteps => _strings.bankMaxAttemptsSteps;

  @override
  String get bankMaxAttemptsTitle => _strings.bankMaxAttemptsTitle;

  @override
  List<String> get bankNoInternetSteps => _strings.bankNoInternetSteps;

  @override
  String get bankNoInternetTitle => _strings.bankNoInternetTitle;

  @override
  List<String> get bankPermissionDeniedSteps =>
      _strings.bankPermissionDeniedSteps;

  @override
  String get bankPermissionDeniedTitle => _strings.bankPermissionDeniedTitle;

  @override
  List<String> get bankServiceUnavailSteps => _strings.bankServiceUnavailSteps;

  @override
  String get bankServiceUnavailTitle => _strings.bankServiceUnavailTitle;

  @override
  List<String> get bankSessionExpiredSteps => _strings.bankSessionExpiredSteps;

  @override
  String get bankSessionExpiredTitle => _strings.bankSessionExpiredTitle;

  @override
  String get bankSupportContactMsg => _strings.bankSupportContactMsg;

  @override
  List<String> get bankSyncFailedSteps => _strings.bankSyncFailedSteps;

  @override
  String get bankSyncFailedTitle => _strings.bankSyncFailedTitle;

  @override
  List<String> get bankTimeoutSteps => _strings.bankTimeoutSteps;

  @override
  String get bankTimeoutTitle => _strings.bankTimeoutTitle;

  @override
  String get bankTransactionsLabel => _strings.bankTransactionsLabel;

  @override
  List<String> get bankUnknownErrorSteps => _strings.bankUnknownErrorSteps;

  @override
  String get bankUnknownErrorTitle => _strings.bankUnknownErrorTitle;

  @override
  String get camera => _strings.camera;

  @override
  String get cancelGoal => _strings.cancelGoal;

  @override
  String get cancelGoalConfirm => _strings.cancelGoalConfirm;

  @override
  String cancelGoalContent(String name) => _strings.cancelGoalContent(name);

  @override
  String get cancelGoalTitle => _strings.cancelGoalTitle;

  @override
  String get cashAccountName => _strings.cashAccountName;

  @override
  String get categoriesTitle => _strings.categoriesTitle;

  @override
  String get categoryDeleted => _strings.categoryDeleted;

  @override
  String get chatOnFinoraLabel => _strings.chatOnFinoraLabel;

  @override
  String get chooseBankTitle => _strings.chooseBankTitle;

  @override
  String get color => _strings.color;

  @override
  String get configureGeminiKey => _strings.configureGeminiKey;

  @override
  String get confirmChanges => _strings.confirmChanges;

  @override
  String get confirmContribution => _strings.confirmContribution;

  @override
  String get confirmSaveChangesQuestion => _strings.confirmSaveChangesQuestion;

  @override
  String get consentExpiredWarning => _strings.consentExpiredWarning;

  @override
  String consentExpiresWarning(int days) =>
      _strings.consentExpiresWarning(days);

  @override
  String consentRenewedMsg(String bankName) =>
      _strings.consentRenewedMsg(bankName);

  @override
  String consentRevokedMsg(String bankName) =>
      _strings.consentRevokedMsg(bankName);

  @override
  String get consentTypeAnalytics => _strings.consentTypeAnalytics;

  @override
  String get consentTypeDataProcessing => _strings.consentTypeDataProcessing;

  @override
  String get consentTypeEssential => _strings.consentTypeEssential;

  @override
  String get consentTypeMarketing => _strings.consentTypeMarketing;

  @override
  String get consentTypePersonalization => _strings.consentTypePersonalization;

  @override
  String get consentTypeThirdParty => _strings.consentTypeThirdParty;

  @override
  String get contributionAdded => _strings.contributionAdded;

  @override
  String get contributionLabel => _strings.contributionLabel;

  @override
  String get contributions => _strings.contributions;

  @override
  String get createCategory => _strings.createCategory;

  @override
  String get createFirstCategory => _strings.createFirstCategory;

  @override
  String daysCount(int n) => _strings.daysCount(n);

  @override
  String get deleteAccountGdprNote => _strings.deleteAccountGdprNote;

  @override
  String get deleteAccountWarningItems => _strings.deleteAccountWarningItems;

  @override
  String get deleteAccountWarningTitle => _strings.deleteAccountWarningTitle;

  @override
  String get deleteCategory => _strings.deleteCategory;

  @override
  String deleteCategoryConfirm(String name) =>
      _strings.deleteCategoryConfirm(name);

  @override
  String get deleteCategoryWarning => _strings.deleteCategoryWarning;

  @override
  String get deleteConfirmInstruction => _strings.deleteConfirmInstruction;

  @override
  String get deleteContributionTitle => _strings.deleteContributionTitle;

  @override
  String get deletePhoto => _strings.deletePhoto;

  @override
  String get deleteTransactionConfirmContent =>
      _strings.deleteTransactionConfirmContent;

  @override
  String get descriptionHint => _strings.descriptionHint;

  @override
  String get editCategory => _strings.editCategory;

  @override
  String get enterAmount => _strings.enterAmount;

  @override
  String get enterPositiveAmount => _strings.enterPositiveAmount;

  @override
  String get errorDeletingAccount => _strings.errorDeletingAccount;

  @override
  String get errorExportingData => _strings.errorExportingData;

  @override
  String get errorLoadingBanks => _strings.errorLoadingBanks;

  @override
  String get errorLoadingCategories => _strings.errorLoadingCategories;

  @override
  String get errorRenewing => _strings.errorRenewing;

  @override
  String get errorRevoking => _strings.errorRevoking;

  @override
  String get expiresAtLabel => _strings.expiresAtLabel;

  @override
  String get expiresInLabel => _strings.expiresInLabel;

  @override
  String get exportDataDesc => _strings.exportDataDesc;

  @override
  String get exportDataIncludesLabel => _strings.exportDataIncludesLabel;

  @override
  String get exportDataItem1 => _strings.exportDataItem1;

  @override
  String get exportDataItem2 => _strings.exportDataItem2;

  @override
  String get exportDataItem3 => _strings.exportDataItem3;

  @override
  String get exportDataItem4 => _strings.exportDataItem4;

  @override
  String get exportResultNote => _strings.exportResultNote;

  @override
  String get gallery => _strings.gallery;

  @override
  String get gdprComplianceDesc => _strings.gdprComplianceDesc;

  @override
  String get geminiKeyConfigured => _strings.geminiKeyConfigured;

  @override
  String get geminiKeyDescription => _strings.geminiKeyDescription;

  @override
  String get geminiKeyRemoved => _strings.geminiKeyRemoved;

  @override
  String get geminiKeyTitle => _strings.geminiKeyTitle;

  @override
  String get goalAiHint => _strings.goalAiHint;

  @override
  String goalAmountOf(String current, String target) =>
      _strings.goalAmountOf(current, target);

  @override
  String get goalAmountPositive => _strings.goalAmountPositive;

  @override
  String get goalAmountRequired => _strings.goalAmountRequired;

  @override
  String get goalAnalyzeAndCreate => _strings.goalAnalyzeAndCreate;

  @override
  List<String> get goalCategoriesList => _strings.goalCategoriesList;

  @override
  String get goalCategoryOptional => _strings.goalCategoryOptional;

  @override
  String goalCompletedCount(int n) => _strings.goalCompletedCount(n);

  @override
  String goalDeadlineDate(String date) => _strings.goalDeadlineDate(date);

  @override
  String get goalDeadlineOptional => _strings.goalDeadlineOptional;

  @override
  String get goalDifficultLabel => _strings.goalDifficultLabel;

  @override
  String get goalFeasibleLabel => _strings.goalFeasibleLabel;

  @override
  String get goalIconLabel => _strings.goalIconLabel;

  @override
  String goalInProgress(int n) => _strings.goalInProgress(n);

  @override
  String goalMonthlySuggested(String amount) =>
      _strings.goalMonthlySuggested(amount);

  @override
  String get goalNameRequired => _strings.goalNameRequired;

  @override
  String get goalNoDeadline => _strings.goalNoDeadline;

  @override
  String get goalNotViableLabel => _strings.goalNotViableLabel;

  @override
  String get goalNoteHint => _strings.goalNoteHint;

  @override
  String get goalNoteOptional => _strings.goalNoteOptional;

  @override
  String goalRemainingAmount(String amount) =>
      _strings.goalRemainingAmount(amount);

  @override
  String get goalSelectCategory => _strings.goalSelectCategory;

  @override
  String get goalTargetAmountLabel => _strings.goalTargetAmountLabel;

  @override
  String get grantedPermissionsLabel => _strings.grantedPermissionsLabel;

  @override
  String get icon => _strings.icon;

  @override
  String get labelProjection => _strings.labelProjection;

  @override
  String get labelSaved => _strings.labelSaved;

  @override
  String lastModified(String date) => _strings.lastModified(date);

  @override
  String get modified => _strings.modified;

  @override
  String get nameLabel => _strings.nameLabel;

  @override
  String get nameTooLong => _strings.nameTooLong;

  @override
  String get newCategory => _strings.newCategory;

  @override
  String get no => _strings.no;

  @override
  String get noActiveConsents => _strings.noActiveConsents;

  @override
  String get noActiveConsentsDesc => _strings.noActiveConsentsDesc;

  @override
  String get noBanksFound => _strings.noBanksFound;

  @override
  String get noCategoriesExpense => _strings.noCategoriesExpense;

  @override
  String get noCategoriesIncome => _strings.noCategoriesIncome;

  @override
  String get noChangesMsg => _strings.noChangesMsg;

  @override
  String get noContributionsYet => _strings.noContributionsYet;

  @override
  String get noDataStoredLabel => _strings.noDataStoredLabel;

  @override
  String get noLinkedBankAccount => _strings.noLinkedBankAccount;

  @override
  String get originAccount => _strings.originAccount;

  @override
  String get permanentActionWarning => _strings.permanentActionWarning;

  @override
  String get predefined => _strings.predefined;

  @override
  String get predictionIntroDesc => _strings.predictionIntroDesc;

  @override
  String get predictionIntroTitle => _strings.predictionIntroTitle;

  @override
  String get psd2AccountInfoDesc => _strings.psd2AccountInfoDesc;

  @override
  String get psd2BalanceDesc => _strings.psd2BalanceDesc;

  @override
  String get psd2ConsentLabel => _strings.psd2ConsentLabel;

  @override
  String get psd2ConsentNote => _strings.psd2ConsentNote;

  @override
  String get psd2RenewalInfoMsg => _strings.psd2RenewalInfoMsg;

  @override
  String get psd2RequestsAccess => _strings.psd2RequestsAccess;

  @override
  String psd2SecureAccessTo(String bankName) =>
      _strings.psd2SecureAccessTo(bankName);

  @override
  String get psd2TransactionsDesc => _strings.psd2TransactionsDesc;

  @override
  String get readOnlyAccountsLabel => _strings.readOnlyAccountsLabel;

  @override
  String get reasonOptionalHint => _strings.reasonOptionalHint;

  @override
  String get recategorizeAll => _strings.recategorizeAll;

  @override
  String recategorizeSimilarMsg(String category) =>
      _strings.recategorizeSimilarMsg(category);

  @override
  String get refreshPredictions => _strings.refreshPredictions;

  @override
  String get registrationDateLabel => _strings.registrationDateLabel;

  @override
  String get renew => _strings.renew;

  @override
  String get renew90Days => _strings.renew90Days;

  @override
  String get renewConsent => _strings.renewConsent;

  @override
  String renewConsentContent(String bankName) =>
      _strings.renewConsentContent(bankName);

  @override
  String get renewalRequired => _strings.renewalRequired;

  @override
  String get revokeAccess => _strings.revokeAccess;

  @override
  String revokeConsentContent(String bankName) =>
      _strings.revokeConsentContent(bankName);

  @override
  String get revokeConsentTitle => _strings.revokeConsentTitle;

  @override
  String get revokeLabel => _strings.revokeLabel;

  @override
  String get saveChanges => _strings.saveChanges;

  @override
  String get savingsIntroDesc => _strings.savingsIntroDesc;

  @override
  String get savingsIntroTitle => _strings.savingsIntroTitle;

  @override
  String get searchBankHint => _strings.searchBankHint;

  @override
  String get securePsd2Connection => _strings.securePsd2Connection;

  @override
  String get selectCategoryHint => _strings.selectCategoryHint;

  @override
  String get selectFromGallery => _strings.selectFromGallery;

  @override
  String get skipTutorial => _strings.skipTutorial;

  @override
  String get statusActive => _strings.statusActive;

  @override
  String get statusExpired => _strings.statusExpired;

  @override
  String get statusRevoked => _strings.statusRevoked;

  @override
  String get subscriptionsIntroDesc => _strings.subscriptionsIntroDesc;

  @override
  String get subscriptionsIntroTitle => _strings.subscriptionsIntroTitle;

  @override
  String get suggestedByHistory => _strings.suggestedByHistory;

  @override
  String get takePictureNow => _strings.takePictureNow;

  @override
  String get ticketPhoto => _strings.ticketPhoto;

  @override
  String get tlsEncryptedLabel => _strings.tlsEncryptedLabel;

  @override
  String get transactionUpdated => _strings.transactionUpdated;

  @override
  String get transactionsLabel => _strings.transactionsLabel;

  @override
  String get tutorialStart => _strings.tutorialStart;

  @override
  String get tutorialStep1Desc => _strings.tutorialStep1Desc;

  @override
  String get tutorialStep1Title => _strings.tutorialStep1Title;

  @override
  String get tutorialStep2Desc => _strings.tutorialStep2Desc;

  @override
  String get tutorialStep2Title => _strings.tutorialStep2Title;

  @override
  String get tutorialStep3Desc => _strings.tutorialStep3Desc;

  @override
  String get tutorialStep3Title => _strings.tutorialStep3Title;

  @override
  String get tutorialStep4Desc => _strings.tutorialStep4Desc;

  @override
  String get tutorialStep4Title => _strings.tutorialStep4Title;

  @override
  String get tutorialStep5Desc => _strings.tutorialStep5Desc;

  @override
  String get tutorialStep5Title => _strings.tutorialStep5Title;

  @override
  String get errorExportExcel => _strings.errorExportExcel;

  @override
  String get exportExcel => _strings.exportExcel;

  @override
  String get exportExcelSubtitle => _strings.exportExcelSubtitle;

  @override
  String get addDebt => _strings.addDebt;

  @override
  String get addSharedExpense => _strings.addSharedExpense;

  @override
  String get aiSuggestBudgetsBtn => _strings.aiSuggestBudgetsBtn;

  @override
  String get aiSuggestBudgetsInfo => _strings.aiSuggestBudgetsInfo;

  @override
  String get aiSuggestBudgetsTitle => _strings.aiSuggestBudgetsTitle;

  @override
  String get allocation => _strings.allocation;

  @override
  String get annualIncomeLabel => _strings.annualIncomeLabel;

  @override
  String get annualRate => _strings.annualRate;

  @override
  String get applyAllSuggestions => _strings.applyAllSuggestions;

  @override
  String get attachReceipt => _strings.attachReceipt;

  @override
  String get avalancheDesc => _strings.avalancheDesc;

  @override
  String get avalancheStrategy => _strings.avalancheStrategy;

  @override
  String get badgesEarned => _strings.badgesEarned;

  @override
  String get badgesLocked => _strings.badgesLocked;

  @override
  String get badgesTitle => _strings.badgesTitle;

  @override
  String get balanceSettled => _strings.balanceSettled;

  @override
  String get balancesTab => _strings.balancesTab;

  @override
  String get benchmarkDesc => _strings.benchmarkDesc;

  @override
  String get benchmarkTitle => _strings.benchmarkTitle;

  @override
  String get budgetComparativeTab => _strings.budgetComparativeTab;

  @override
  String get budgetComplianceComponent => _strings.budgetComplianceComponent;

  @override
  String get budgetTrendDown => _strings.budgetTrendDown;

  @override
  String get budgetTrendUp => _strings.budgetTrendUp;

  @override
  String get calculate => _strings.calculate;

  @override
  String get challengeComplete => _strings.challengeComplete;

  @override
  String get challengesTitle => _strings.challengesTitle;

  @override
  String get confirmTransaction => _strings.confirmTransaction;

  @override
  String get createHousehold => _strings.createHousehold;

  @override
  String get creditorName => _strings.creditorName;

  @override
  String get debtDeleted => _strings.debtDeleted;

  @override
  String get debtName => _strings.debtName;

  @override
  String get debtSaved => _strings.debtSaved;

  @override
  String get debtTypeOwed => _strings.debtTypeOwed;

  @override
  String get debtTypeOwn => _strings.debtTypeOwn;

  @override
  String get debtsNav => _strings.debtsNav;

  @override
  String get debtsTitle => _strings.debtsTitle;

  @override
  String get deductibleExpensesTab => _strings.deductibleExpensesTab;

  @override
  String get deductionsLabel => _strings.deductionsLabel;

  @override
  String get deleteDebt => _strings.deleteDebt;

  @override
  String get deleteDebtConfirm => _strings.deleteDebtConfirm;

  @override
  String get deselectAll => _strings.deselectAll;

  @override
  String get dueDate => _strings.dueDate;

  @override
  String get duplicateWarning => _strings.duplicateWarning;

  @override
  String get duplicatesFound => _strings.duplicatesFound;

  @override
  String get editDebt => _strings.editDebt;

  @override
  String get effectiveRate => _strings.effectiveRate;

  @override
  String get estimatedTax => _strings.estimatedTax;

  @override
  String get etfName => _strings.etfName;

  @override
  String get expectedReturn => _strings.expectedReturn;

  @override
  String get exportFiscalBtn => _strings.exportFiscalBtn;

  @override
  String get exportFiscalDesc => _strings.exportFiscalDesc;

  @override
  String get exportFiscalTab => _strings.exportFiscalTab;

  @override
  String get extraPaymentLabel => _strings.extraPaymentLabel;

  @override
  String get extractedAmount => _strings.extractedAmount;

  @override
  String get extractedData => _strings.extractedData;

  @override
  String get extractedDate => _strings.extractedDate;

  @override
  String get extractedMerchant => _strings.extractedMerchant;

  @override
  String get finalAmount => _strings.finalAmount;

  @override
  String get fiscalCategoryCapitalGain => _strings.fiscalCategoryCapitalGain;

  @override
  String get fiscalCategoryDonation => _strings.fiscalCategoryDonation;

  @override
  String get fiscalCategoryFreelance => _strings.fiscalCategoryFreelance;

  @override
  String get fiscalCategoryLabel => _strings.fiscalCategoryLabel;

  @override
  String get fiscalCategoryOther => _strings.fiscalCategoryOther;

  @override
  String get fiscalDataExported => _strings.fiscalDataExported;

  @override
  String get fiscalNav => _strings.fiscalNav;

  @override
  String get fiscalTitle => _strings.fiscalTitle;

  @override
  String get fiscalYear => _strings.fiscalYear;

  @override
  String get fromCamera => _strings.fromCamera;

  @override
  String get fromGallery => _strings.fromGallery;

  @override
  String get gamificationNav => _strings.gamificationNav;

  @override
  String get gamificationTitle => _strings.gamificationTitle;

  @override
  String get glossaryTitle => _strings.glossaryTitle;

  @override
  String get goalsProgressComponent => _strings.goalsProgressComponent;

  @override
  String get healthScore => _strings.healthScore;

  @override
  String get healthScoreBreakdown => _strings.healthScoreBreakdown;

  @override
  String get householdCreated => _strings.householdCreated;

  @override
  String get householdName => _strings.householdName;

  @override
  String get householdNav => _strings.householdNav;

  @override
  String get householdOverview => _strings.householdOverview;

  @override
  String get householdRole => _strings.householdRole;

  @override
  String get householdTitle => _strings.householdTitle;

  @override
  String get importConfirmed => _strings.importConfirmed;

  @override
  String get importSelected => _strings.importSelected;

  @override
  String get importStatement => _strings.importStatement;

  @override
  String get importStatementDesc => _strings.importStatementDesc;

  @override
  String get importedTransactions => _strings.importedTransactions;

  @override
  String get interestRate => _strings.interestRate;

  @override
  String get interestSavings => _strings.interestSavings;

  @override
  String get investmentHorizon => _strings.investmentHorizon;

  @override
  String get investmentYears => _strings.investmentYears;

  @override
  String get investmentsNav => _strings.investmentsNav;

  @override
  String get investmentsTitle => _strings.investmentsTitle;

  @override
  String get investorProfileTab => _strings.investorProfileTab;

  @override
  String get inviteByEmail => _strings.inviteByEmail;

  @override
  String get inviteCode => _strings.inviteCode;

  @override
  String get inviteMember => _strings.inviteMember;

  @override
  String get irpfTab => _strings.irpfTab;

  @override
  String get joinWithCode => _strings.joinWithCode;

  @override
  String get last3Months => _strings.last3Months;

  @override
  String get leaveHousehold => _strings.leaveHousehold;

  @override
  String get loanCalculator => _strings.loanCalculator;

  @override
  String get longTerm => _strings.longTerm;

  @override
  String get longestStreak => _strings.longestStreak;

  @override
  String get marketIndices => _strings.marketIndices;

  @override
  String get marketsTab => _strings.marketsTab;

  @override
  String get mediumTerm => _strings.mediumTerm;

  @override
  String get memberInvited => _strings.memberInvited;

  @override
  String get memberRole => _strings.memberRole;

  @override
  String get membersTab => _strings.membersTab;

  @override
  String get monthlyCapacity => _strings.monthlyCapacity;

  @override
  String get monthlyChallenge => _strings.monthlyChallenge;

  @override
  String get monthlyInvestment => _strings.monthlyInvestment;

  @override
  String get monthlyPayment => _strings.monthlyPayment;

  @override
  String get monthlyPaymentResult => _strings.monthlyPaymentResult;

  @override
  String get monthsToPayoff => _strings.monthsToPayoff;

  @override
  String get mortgageCalculator => _strings.mortgageCalculator;

  @override
  String get netIncome => _strings.netIncome;

  @override
  String get noDebts => _strings.noDebts;

  @override
  String get noFiscalData => _strings.noFiscalData;

  @override
  String get noHistoryData => _strings.noHistoryData;

  @override
  String get noHousehold => _strings.noHousehold;

  @override
  String get noProfile => _strings.noProfile;

  @override
  String get noStreakYet => _strings.noStreakYet;

  @override
  String get noTextDetected => _strings.noTextDetected;

  @override
  String get ocrNav => _strings.ocrNav;

  @override
  String get ocrTitle => _strings.ocrTitle;

  @override
  String get originalAmount => _strings.originalAmount;

  @override
  String get overviewTab => _strings.overviewTab;

  @override
  String get owedToMeTab => _strings.owedToMeTab;

  @override
  String get owesYou => _strings.owesYou;

  @override
  String get ownDebtsTab => _strings.ownDebtsTab;

  @override
  String get ownerRole => _strings.ownerRole;

  @override
  String get paymentOrder => _strings.paymentOrder;

  @override
  String get portfolioRationale => _strings.portfolioRationale;

  @override
  String get portfolioTab => _strings.portfolioTab;

  @override
  String get principal => _strings.principal;

  @override
  String get profileAggressive => _strings.profileAggressive;

  @override
  String get profileAggressiveDesc => _strings.profileAggressiveDesc;

  @override
  String get profileConservative => _strings.profileConservative;

  @override
  String get profileConservativeDesc => _strings.profileConservativeDesc;

  @override
  String get profileModerate => _strings.profileModerate;

  @override
  String get profileModerateDesc => _strings.profileModerateDesc;

  @override
  String get profileRequired => _strings.profileRequired;

  @override
  String get profileSaved => _strings.profileSaved;

  @override
  String get quizTitle => _strings.quizTitle;

  @override
  String get receiptAttached => _strings.receiptAttached;

  @override
  String get receiptImported => _strings.receiptImported;

  @override
  String get recommendedStrategy => _strings.recommendedStrategy;

  @override
  String get remainingAmount => _strings.remainingAmount;

  @override
  String get removeMember => _strings.removeMember;

  @override
  String get reviewImport => _strings.reviewImport;

  @override
  String get rolloverDisabled => _strings.rolloverDisabled;

  @override
  String get rolloverEnabled => _strings.rolloverEnabled;

  @override
  String get rolloverLabel => _strings.rolloverLabel;

  @override
  String get saveProfile => _strings.saveProfile;

  @override
  String get savingsRateComponent => _strings.savingsRateComponent;

  @override
  String get savingsWithExtra => _strings.savingsWithExtra;

  @override
  String get scanReceipt => _strings.scanReceipt;

  @override
  String get scanReceiptDesc => _strings.scanReceiptDesc;

  @override
  String get scanningReceipt => _strings.scanningReceipt;

  @override
  String get scoreExcellent => _strings.scoreExcellent;

  @override
  String get scoreFair => _strings.scoreFair;

  @override
  String get scoreGood => _strings.scoreGood;

  @override
  String get scorePoor => _strings.scorePoor;

  @override
  String get selectAll => _strings.selectAll;

  @override
  String get selectFile => _strings.selectFile;

  @override
  String get settleBalance => _strings.settleBalance;

  @override
  String get sharedTab => _strings.sharedTab;

  @override
  String get shortTerm => _strings.shortTerm;

  @override
  String get simulate => _strings.simulate;

  @override
  String get simulatorTab => _strings.simulatorTab;

  @override
  String get simulatorTitle => _strings.simulatorTitle;

  @override
  String get skipDuplicates => _strings.skipDuplicates;

  @override
  String get snowballDesc => _strings.snowballDesc;

  @override
  String get snowballStrategy => _strings.snowballStrategy;

  @override
  String get splitPercentage => _strings.splitPercentage;

  @override
  String get startQuizBtn => _strings.startQuizBtn;

  @override
  String get strategiesTab => _strings.strategiesTab;

  @override
  String get streakLabel => _strings.streakLabel;

  @override
  String get streakWeeks => _strings.streakWeeks;

  @override
  String get suggestedPortfolio => _strings.suggestedPortfolio;

  @override
  String get tagAsFiscal => _strings.tagAsFiscal;

  @override
  String get taxBrackets => _strings.taxBrackets;

  @override
  String get taxCalendarTab => _strings.taxCalendarTab;

  @override
  String get taxCalendarTitle => _strings.taxCalendarTitle;

  @override
  String get termMonths => _strings.termMonths;

  @override
  String get totalDeductible => _strings.totalDeductible;

  @override
  String get totalInterest => _strings.totalInterest;

  @override
  String get totalInvested => _strings.totalInvested;

  @override
  String get totalPayment => _strings.totalPayment;

  @override
  String get totalReturns => _strings.totalReturns;

  @override
  String get wearableConnected => _strings.wearableConnected;

  @override
  String get wearableInstructions => _strings.wearableInstructions;

  @override
  String get wearableNotConnected => _strings.wearableNotConnected;

  @override
  String get weeklyChallenge => _strings.weeklyChallenge;

  @override
  String get widgetAddInstructions => _strings.widgetAddInstructions;

  @override
  String get widgetAppleWatch => _strings.widgetAppleWatch;

  @override
  String get widgetBalance => _strings.widgetBalance;

  @override
  String get widgetBudgetPct => _strings.widgetBudgetPct;

  @override
  String get widgetDarkModeAuto => _strings.widgetDarkModeAuto;

  @override
  String get widgetLastUpdated => _strings.widgetLastUpdated;

  @override
  String get widgetMetricsLabel => _strings.widgetMetricsLabel;

  @override
  String get widgetNav => _strings.widgetNav;

  @override
  String get widgetSettingsTitle => _strings.widgetSettingsTitle;

  @override
  String get widgetTitle => _strings.widgetTitle;

  @override
  String get widgetTodaySpent => _strings.widgetTodaySpent;

  @override
  String get widgetWearOS => _strings.widgetWearOS;

  @override
  String get widgetWearableTitle => _strings.widgetWearableTitle;

  @override
  String get youOwe => _strings.youOwe;

  @override
  String get enterPassword => _strings.enterPassword;

  @override
  String get sectionAdvancedFinances => _strings.sectionAdvancedFinances;

  @override
  String get settingsDebts => _strings.settingsDebts;

  @override
  String get settingsDebtsSubtitle => _strings.settingsDebtsSubtitle;

  @override
  String get settingsInvestments => _strings.settingsInvestments;

  @override
  String get settingsInvestmentsSubtitle =>
      _strings.settingsInvestmentsSubtitle;

  @override
  String get settingsHousehold => _strings.settingsHousehold;

  @override
  String get settingsHouseholdSubtitle => _strings.settingsHouseholdSubtitle;

  @override
  String get joinChallenge => _strings.joinChallenge;

  @override
  String get settingsGamification => _strings.settingsGamification;

  @override
  String get settingsGamificationSubtitle =>
      _strings.settingsGamificationSubtitle;

  @override
  String get settingsFiscal => _strings.settingsFiscal;

  @override
  String get settingsFiscalSubtitle => _strings.settingsFiscalSubtitle;

  @override
  String get settingsOcr => _strings.settingsOcr;

  @override
  String get settingsOcrSubtitle => _strings.settingsOcrSubtitle;

  @override
  String get settingsWidget => _strings.settingsWidget;

  @override
  String get settingsWidgetSubtitle => _strings.settingsWidgetSubtitle;

  @override
  String get removeFiscalTag => _strings.removeFiscalTag;

  @override
  String get accountsSubtitle => _strings.accountsSubtitle;

  @override
  String get budgetSubtitle => _strings.budgetSubtitle;

  @override
  String get budgetTitle => _strings.budgetTitle;

  @override
  String get debtsSubtitle => _strings.debtsSubtitle;

  @override
  String get debtsTutorialStart => _strings.debtsTutorialStart;

  @override
  String get debtsTutorialStep1Body => _strings.debtsTutorialStep1Body;

  @override
  String get debtsTutorialStep1Title => _strings.debtsTutorialStep1Title;

  @override
  String get debtsTutorialStep2Body => _strings.debtsTutorialStep2Body;

  @override
  String get debtsTutorialStep2Title => _strings.debtsTutorialStep2Title;

  @override
  String get debtsTutorialStep3Body => _strings.debtsTutorialStep3Body;

  @override
  String get debtsTutorialStep3Title => _strings.debtsTutorialStep3Title;

  @override
  String get debtsTutorialStep4Body => _strings.debtsTutorialStep4Body;

  @override
  String get debtsTutorialStep4Title => _strings.debtsTutorialStep4Title;

  @override
  String get debtsTutorialTitle => _strings.debtsTutorialTitle;

  @override
  String get fiscalSubtitle => _strings.fiscalSubtitle;

  @override
  String get gamificationSubtitle => _strings.gamificationSubtitle;

  @override
  String get householdExpenseExplain => _strings.householdExpenseExplain;

  @override
  String get householdExpenseHowBody => _strings.householdExpenseHowBody;

  @override
  String get householdExpenseHowTitle => _strings.householdExpenseHowTitle;

  @override
  String get householdInviteInfo => _strings.householdInviteInfo;

  @override
  String get householdSubtitle => _strings.householdSubtitle;

  @override
  String get investmentsSubtitle => _strings.investmentsSubtitle;

  @override
  String get modules => _strings.modules;

  @override
  String get ocrSubtitle => _strings.ocrSubtitle;

  @override
  String get widgetSubtitle => _strings.widgetSubtitle;

  // ── Investments: real-time market data ─────────────────────────────────────
  @override
  String get volume24h => _strings.volume24h;

  @override
  String get marketCap => _strings.marketCap;

  @override
  String get high24h => _strings.high24h;

  @override
  String get low24h => _strings.low24h;

  @override
  String get sectionCrypto => _strings.sectionCrypto;

  @override
  String get sectionEquity => _strings.sectionEquity;

  @override
  String get sectionCommoditiesForex => _strings.sectionCommoditiesForex;

  @override
  String get lastUpdated => _strings.lastUpdated;

  @override
  String get chartStatsTitle => _strings.chartStatsTitle;

  @override
  String get refresh => _strings.refresh;

  @override
  String get allExpensesTitle => _strings.allExpensesTitle;

  @override
  String get markDeductible => _strings.markDeductible;

  @override
  String get exportSelectFormat => _strings.exportSelectFormat;

  @override
  String get exportXlsxDesc => _strings.exportXlsxDesc;

  @override
  String get exportCsvDesc => _strings.exportCsvDesc;

  @override
  String get exportShareTitle => _strings.exportShareTitle;

  @override
  String get wearableSyncBtn => _strings.wearableSyncBtn;

  @override
  String get wearableConnecting => _strings.wearableConnecting;

  @override
  String get widgetUpdateSuccess => _strings.widgetUpdateSuccess;

  @override
  String get fromFile => _strings.fromFile;
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(AppStrings.forLocale(locale.languageCode));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
