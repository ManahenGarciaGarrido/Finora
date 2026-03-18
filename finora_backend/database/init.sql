-- Finora Database Initialization Script
-- This script creates the necessary tables for the application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expires TIMESTAMP,
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP,
    terms_accepted BOOLEAN DEFAULT FALSE,
    terms_accepted_at TIMESTAMP,
    privacy_accepted BOOLEAN DEFAULT FALSE,
    privacy_accepted_at TIMESTAMP,
    photo_base64 TEXT,
    widget_settings JSONB DEFAULT '{"show_balance":true,"show_today_spent":true,"show_budget_pct":true,"dark_mode":"auto"}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create index on verification token
CREATE INDEX IF NOT EXISTS idx_users_verification_token ON users(email_verification_token);

-- GDPR Consents table
CREATE TABLE IF NOT EXISTS gdpr_consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    consent_type VARCHAR(50) NOT NULL,
    granted BOOLEAN DEFAULT FALSE,
    granted_at TIMESTAMP,
    revoked_at TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on user_id for GDPR consents
CREATE INDEX IF NOT EXISTS idx_gdpr_consents_user_id ON gdpr_consents(user_id);

-- Audit logs table for GDPR compliance
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource VARCHAR(100),
    resource_id VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on audit logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at for users
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to auto-update updated_at for gdpr_consents
DROP TRIGGER IF EXISTS update_gdpr_consents_updated_at ON gdpr_consents;
CREATE TRIGGER update_gdpr_consents_updated_at
    BEFORE UPDATE ON gdpr_consents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TRANSACTIONS TABLE (RF-05)
-- ============================================

-- Transactions table for manual income/expense tracking
-- external_tx_id: Salt Edge transaction ID (para deduplicación al importar desde el banco)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    type VARCHAR(10) NOT NULL CHECK (type IN ('income', 'expense')),
    category VARCHAR(100) NOT NULL,
    description TEXT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method VARCHAR(30) NOT NULL DEFAULT 'cash' CHECK (payment_method IN (
        'cash', 'card', 'transfer',
        'debit_card', 'credit_card', 'prepaid_card',
        'bank_transfer', 'bizum', 'paypal',
        'apple_pay', 'google_pay', 'direct_debit',
        'cheque', 'crypto', 'voucher', 'sepa', 'wire'
    )),
    external_tx_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for transactions
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, date DESC);

-- Índice de búsqueda de texto completo en description (RF-09 Nota Técnica)
-- Permite búsquedas eficientes por nombre de comercio/descripción en el backend
CREATE INDEX IF NOT EXISTS idx_transactions_description_fts
    ON transactions USING GIN(to_tsvector('spanish', coalesce(description, '')));

-- Índice en description para búsquedas combinadas (user_id + description)
CREATE INDEX IF NOT EXISTS idx_transactions_user_description
    ON transactions(user_id, description text_pattern_ops);

-- Trigger to auto-update updated_at for transactions
DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- CATEGORIES TABLE (RF-15)
-- ============================================

-- Categories table: predefined (user_id NULL) + user custom categories
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('income', 'expense')),
    icon VARCHAR(50) NOT NULL,
    color VARCHAR(7) NOT NULL,
    is_predefined BOOLEAN NOT NULL DEFAULT FALSE,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for categories
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type);

-- Trigger to auto-update updated_at for categories
DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- USER CONSENTS CURRENT TABLE (GDPR - RNF-04)
-- Estado actual de consentimientos por usuario
-- ============================================

CREATE TABLE IF NOT EXISTS user_consents_current (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_type VARCHAR(50) NOT NULL,
    granted BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, consent_type)
);

CREATE INDEX IF NOT EXISTS idx_user_consents_current_user_id ON user_consents_current(user_id);

-- ============================================
-- USER CONSENTS HISTORY TABLE (GDPR - RNF-04)
-- Registro histórico de TODOS los cambios de consentimiento
-- ============================================

CREATE TABLE IF NOT EXISTS user_consents_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_type VARCHAR(50) NOT NULL,
    granted BOOLEAN NOT NULL,
    action VARCHAR(50) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_consents_history_user_id ON user_consents_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_consents_history_created_at ON user_consents_history(created_at);

-- ============================================
-- FUNCTION: Seed predefined categories for a user (RF-15)
-- Called at registration to give each user their own categories
-- ============================================

