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
  String get nutrition => _strings.nutrition;
  @override
  String get transport => _strings.transport;
  @override
  String get leisure => _strings.leisure;
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
  String get fullName => _strings.fullName;
  @override
  String get nameRequired => _strings.nameRequired;
  @override
  String get nameHint => _strings.nameHint;
  @override
  String get confirmPasswordRequired => _strings.confirmPasswordRequired;
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
  String get downloadData => _strings.downloadData;

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
  String get newAccountTitle => _strings.newAccountTitle;
  @override
  String get accountTypeLabel => _strings.accountTypeLabel;
  @override
  String get ibanOptional => _strings.ibanOptional;
  @override
  String get saveAccountBtn => _strings.saveAccountBtn;
  @override
  String get addCardTitle => _strings.addCardTitle;
  @override
  String get selectCsvFile => _strings.selectCsvFile;
  @override
  String get dontCloseAppMsg => _strings.dontCloseAppMsg;
  @override
  String get aiAnalysisLabel => _strings.aiAnalysisLabel;
  @override
  String get configureAccountMsg => _strings.configureAccountMsg;
  @override
  String get cardsLabel => _strings.cardsLabel;
  @override
  String get noCardsOptional => _strings.noCardsOptional;
  @override
  String get importCsvLabel => _strings.importCsvLabel;
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
  @override
  String get csvImportDesc => _strings.csvImportDesc;
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
