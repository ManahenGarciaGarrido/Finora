# 🏦 Finora - Gestor de Finanzas Personales

**Aplicación móvil multiplataforma (Android/iOS) para gestión inteligente de finanzas personales con IA**

---

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#-descripción-del-proyecto)
- [Arquitectura del Proyecto](#-arquitectura-del-proyecto)
- [Estructura del Frontend](#-estructura-del-frontend)
- [Requisitos del Sistema](#-requisitos-del-sistema)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Instalación y Configuración](#-instalación-y-configuración)
- [Módulos y Funcionalidades](#-módulos-y-funcionalidades)
- [Backend](#-backend)
- [Roadmap](#-roadmap)

---

## 🎯 Descripción del Proyecto

Finora es una aplicación móvil desarrollada en **Flutter** que permite a los usuarios gestionar sus finanzas personales de manera inteligente mediante:

- Registro y seguimiento de transacciones
- Sincronización automática con entidades bancarias (PSD2)
- Categorización inteligente mediante IA
- Predicción de gastos con Machine Learning
- Asistente conversacional con IA generativa
- Objetivos de ahorro personalizados
- Análisis de affordability
- Visualizaciones interactivas

---

## 🏗️ Arquitectura del Proyecto

El proyecto sigue los principios de **Clean Architecture** con la siguiente estructura:

```
finora/
├── lib/
│   ├── core/                      # Funcionalidades compartidas
│   ├── features/                  # Módulos de la aplicación
│   ├── config/                    # Configuraciones
│   └── main.dart                  # Punto de entrada
├── test/                          # Tests unitarios e integración
├── assets/                        # Recursos estáticos
└── pubspec.yaml                   # Dependencias
```

---

## 📂 Estructura del Frontend

### 1️⃣ **Core (Funcionalidades Compartidas)**

#### `lib/core/`

```
core/
├── constants/
│   ├── app_constants.dart          # Constantes globales
│   ├── api_endpoints.dart          # Endpoints del backend
│   ├── storage_keys.dart           # Keys para almacenamiento local
│   └── theme_constants.dart        # Constantes de tema
│
├── theme/
│   ├── app_theme.dart              # Tema principal de la app
│   ├── app_colors.dart             # Paleta de colores
│   ├── app_text_styles.dart        # Estilos de texto
│   └── app_dimensions.dart         # Dimensiones y espaciados
│
├── utils/
│   ├── validators.dart             # Validadores de formularios
│   ├── formatters.dart             # Formateadores (fechas, moneda)
│   ├── currency_formatter.dart     # Formato de moneda
│   ├── date_formatter.dart         # Formato de fechas
│   ├── encryption_helper.dart      # Helpers para cifrado
│   ├── biometric_helper.dart       # Helper para biometría
│   └── logger.dart                 # Sistema de logs
│
├── errors/
│   ├── failures.dart               # Definición de errores
│   ├── exceptions.dart             # Excepciones personalizadas
│   └── error_handler.dart          # Manejador global de errores
│
├── network/
│   ├── api_client.dart             # Cliente HTTP base
│   ├── interceptors.dart           # Interceptores (auth, logs)
│   ├── network_info.dart           # Estado de conexión
│   └── ssl_pinning.dart            # SSL pinning para seguridad
│
├── storage/
│   ├── local_storage.dart          # SharedPreferences wrapper
│   ├── secure_storage.dart         # Flutter Secure Storage wrapper
│   ├── database/
│   │   ├── database_helper.dart    # SQLite helper
│   │   ├── database_schema.dart    # Esquema de BD local
│   │   └── migrations/             # Migraciones de BD
│   │       ├── migration_v1.dart
│   │       └── migration_v2.dart
│   └── cache_manager.dart          # Gestor de caché
│
├── widgets/
│   ├── custom_app_bar.dart         # AppBar personalizada
│   ├── custom_button.dart          # Botones reutilizables
│   ├── custom_text_field.dart      # Campos de texto
│   ├── loading_indicator.dart      # Indicadores de carga
│   ├── error_widget.dart           # Widget de error
│   ├── empty_state_widget.dart     # Estado vacío
│   ├── bottom_sheet_wrapper.dart   # Wrapper para bottom sheets
│   ├── card_wrapper.dart           # Cards personalizadas
│   └── accessibility/
│       ├── screen_reader_text.dart # Textos para lectores de pantalla
│       └── semantic_wrapper.dart   # Wrapper semántico WCAG
│
├── routes/
│   ├── app_router.dart             # Configuración de rutas
│   ├── route_names.dart            # Nombres de rutas
│   └── route_guards.dart           # Guards de autenticación
│
├── localization/
│   ├── app_localizations.dart      # Sistema de i18n
│   ├── localization_delegate.dart  # Delegate de localización
│   └── translations/
│       ├── es.json                 # Español
│       ├── en.json                 # Inglés
│       └── fr.json                 # Francés
│
└── di/
    └── injection_container.dart    # Inyección de dependencias (get_it)
```

**Requisitos cubiertos:**
- `RNF-01`: Cifrado de datos en tránsito (api_client.dart, ssl_pinning.dart)
- `RNF-02`: Cifrado de datos sensibles en reposo (secure_storage.dart, encryption_helper.dart)
- `RNF-11`: Accesibilidad WCAG 2.1 AA (accessibility/)
- `RNF-12`: Diseño responsive (app_dimensions.dart, app_theme.dart)
- `RNF-13`: Localización e internacionalización (localization/)
- `RNF-15`: Funcionamiento offline (local_storage.dart, database_helper.dart, cache_manager.dart)
- `RNF-22`: Arquitectura limpia y modular (estructura completa)

---

### 2️⃣ **Feature: Autenticación**

#### `lib/features/authentication/`

```
authentication/
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart     # API de autenticación
│   │   └── auth_local_datasource.dart      # Datos locales (token, sesión)
│   ├── models/
│   │   ├── user_model.dart                 # Modelo de usuario
│   │   ├── login_request_model.dart
│   │   ├── login_response_model.dart
│   │   ├── register_request_model.dart
│   │   └── password_reset_model.dart
│   └── repositories/
│       └── auth_repository_impl.dart       # Implementación del repositorio
│
├── domain/
│   ├── entities/
│   │   └── user.dart                       # Entidad de usuario
│   ├── repositories/
│   │   └── auth_repository.dart            # Interface del repositorio
│   └── usecases/
│       ├── login_usecase.dart
│       ├── register_usecase.dart
│       ├── logout_usecase.dart
│       ├── biometric_login_usecase.dart
│       ├── forgot_password_usecase.dart
│       ├── reset_password_usecase.dart
│       ├── enable_2fa_usecase.dart
│       └── verify_2fa_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart                  # BLoC principal
    │   ├── auth_event.dart
    │   ├── auth_state.dart
    │   ├── biometric_bloc.dart             # BLoC para biometría
    │   └── two_factor_bloc.dart            # BLoC para 2FA
    ├── pages/
    │   ├── login_page.dart
    │   ├── register_page.dart
    │   ├── forgot_password_page.dart
    │   ├── reset_password_page.dart
    │   ├── biometric_setup_page.dart
    │   └── two_factor_setup_page.dart
    └── widgets/
        ├── login_form.dart
        ├── register_form.dart
        ├── password_field.dart
        ├── biometric_button.dart
        ├── two_factor_input.dart
        └── social_login_buttons.dart
```

**Requisitos cubiertos:**
- `RF-01`: Registro de usuario (register_usecase.dart, register_page.dart)
- `RF-02`: Inicio de sesión (login_usecase.dart, login_page.dart)
- `RF-03`: Autenticación biométrica (biometric_login_usecase.dart, biometric_button.dart)
- `RF-04`: Recuperación de contraseña (forgot_password_usecase.dart, forgot_password_page.dart)
- `RNF-03`: Autenticación de dos factores (enable_2fa_usecase.dart, two_factor_bloc.dart)
- `HU-01`: Registro rápido de usuario
- `HU-02`: Login con autenticación biométrica

---

### 3️⃣ **Feature: Transacciones**

#### `lib/features/transactions/`

```
transactions/
├── data/
│   ├── datasources/
│   │   ├── transaction_remote_datasource.dart
│   │   └── transaction_local_datasource.dart    # Para funcionamiento offline
│   ├── models/
│   │   ├── transaction_model.dart
│   │   ├── transaction_filter_model.dart
│   │   └── transaction_search_model.dart
│   └── repositories/
│       └── transaction_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── transaction.dart
│   │   ├── transaction_filter.dart
│   │   └── transaction_type.dart                # Enum: income, expense
│   ├── repositories/
│   │   └── transaction_repository.dart
│   └── usecases/
│       ├── create_transaction_usecase.dart
│       ├── update_transaction_usecase.dart
│       ├── delete_transaction_usecase.dart
│       ├── get_transactions_usecase.dart
│       ├── filter_transactions_usecase.dart
│       ├── search_transactions_usecase.dart
│       └── sync_offline_transactions_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── transaction_bloc.dart
    │   ├── transaction_event.dart
    │   ├── transaction_state.dart
    │   ├── transaction_filter_bloc.dart
    │   └── transaction_search_bloc.dart
    ├── pages/
    │   ├── transactions_list_page.dart
    │   ├── transaction_detail_page.dart
    │   ├── add_transaction_page.dart
    │   └── edit_transaction_page.dart
    └── widgets/
        ├── transaction_card.dart
        ├── transaction_list_item.dart
        ├── transaction_form.dart
        ├── transaction_filters.dart
        ├── transaction_search_bar.dart
        ├── amount_input.dart
        ├── category_selector.dart
        ├── date_picker_field.dart
        └── empty_transactions_widget.dart
```

**Requisitos cubiertos:**
- `RF-05`: Registro manual de transacciones (create_transaction_usecase.dart, add_transaction_page.dart)
- `RF-06`: Edición de transacciones (update_transaction_usecase.dart, edit_transaction_page.dart)
- `RF-07`: Eliminación de transacciones (delete_transaction_usecase.dart)
- `RF-08`: Listado y filtrado de transacciones (get_transactions_usecase.dart, transaction_filters.dart)
- `RF-09`: Búsqueda de transacciones (search_transactions_usecase.dart, transaction_search_bar.dart)
- `HU-03`: Registro rápido de gasto
- `HU-04`: Búsqueda rápida de transacciones
- `CU-01`: Caso de Uso: Registrar Transacción Manual

---

### 4️⃣ **Feature: Sincronización Bancaria**

#### `lib/features/bank_sync/`

```
bank_sync/
├── data/
│   ├── datasources/
│   │   ├── bank_remote_datasource.dart          # API de agregación bancaria
│   │   └── bank_local_datasource.dart
│   ├── models/
│   │   ├── bank_account_model.dart
│   │   ├── bank_connection_model.dart
│   │   ├── bank_institution_model.dart
│   │   └── sync_status_model.dart
│   └── repositories/
│       └── bank_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── bank_account.dart
│   │   ├── bank_connection.dart
│   │   ├── bank_institution.dart
│   │   └── sync_status.dart
│   ├── repositories/
│   │   └── bank_repository.dart
│   └── usecases/
│       ├── connect_bank_usecase.dart
│       ├── disconnect_bank_usecase.dart
│       ├── sync_bank_transactions_usecase.dart
│       ├── get_bank_accounts_usecase.dart
│       ├── get_bank_institutions_usecase.dart
│       └── check_sync_status_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── bank_sync_bloc.dart
    │   ├── bank_sync_event.dart
    │   ├── bank_sync_state.dart
    │   ├── bank_connection_bloc.dart
    │   └── sync_status_bloc.dart
    ├── pages/
    │   ├── bank_list_page.dart
    │   ├── bank_connection_page.dart
    │   ├── bank_accounts_page.dart
    │   └── sync_status_page.dart
    └── widgets/
        ├── bank_institution_card.dart
        ├── bank_account_card.dart
        ├── sync_progress_indicator.dart
        ├── connection_status_badge.dart
        ├── bank_search_bar.dart
        └── psd2_consent_dialog.dart            # Cumplimiento PSD2
```

**Requisitos cubiertos:**
- `RF-10`: Conexión con entidades bancarias (connect_bank_usecase.dart, bank_connection_page.dart)
- `RF-11`: Sincronización automática de transacciones (sync_bank_transactions_usecase.dart)
- `RF-12`: Gestión de múltiples cuentas bancarias (get_bank_accounts_usecase.dart, bank_accounts_page.dart)
- `RF-13`: Desconexión de cuentas bancarias (disconnect_bank_usecase.dart)
- `RNF-05`: Cumplimiento PSD2 (psd2_consent_dialog.dart)
- `RNF-07`: Tiempo de sincronización bancaria
- `HU-05`: Conexión bancaria sencilla y segura
- `HU-06`: Sincronización automática de transacciones
- `CU-02`: Caso de Uso: Conectar Cuenta Bancaria

---

### 5️⃣ **Feature: Categorización con IA**

#### `lib/features/categories/`

```
categories/
├── data/
│   ├── datasources/
│   │   ├── category_remote_datasource.dart      # API con IA
│   │   └── category_local_datasource.dart
│   ├── models/
│   │   ├── category_model.dart
│   │   ├── category_prediction_model.dart
│   │   └── auto_categorization_model.dart
│   └── repositories/
│       └── category_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── category.dart
│   │   ├── category_prediction.dart
│   │   └── category_type.dart                   # Enum: predefined, custom
│   ├── repositories/
│   │   └── category_repository.dart
│   └── usecases/
│       ├── get_categories_usecase.dart
│       ├── create_category_usecase.dart
│       ├── update_category_usecase.dart
│       ├── delete_category_usecase.dart
│       ├── auto_categorize_transaction_usecase.dart
│       ├── recategorize_transaction_usecase.dart
│       └── train_categorization_model_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── category_bloc.dart
    │   ├── category_event.dart
    │   ├── category_state.dart
    │   └── auto_categorization_bloc.dart
    ├── pages/
    │   ├── categories_page.dart
    │   ├── add_category_page.dart
    │   ├── edit_category_page.dart
    │   └── category_suggestions_page.dart
    └── widgets/
        ├── category_card.dart
        ├── category_list_item.dart
        ├── category_form.dart
        ├── category_icon_picker.dart
        ├── category_color_picker.dart
        ├── ai_suggestion_chip.dart
        └── recategorize_dialog.dart
```

**Requisitos cubiertos:**
- `RF-14`: Categorización automática con IA (auto_categorize_transaction_usecase.dart)
- `RF-15`: Gestión de categorías predefinidas (get_categories_usecase.dart)
- `RF-16`: Creación de categorías personalizadas (create_category_usecase.dart, add_category_page.dart)
- `RF-17`: Recategorización manual de transacciones (recategorize_transaction_usecase.dart, recategorize_dialog.dart)

---

### 6️⃣ **Feature: Objetivos de Ahorro**

#### `lib/features/savings_goals/`

```
savings_goals/
├── data/
│   ├── datasources/
│   │   ├── goal_remote_datasource.dart
│   │   └── goal_local_datasource.dart
│   ├── models/
│   │   ├── savings_goal_model.dart
│   │   ├── goal_contribution_model.dart
│   │   └── goal_recommendation_model.dart
│   └── repositories/
│       └── goal_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── savings_goal.dart
│   │   ├── goal_contribution.dart
│   │   ├── goal_progress.dart
│   │   └── goal_recommendation.dart
│   ├── repositories/
│   │   └── goal_repository.dart
│   └── usecases/
│       ├── create_goal_usecase.dart
│       ├── update_goal_usecase.dart
│       ├── delete_goal_usecase.dart
│       ├── get_goals_usecase.dart
│       ├── add_contribution_usecase.dart
│       ├── get_goal_progress_usecase.dart
│       └── get_ai_recommendations_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── goal_bloc.dart
    │   ├── goal_event.dart
    │   ├── goal_state.dart
    │   ├── goal_progress_bloc.dart
    │   └── goal_recommendation_bloc.dart
    ├── pages/
    │   ├── goals_page.dart
    │   ├── goal_detail_page.dart
    │   ├── add_goal_page.dart
    │   ├── edit_goal_page.dart
    │   └── goal_recommendations_page.dart
    └── widgets/
        ├── goal_card.dart
        ├── goal_progress_bar.dart
        ├── goal_progress_chart.dart
        ├── goal_form.dart
        ├── contribution_input.dart
        ├── ai_recommendation_card.dart
        └── goal_celebration_dialog.dart        # Al completar objetivo
```

**Requisitos cubiertos:**
- `RF-18`: Creación de objetivos de ahorro (create_goal_usecase.dart, add_goal_page.dart)
- `RF-19`: Seguimiento de progreso de objetivos (get_goal_progress_usecase.dart, goal_progress_chart.dart)
- `RF-20`: Registro de aportaciones a objetivos (add_contribution_usecase.dart, contribution_input.dart)
- `RF-21`: Recomendaciones inteligentes de ahorro (get_ai_recommendations_usecase.dart, ai_recommendation_card.dart)
- `HU-07`: Objetivos de ahorro visuales y motivadores
- `HU-08`: Recomendación inteligente de ahorro con IA
- `CU-03`: Caso de Uso: Crear Objetivo de Ahorro

---

### 7️⃣ **Feature: Predicción con IA**

#### `lib/features/predictions/`

```
predictions/
├── data/
│   ├── datasources/
│   │   ├── prediction_remote_datasource.dart    # API con ML
│   │   └── prediction_local_datasource.dart
│   ├── models/
│   │   ├── expense_prediction_model.dart
│   │   ├── anomaly_model.dart
│   │   ├── subscription_model.dart
│   │   └── recurring_expense_model.dart
│   └── repositories/
│       └── prediction_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── expense_prediction.dart
│   │   ├── anomaly.dart
│   │   ├── subscription.dart
│   │   └── recurring_expense.dart
│   ├── repositories/
│   │   └── prediction_repository.dart
│   └── usecases/
│       ├── predict_expenses_usecase.dart
│       ├── detect_anomalies_usecase.dart
│       ├── detect_subscriptions_usecase.dart
│       ├── detect_recurring_expenses_usecase.dart
│       └── get_prediction_insights_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── prediction_bloc.dart
    │   ├── prediction_event.dart
    │   ├── prediction_state.dart
    │   ├── anomaly_bloc.dart
    │   └── subscription_bloc.dart
    ├── pages/
    │   ├── predictions_page.dart
    │   ├── expense_forecast_page.dart
    │   ├── anomalies_page.dart
    │   └── subscriptions_page.dart
    └── widgets/
        ├── prediction_card.dart
        ├── forecast_chart.dart
        ├── anomaly_alert_card.dart
        ├── subscription_card.dart
        ├── recurring_expense_card.dart
        ├── confidence_indicator.dart           # Confianza del modelo ML
        └── prediction_timeline.dart
```

**Requisitos cubiertos:**
- `RF-22`: Predicción de gastos con machine learning (predict_expenses_usecase.dart, forecast_chart.dart)
- `RF-23`: Detección de anomalías en gastos (detect_anomalies_usecase.dart, anomaly_alert_card.dart)
- `RF-24`: Detección automática de suscripciones y gastos recurrentes (detect_subscriptions_usecase.dart, subscriptions_page.dart)
- `HU-09`: Predicción de gastos del próximo mes
- `HU-10`: Detección y alerta de gastos inusuales
- `HU-11`: Identificación automática de suscripciones
- `CU-05`: Caso de Uso: Visualizar Predicción de Gastos

---

### 8️⃣ **Feature: Asistente IA**

#### `lib/features/ai_assistant/`

```
ai_assistant/
├── data/
│   ├── datasources/
│   │   ├── assistant_remote_datasource.dart     # API con LLM
│   │   └── conversation_local_datasource.dart
│   ├── models/
│   │   ├── chat_message_model.dart
│   │   ├── affordability_analysis_model.dart
│   │   ├── financial_recommendation_model.dart
│   │   └── conversation_context_model.dart
│   └── repositories/
│       └── assistant_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── chat_message.dart
│   │   ├── affordability_analysis.dart
│   │   ├── financial_recommendation.dart
│   │   └── conversation_context.dart
│   ├── repositories/
│   │   └── assistant_repository.dart
│   └── usecases/
│       ├── send_message_usecase.dart
│       ├── analyze_affordability_usecase.dart
│       ├── get_recommendations_usecase.dart
│       ├── get_conversation_history_usecase.dart
│       └── clear_conversation_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── assistant_bloc.dart
    │   ├── assistant_event.dart
    │   ├── assistant_state.dart
    │   ├── affordability_bloc.dart
    │   └── recommendation_bloc.dart
    ├── pages/
    │   ├── ai_chat_page.dart
    │   ├── affordability_analysis_page.dart
    │   └── recommendations_page.dart
    └── widgets/
        ├── chat_message_bubble.dart
        ├── chat_input_field.dart
        ├── typing_indicator.dart
        ├── affordability_result_card.dart
        ├── recommendation_card.dart
        ├── suggestion_chips.dart
        └── voice_input_button.dart             # Entrada por voz
```

**Requisitos cubiertos:**
- `RF-25`: Asistente conversacional con IA generativa (send_message_usecase.dart, ai_chat_page.dart)
- `RF-26`: Análisis de affordability (analyze_affordability_usecase.dart, affordability_analysis_page.dart)
- `RF-27`: Recomendaciones inteligentes de optimización financiera (get_recommendations_usecase.dart, recommendation_card.dart)
- `HU-12`: Chat con asistente IA en lenguaje natural
- `HU-13`: ¿Puedo permitírmelo? - Análisis de affordability
- `HU-14`: Recomendaciones proactivas de optimización
- `CU-04`: Caso de Uso: Consultar Asistente IA sobre Finanzas

---

### 9️⃣ **Feature: Visualización**

#### `lib/features/visualization/`

```
visualization/
├── data/
│   ├── datasources/
│   │   ├── analytics_remote_datasource.dart
│   │   └── analytics_local_datasource.dart
│   ├── models/
│   │   ├── dashboard_model.dart
│   │   ├── category_spending_model.dart
│   │   ├── time_series_model.dart
│   │   └── financial_summary_model.dart
│   └── repositories/
│       └── visualization_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── dashboard_data.dart
│   │   ├── category_spending.dart
│   │   ├── time_series_data.dart
│   │   └── financial_summary.dart
│   ├── repositories/
│   │   └── visualization_repository.dart
│   └── usecases/
│       ├── get_dashboard_data_usecase.dart
│       ├── get_category_spending_usecase.dart
│       ├── get_time_series_data_usecase.dart
│       └── get_financial_summary_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── dashboard_bloc.dart
    │   ├── dashboard_event.dart
    │   ├── dashboard_state.dart
    │   └── chart_filter_bloc.dart
    ├── pages/
    │   ├── dashboard_page.dart                  # Página principal
    │   ├── category_analysis_page.dart
    │   └── trends_page.dart
    └── widgets/
        ├── dashboard_summary_card.dart
        ├── balance_card.dart
        ├── recent_transactions_widget.dart
        ├── quick_actions_widget.dart
        ├── category_pie_chart.dart
        ├── category_bar_chart.dart
        ├── time_series_line_chart.dart
        ├── interactive_chart.dart               # Charts interactivos
        ├── chart_legend.dart
        ├── period_selector.dart                 # Selector de período
        └── chart_tooltip.dart
```

**Requisitos cubiertos:**
- `RF-28`: Dashboard con resumen financiero (get_dashboard_data_usecase.dart, dashboard_page.dart)
- `RF-29`: Visualización de gastos por categoría (get_category_spending_usecase.dart, category_pie_chart.dart)
- `RF-30`: Gráfico de evolución temporal (get_time_series_data_usecase.dart, time_series_line_chart.dart)
- `HU-15`: Dashboard visual e informativo
- `HU-16`: Gráficos interactivos de gastos

---

### 🔟 **Feature: Notificaciones**

#### `lib/features/notifications/`

```
notifications/
├── data/
│   ├── datasources/
│   │   ├── notification_remote_datasource.dart
│   │   └── notification_local_datasource.dart
│   ├── models/
│   │   ├── notification_model.dart
│   │   ├── notification_settings_model.dart
│   │   └── push_token_model.dart
│   └── repositories/
│       └── notification_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── notification.dart
│   │   ├── notification_type.dart               # Enum: transaction, budget, goal
│   │   └── notification_settings.dart
│   ├── repositories/
│   │   └── notification_repository.dart
│   └── usecases/
│       ├── send_notification_usecase.dart
│       ├── schedule_notification_usecase.dart
│       ├── get_notifications_usecase.dart
│       ├── mark_as_read_usecase.dart
│       ├── update_settings_usecase.dart
│       └── register_push_token_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── notification_bloc.dart
    │   ├── notification_event.dart
    │   ├── notification_state.dart
    │   └── notification_settings_bloc.dart
    ├── pages/
    │   ├── notifications_page.dart
    │   └── notification_settings_page.dart
    └── widgets/
        ├── notification_card.dart
        ├── notification_badge.dart
        ├── notification_settings_item.dart
        └── empty_notifications_widget.dart
```

**Requisitos cubiertos:**
- `RF-31`: Notificaciones push de transacciones (send_notification_usecase.dart)
- `RF-32`: Alertas de exceso de presupuesto (schedule_notification_usecase.dart)
- `RF-33`: Recordatorios de progreso de objetivos (schedule_notification_usecase.dart)

---

### 1️⃣1️⃣ **Feature: Exportación**

#### `lib/features/export/`

```
export/
├── data/
│   ├── datasources/
│   │   └── export_remote_datasource.dart
│   ├── models/
│   │   ├── export_request_model.dart
│   │   └── export_response_model.dart
│   └── repositories/
│       └── export_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── export_request.dart
│   │   └── export_format.dart                   # Enum: CSV, PDF
│   ├── repositories/
│   │   └── export_repository.dart
│   └── usecases/
│       ├── export_to_csv_usecase.dart
│       ├── export_to_pdf_usecase.dart
│       └── share_export_usecase.dart
│
└── presentation/
    ├── bloc/
    │   ├── export_bloc.dart
    │   ├── export_event.dart
    │   └── export_state.dart
    ├── pages/
    │   └── export_page.dart
    └── widgets/
        ├── export_options_card.dart
        ├── date_range_selector.dart
        ├── format_selector.dart
        └── export_progress_dialog.dart
```

**Requisitos cubiertos:**
- `RF-34`: Exportación de transacciones a CSV (export_to_csv_usecase.dart)
- `RF-35`: Generación de informes financieros en PDF (export_to_pdf_usecase.dart)

---

### 1️⃣2️⃣ **Feature: Configuración**

#### `lib/features/settings/`

```
settings/
├── data/
│   ├── datasources/
│   │   ├── settings_remote_datasource.dart
│   │   └── settings_local_datasource.dart
│   ├── models/
│   │   ├── user_settings_model.dart
│   │   ├── app_preferences_model.dart
│   │   └── privacy_settings_model.dart
│   └── repositories/
│       └── settings_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── user_settings.dart
│   │   ├── app_preferences.dart
│   │   └── privacy_settings.dart
│   ├── repositories/
│   │   └── settings_repository.dart
│   └── usecases/
│       ├── get_settings_usecase.dart
│       ├── update_settings_usecase.dart
│       ├── change_language_usecase.dart
│       ├── change_currency_usecase.dart
│       ├── delete_account_usecase.dart
│       └── export_user_data_usecase.dart        # GDPR
│
└── presentation/
    ├── bloc/
    │   ├── settings_bloc.dart
    │   ├── settings_event.dart
    │   └── settings_state.dart
    ├── pages/
    │   ├── settings_page.dart
    │   ├── profile_page.dart
    │   ├── privacy_page.dart
    │   ├── appearance_page.dart
    │   └── about_page.dart
    └── widgets/
        ├── settings_section.dart
        ├── settings_item.dart
        ├── language_selector.dart
        ├── currency_selector.dart
        ├── theme_selector.dart
        └── delete_account_dialog.dart
```

**Requisitos cubiertos:**
- `RNF-04`: Cumplimiento GDPR (export_user_data_usecase.dart, delete_account_usecase.dart, privacy_page.dart)
- `RNF-13`: Localización e internacionalización (change_language_usecase.dart, language_selector.dart)

---

## 📦 Assets y Recursos

### `assets/`

```
assets/
├── images/
│   ├── logo/
│   │   ├── logo.png
│   │   ├── logo_dark.png
│   │   └── splash_logo.png
│   ├── illustrations/
│   │   ├── empty_state.svg
│   │   ├── no_transactions.svg
│   │   ├── no_goals.svg
│   │   └── success_animation.json              # Lottie animation
│   └── icons/
│       └── category_icons/                      # Iconos de categorías
│           ├── food.svg
│           ├── transport.svg
│           ├── shopping.svg
│           └── ...
│
├── fonts/
│   └── Poppins/                                 # Fuente personalizada
│       ├── Poppins-Regular.ttf
│       ├── Poppins-Medium.ttf
│       ├── Poppins-SemiBold.ttf
│       └── Poppins-Bold.ttf
│
└── translations/
    ├── es.json
    ├── en.json
    └── fr.json
```

---

## 🧪 Testing

### `test/`

```
test/
├── unit/
│   ├── core/
│   │   ├── utils/
│   │   └── network/
│   └── features/
│       ├── authentication/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── transactions/
│       ├── bank_sync/
│       ├── categories/
│       ├── savings_goals/
│       ├── predictions/
│       ├── ai_assistant/
│       └── visualization/
│
├── widget/
│   └── features/
│       ├── authentication/
│       ├── transactions/
│       └── ...
│
├── integration/
│   ├── authentication_flow_test.dart
│   ├── transaction_flow_test.dart
│   ├── bank_sync_flow_test.dart
│   └── complete_user_journey_test.dart
│
└── e2e/
    ├── app_test.dart
    └── screenshots/
```

**Requisitos cubiertos:**
- `RNF-21`: Documentación del código (cobertura de tests)
- `RNF-22`: Arquitectura limpia y modular (estructura de tests)

---

## 📱 Configuración Específica de Plataforma

### `android/`

```
android/
├── app/
│   ├── src/
│   │   └── main/
│   │       ├── AndroidManifest.xml             # Permisos y configuración
│   │       ├── kotlin/
│   │       └── res/
│   └── build.gradle                            # Dependencias Android
├── gradle/
└── build.gradle
```

**Requisitos cubiertos:**
- `RNF-18`: Compatibilidad con Android

### `ios/`

```
ios/
├── Runner/
│   ├── Info.plist                              # Permisos iOS
│   ├── AppDelegate.swift
│   └── Assets.xcassets/
├── Runner.xcodeproj/
└── Podfile                                     # Dependencias iOS
```

**Requisitos cubiertos:**
- `RNF-19`: Compatibilidad con iOS

---

## 🔐 Archivos de Configuración

### Raíz del proyecto

```
finora/
├── pubspec.yaml                                # Dependencias Flutter
├── analysis_options.yaml                       # Reglas de linting
├── .env                                        # Variables de entorno (NO subir a Git)
├── .env.example                                # Ejemplo de variables
├── .gitignore
├── README.md
├── CHANGELOG.md
├── LICENSE
└── flutter_launcher_icons.yaml                # Configuración de iconos
```

---

## 📋 Requisitos del Sistema

### Desarrollo

- **Flutter SDK**: >= 3.16.0
- **Dart SDK**: >= 3.2.0
- **Android Studio** / **Xcode** (para emuladores)
- **Node.js**: >= 18.x (para scripts auxiliares)

### Runtime

- **Android**: API Level 21+ (Android 5.0 Lollipop)
- **iOS**: iOS 12.0+

---

## 🛠️ Tecnologías Utilizadas

### Framework Principal
- **Flutter** 3.16+
- **Dart** 3.2+

### Gestión de Estado
- **flutter_bloc** / **bloc** - Patrón BLoC para gestión de estado
- **equatable** - Comparación de objetos inmutables

### Networking
- **dio** - Cliente HTTP
- **retrofit** - Generación de código para APIs REST
- **pretty_dio_logger** - Logs de peticiones HTTP

### Base de Datos Local
- **sqflite** - SQLite para Flutter
- **hive** - Base de datos NoSQL rápida
- **shared_preferences** - Almacenamiento clave-valor
- **flutter_secure_storage** - Almacenamiento seguro

### Seguridad
- **encrypt** - Cifrado de datos
- **local_auth** - Autenticación biométrica
- **flutter_keychain** - Gestión de keychain
- **ssl_pinning** - SSL pinning

### Sincronización Bancaria
- **plaid_flutter** / **tink_link** - Agregación bancaria PSD2

### IA y Machine Learning
- **tflite_flutter** - TensorFlow Lite para predicciones locales
- **http** - Llamadas a APIs de IA (OpenAI, Google AI)

### Gráficos y Visualización
- **fl_chart** - Gráficos interactivos
- **syncfusion_flutter_charts** - Charts avanzados (alternativa)

### Notificaciones
- **firebase_messaging** - Push notifications
- **flutter_local_notifications** - Notificaciones locales

### Internacionalización
- **intl** - Formateo de fechas y números
- **flutter_localizations** - i18n de Flutter
- **easy_localization** - Sistema de traducciones

### UI/UX
- **flutter_svg** - Renderizado de SVG
- **cached_network_image** - Caché de imágenes
- **shimmer** - Efectos de carga
- **lottie** - Animaciones
- **google_fonts** - Fuentes de Google

### Exportación
- **pdf** - Generación de PDFs
- **csv** - Exportación a CSV
- **share_plus** - Compartir archivos

### Testing
- **mockito** - Mocks para tests
- **flutter_test** - Tests de Flutter
- **integration_test** - Tests de integración

### DevTools
- **freezed** - Generación de modelos inmutables
- **json_serializable** - Serialización JSON
- **build_runner** - Generación de código
- **flutter_launcher_icons** - Generación de iconos
- **flutter_native_splash** - Splash screen nativo

### Monitoreo
- **firebase_crashlytics** - Reportes de crashes
- **firebase_analytics** - Analytics
- **sentry_flutter** - Monitoreo de errores

---

## 🚀 Instalación y Configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/ManahenGarciaGarrido/Finora.git
cd Finora
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Generar código (modelos, rutas, etc.)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env con las credenciales necesarias
```

### 5. Configurar Firebase (para notificaciones y analytics)

- Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
- Colocarlos en las carpetas correspondientes

### 6. Ejecutar la aplicación

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (desarrollo)
flutter run -d chrome
```

---

## 📊 Módulos y Funcionalidades

### Módulos Must Have (Sprint 1-5)
1. **Autenticación** - Registro, login, recuperación de contraseña
2. **Transacciones** - CRUD completo de transacciones
3. **Sincronización Bancaria** - Conexión con bancos via PSD2
4. **Categorización IA** - Categorización automática con ML
5. **Visualización** - Dashboard con resumen financiero

### Módulos Should Have (Sprint 6-9)
6. **Objetivos de Ahorro** - Creación y seguimiento de objetivos
7. **Predicción IA** - Predicción de gastos con ML
8. **Asistente IA** - Chatbot con IA generativa

### Módulos Could Have (Sprint 10)
9. **Notificaciones** - Push notifications
10. **Exportación** - CSV y PDF
11. **Configuración** - Ajustes y preferencias

---

## 🔧 Backend

> **Nota**: La estructura del backend está pendiente de definir.

### Backend por determinar

El backend de Finora deberá incluir los siguientes componentes:

- **API REST** para comunicación con el frontend
- **Base de datos** para almacenamiento persistente
- **Servicios de IA/ML** para:
  - Categorización automática
  - Predicción de gastos
  - Detección de anomalías
  - Asistente conversacional
- **Integración con agregadores bancarios** (PSD2)
- **Sistema de autenticación** con JWT
- **Servicios de notificaciones** push
- **Generación de informes** PDF/CSV
- **Sistema de backup** y recuperación

**Tecnologías sugeridas**: Node.js/Express, Python/FastAPI, PostgreSQL, Redis, TensorFlow/PyTorch, Firebase.

---

## 🗓️ Roadmap

### Sprint 1 (Semanas 1-2)
- ✅ RF-01: Registro de usuario
- ✅ RNF-01, RNF-02: Cifrado de datos
- ✅ RNF-12: Diseño responsive
- ✅ RNF-18, RNF-19: Compatibilidad móvil
- ✅ RNF-22: Arquitectura limpia

### Sprint 2 (Semanas 3-4)
- 🔄 RF-02: Inicio de sesión
- 🔄 RF-04: Recuperación de contraseña
- 🔄 RF-05: Registro manual de transacciones
- 🔄 RF-15: Gestión de categorías predefinidas
- 🔄 RNF-06: Tiempo de respuesta
- 🔄 RNF-15: Funcionamiento offline

### Sprint 3 (Semanas 5-6)
- 📋 RF-06: Edición de transacciones
- 📋 RF-08: Listado y filtrado de transacciones
- 📋 RF-09: Búsqueda de transacciones
- 📋 RF-28: Dashboard con resumen financiero
- 📋 RNF-08: Tiempo de carga de la aplicación

### Sprint 4 (Semanas 7-8)
- 📋 RF-10: Conexión con entidades bancarias
- 📋 RF-11: Sincronización automática de transacciones
- 📋 RNF-05: Cumplimiento PSD2
- 📋 RNF-07: Tiempo de sincronización bancaria
- 📋 RNF-16: Recuperación ante fallos

### Sprint 5 (Semanas 9-10)
- 📋 RF-07: Eliminación de transacciones
- 📋 RF-12: Gestión de múltiples cuentas bancarias
- 📋 RF-13: Desconexión de cuentas bancarias
- 📋 RF-14: Categorización automática con IA
- 📋 RF-16: Creación de categorías personalizadas
- 📋 RF-17: Recategorización manual de transacciones
- 📋 RNF-20: Escalabilidad de datos

### Sprint 6 (Semanas 11-12)
- 📋 RF-03: Autenticación biométrica
- 📋 RF-29: Visualización de gastos por categoría
- 📋 RF-30: Gráfico de evolución temporal
- 📋 RNF-11: Accesibilidad WCAG 2.1 AA

### Sprint 7 (Semanas 13-14)
- 📋 RF-18: Creación de objetivos de ahorro
- 📋 RF-19: Seguimiento de progreso de objetivos
- 📋 RF-20: Registro de aportaciones a objetivos
- 📋 RF-21: Recomendaciones inteligentes de ahorro

### Sprint 8 (Semanas 15-16)
- 📋 RF-22: Predicción de gastos con machine learning
- 📋 RF-23: Detección de anomalías en gastos
- 📋 RF-24: Detección automática de suscripciones

### Sprint 9 (Semanas 17-18)
- 📋 RF-25: Asistente conversacional con IA generativa
- 📋 RF-26: Análisis de affordability
- 📋 RF-27: Recomendaciones inteligentes de optimización financiera

### Sprint 10 (Semanas 19-20)
- 📋 RF-31, RF-32, RF-33: Sistema de notificaciones
- 📋 RF-34, RF-35: Exportación CSV y PDF
- 📋 RNF-03: Autenticación de dos factores (2FA)
- 📋 RNF-09: Consumo de memoria
- 📋 RNF-10: Curva de aprendizaje
- 📋 RNF-13: Localización e internacionalización
- 📋 RNF-14: Disponibilidad del sistema
- 📋 RNF-17: Backup automático de datos
- 📋 RNF-21: Documentación del código

---

## 📄 Licencia

Este proyecto es parte del Trabajo de Fin de Grado (TFG) de **Manahen García Garrido** en la Universidad de Extremadura.

---

## 👤 Autor

**Manahen García Garrido**  
📧 Email: [manahen@example.com](mailto:manahen@example.com)  
🔗 GitHub: [@ManahenGarciaGarrido](https://github.com/ManahenGarciaGarrido)

---

## 🙏 Agradecimientos

- Universidad de Extremadura - Escuela Politécnica
- Colaboradores: Eduardo Gómez Almendral, Rubén Tie Corbacho Pérez

---

**Última actualización**: Diciembre 2024  
**Versión**: 0.1.0-alpha