CREATE OR REPLACE FUNCTION seed_categories_for_user(p_user_id UUID) RETURNS VOID AS $$
BEGIN
    -- Expense categories
    INSERT INTO categories (user_id, name, type, icon, color, is_predefined, display_order) VALUES
        (p_user_id, 'Alimentación', 'expense', 'restaurant', '#F59E0B', TRUE, 1),
        (p_user_id, 'Transporte', 'expense', 'directions_car', '#3B82F6', TRUE, 2),
        (p_user_id, 'Ocio', 'expense', 'sports_esports', '#8B5CF6', TRUE, 3),
        (p_user_id, 'Salud', 'expense', 'local_hospital', '#EF4444', TRUE, 4),
        (p_user_id, 'Vivienda', 'expense', 'home', '#06B6D4', TRUE, 5),
        (p_user_id, 'Servicios', 'expense', 'phone_android', '#6366F1', TRUE, 6),
        (p_user_id, 'Educación', 'expense', 'school', '#F97316', TRUE, 7),
        (p_user_id, 'Ropa', 'expense', 'checkroom', '#EC4899', TRUE, 8),
        (p_user_id, 'Otros', 'expense', 'more_horiz', '#6B7280', TRUE, 9);
    -- Income categories
    INSERT INTO categories (user_id, name, type, icon, color, is_predefined, display_order) VALUES
        (p_user_id, 'Salario', 'income', 'work', '#22C55E', TRUE, 1),
        (p_user_id, 'Freelance', 'income', 'computer', '#14B8A6', TRUE, 2),
        (p_user_id, 'Otros ingresos', 'income', 'account_balance_wallet', '#64748B', TRUE, 3);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Seed default GDPR consents for a user
-- Called at registration with the user's consent choices
-- ============================================

CREATE OR REPLACE FUNCTION seed_default_consents(p_user_id UUID, p_ip VARCHAR, p_user_agent TEXT) RETURNS VOID AS $$
BEGIN
    -- Insert default consents (all ON = user accepted without customizing)
    INSERT INTO user_consents_current (user_id, consent_type, granted) VALUES
        (p_user_id, 'essential', TRUE),
        (p_user_id, 'analytics', TRUE),
        (p_user_id, 'marketing', TRUE),
        (p_user_id, 'third_party', TRUE),
        (p_user_id, 'personalization', TRUE),
        (p_user_id, 'data_processing', TRUE)
    ON CONFLICT (user_id, consent_type) DO UPDATE SET granted = EXCLUDED.granted, updated_at = CURRENT_TIMESTAMP;

    -- Record in history
    INSERT INTO user_consents_history (user_id, consent_type, granted, action, ip_address, user_agent) VALUES
        (p_user_id, 'essential', TRUE, 'INITIAL_REGISTRATION', p_ip, p_user_agent),
        (p_user_id, 'analytics', TRUE, 'INITIAL_REGISTRATION', p_ip, p_user_agent),
        (p_user_id, 'marketing', TRUE, 'INITIAL_REGISTRATION', p_ip, p_user_agent),
        (p_user_id, 'third_party', TRUE, 'INITIAL_REGISTRATION', p_ip, p_user_agent),
        (p_user_id, 'personalization', TRUE, 'INITIAL_REGISTRATION', p_ip, p_user_agent),
        (p_user_id, 'data_processing', TRUE, 'INITIAL_REGISTRATION', p_ip, p_user_agent);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- RF-10: BANK CONNECTIONS TABLE (Salt Edge Community)
-- requisition_id almacena el Salt Edge connection_id tras el callback
-- saltedge_customer_id: ID del Customer en Salt Edge (uno por usuario)
-- ============================================

CREATE TABLE IF NOT EXISTS bank_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requisition_id VARCHAR(255),
    saltedge_customer_id VARCHAR(255),
    institution_id VARCHAR(100),
    institution_name VARCHAR(255),
    institution_logo VARCHAR(512),
    auth_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'linked', 'failed', 'disconnected')),
    linked_at TIMESTAMP,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bank_connections_user_id ON bank_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_bank_connections_requisition_id ON bank_connections(requisition_id);

DROP TRIGGER IF EXISTS update_bank_connections_updated_at ON bank_connections;
CREATE TRIGGER update_bank_connections_updated_at
    BEFORE UPDATE ON bank_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RF-10: BANK ACCOUNTS TABLE (Salt Edge Community)
-- ============================================

CREATE TABLE IF NOT EXISTS bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    connection_id UUID NOT NULL REFERENCES bank_connections(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    external_account_id VARCHAR(255) UNIQUE,
    iban VARCHAR(34),
    account_name VARCHAR(255),
    account_type VARCHAR(30) NOT NULL DEFAULT 'current' CHECK (account_type IN ('current', 'savings', 'investment', 'other')),
    currency VARCHAR(3) DEFAULT 'EUR',
    balance_cents BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_connection_id ON bank_accounts(connection_id);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_user_id ON bank_accounts(user_id);

DROP TRIGGER IF EXISTS update_bank_accounts_updated_at ON bank_accounts;
CREATE TRIGGER update_bank_accounts_updated_at
    BEFORE UPDATE ON bank_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RF-10: BANK CARDS TABLE
-- Tarjetas asociadas a cuentas bancarias
-- ============================================

CREATE TABLE IF NOT EXISTS bank_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bank_account_id UUID NOT NULL REFERENCES bank_accounts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_name VARCHAR(255) NOT NULL,
    card_type VARCHAR(20) NOT NULL DEFAULT 'debit' CHECK (card_type IN ('debit', 'credit', 'prepaid')),
    last_four VARCHAR(4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bank_cards_bank_account_id ON bank_cards(bank_account_id);
CREATE INDEX IF NOT EXISTS idx_bank_cards_user_id ON bank_cards(user_id);

DROP TRIGGER IF EXISTS update_bank_cards_updated_at ON bank_cards;
CREATE TRIGGER update_bank_cards_updated_at
    BEFORE UPDATE ON bank_cards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Add bank_account_id and card_id to transactions (safe for re-runs)
-- ============================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'bank_account_id'
  ) THEN
    ALTER TABLE transactions
      ADD COLUMN bank_account_id UUID REFERENCES bank_accounts(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'card_id'
  ) THEN
    ALTER TABLE transactions
      ADD COLUMN card_id UUID REFERENCES bank_cards(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bank_accounts' AND column_name = 'account_type'
  ) THEN
    ALTER TABLE bank_accounts
      ADD COLUMN account_type VARCHAR(30) NOT NULL DEFAULT 'current'
        CHECK (account_type IN ('current', 'savings', 'investment', 'other'));
  END IF;
END$$;

-- ============================================
-- RNF-05: PSD2 CONSENTS TABLE
-- Gestión de consentimientos bancarios con expiración (90 días SCA)
-- ============================================

CREATE TABLE IF NOT EXISTS psd2_consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    connection_id UUID NOT NULL REFERENCES bank_connections(id) ON DELETE CASCADE,
    consent_reference VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'expired', 'revoked')),
    scope TEXT NOT NULL DEFAULT 'read_accounts,read_transactions',
    granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    renewal_notified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(connection_id)
);

CREATE INDEX IF NOT EXISTS idx_psd2_consents_user_id ON psd2_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_psd2_consents_expires_at ON psd2_consents(expires_at);
CREATE INDEX IF NOT EXISTS idx_psd2_consents_status ON psd2_consents(status);

DROP TRIGGER IF EXISTS update_psd2_consents_updated_at ON psd2_consents;
CREATE TRIGGER update_psd2_consents_updated_at
    BEFORE UPDATE ON psd2_consents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RNF-07: SYNC LOGS TABLE
-- Historial de sincronizaciones para monitorización y debugging
-- ============================================

CREATE TABLE IF NOT EXISTS sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    connection_id UUID REFERENCES bank_connections(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    trigger_type VARCHAR(20) NOT NULL DEFAULT 'cron'
        CHECK (trigger_type IN ('cron', 'manual', 'initial')),
    status VARCHAR(20) NOT NULL DEFAULT 'success'
        CHECK (status IN ('success', 'error', 'partial')),
    imported_count INTEGER DEFAULT 0,
    skipped_count INTEGER DEFAULT 0,
    duration_ms INTEGER,
    error_message TEXT,
    synced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sync_logs_connection_id ON sync_logs(connection_id);
CREATE INDEX IF NOT EXISTS idx_sync_logs_synced_at ON sync_logs(synced_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_logs_user_id ON sync_logs(user_id);


-- ============================================
-- HU-06: In-app notifications table
-- ============================================

CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(50)  NOT NULL DEFAULT 'bank_sync',
    title       VARCHAR(255) NOT NULL,
    body        TEXT         NOT NULL,
    metadata    JSONB,
    read_at     TIMESTAMP,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread  ON notifications(user_id, read_at) WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- ============================================
-- RF-14 / RF-17: CATEGORY FEEDBACK TABLE
-- Almacena correcciones del usuario para mejorar el modelo de IA
-- ============================================

CREATE TABLE IF NOT EXISTS category_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    transaction_type VARCHAR(10) NOT NULL CHECK (transaction_type IN ('income', 'expense')),
    corrected_category VARCHAR(100) NOT NULL,
    original_category VARCHAR(100),
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, description, transaction_type)
);

CREATE INDEX IF NOT EXISTS idx_category_feedback_user_id ON category_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_category_feedback_description ON category_feedback(user_id, transaction_type);

DROP TRIGGER IF EXISTS update_category_feedback_updated_at ON category_feedback;
CREATE TRIGGER update_category_feedback_updated_at
    BEFORE UPDATE ON category_feedback
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RNF-20: Índices adicionales para escalabilidad con 10k+ transacciones
-- ============================================

-- Índice compuesto para filtros por cuenta bancaria (RF-12)
CREATE INDEX IF NOT EXISTS idx_transactions_bank_account
    ON transactions(user_id, bank_account_id)
    WHERE bank_account_id IS NOT NULL;

-- Índice compuesto para filtrar por tipo + fecha (consulta más frecuente)
CREATE INDEX IF NOT EXISTS idx_transactions_user_type_date
    ON transactions(user_id, type, date DESC);

-- Índice para búsquedas combinadas usuario + categoría + fecha
CREATE INDEX IF NOT EXISTS idx_transactions_user_category_date
    ON transactions(user_id, category, date DESC);

-- ============================================
-- RF-18 / RF-19 / RF-20 / HU-07: SAVINGS GOALS
-- Objetivos de ahorro con progreso visual y motivación
-- ============================================

-- Iconos disponibles para objetivos (enum abierto, se amplía en app)
-- Valores: house, car, travel, education, emergency, wedding, tech,
--          business, health, retirement, gift, other

CREATE TABLE IF NOT EXISTS savings_goals (
    id              UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(120) NOT NULL,
    icon            VARCHAR(40)  NOT NULL DEFAULT 'other',   -- nombre del icono (RF-18)
    color           VARCHAR(7)   NOT NULL DEFAULT '#6C63FF', -- hex color personalizable
    target_amount   NUMERIC(12,2) NOT NULL CHECK (target_amount > 0),
    current_amount  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    deadline        DATE,                                    -- fecha límite opcional (RF-18)
    category        VARCHAR(100),                            -- categoría asociada opcional
    notes           TEXT,
    -- Estado: active (en progreso) | completed (100%) | cancelled (abandonado)
    status          VARCHAR(20)  NOT NULL DEFAULT 'active'
                       CHECK (status IN ('active', 'completed', 'cancelled')),
    -- Recomendación mensual de IA (RF-21): calculada al crear/actualizar
    monthly_target  NUMERIC(10,2),                           -- aportación mensual sugerida
    ai_feasibility  VARCHAR(20),                             -- viable | difficult | not_viable
    ai_explanation  TEXT,                                    -- justificación del cálculo
    completed_at    TIMESTAMP,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_savings_goals_user_id ON savings_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_goals_status  ON savings_goals(user_id, status);

DROP TRIGGER IF EXISTS update_savings_goals_updated_at ON savings_goals;
CREATE TRIGGER update_savings_goals_updated_at
    BEFORE UPDATE ON savings_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RF-20: GOAL CONTRIBUTIONS
-- Historial de aportaciones a cada objetivo de ahorro
-- ============================================

CREATE TABLE IF NOT EXISTS goal_contributions (
    id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    goal_id     UUID         NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
    user_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount      NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    date        DATE         NOT NULL DEFAULT CURRENT_DATE,
    note        VARCHAR(255),  -- nota opcional (RF-20)
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal_id ON goal_contributions(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_contributions_user_id ON goal_contributions(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_contributions_date    ON goal_contributions(goal_id, date DESC);

DROP TRIGGER IF EXISTS update_goal_contributions_updated_at ON goal_contributions;
CREATE TRIGGER update_goal_contributions_updated_at
    BEFORE UPDATE ON goal_contributions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- ============================================
-- RF-32: BUDGETS
-- Presupuestos mensuales por categoría
-- ============================================

CREATE TABLE IF NOT EXISTS budgets (
    id               UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category         VARCHAR(100)  NOT NULL,
    monthly_limit    NUMERIC(12,2) NOT NULL CHECK (monthly_limit > 0),
    rollover_enabled BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, category)
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);

DROP TRIGGER IF EXISTS update_budgets_updated_at ON budgets;
CREATE TRIGGER update_budgets_updated_at
    BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();