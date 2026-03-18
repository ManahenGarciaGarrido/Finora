/**
 * Database migration script — adds new columns and tables for bank cards feature
 *
 * Run with: node database/migrate.js
 * Safe to run multiple times (idempotent).
 */

const db = require('../services/db');

async function migrate() {
  console.log('[migrate] Starting database migration…');

  try {
    // 1. Add account_type to bank_accounts
    await db.query(`
      ALTER TABLE bank_accounts
        ADD COLUMN IF NOT EXISTS account_type VARCHAR(30) NOT NULL DEFAULT 'current'
    `);
    console.log('[migrate] ✓ bank_accounts.account_type');

    // 2. Create bank_cards table
    await db.query(`
      CREATE TABLE IF NOT EXISTS bank_cards (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        bank_account_id UUID NOT NULL REFERENCES bank_accounts(id) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        card_name VARCHAR(255) NOT NULL,
        card_type VARCHAR(20) NOT NULL DEFAULT 'debit'
          CHECK (card_type IN ('debit', 'credit', 'prepaid')),
        last_four VARCHAR(4),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_bank_cards_bank_account_id ON bank_cards(bank_account_id)
    `);
    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_bank_cards_user_id ON bank_cards(user_id)
    `);
    console.log('[migrate] ✓ bank_cards table');

    // 3. Add bank_account_id to transactions
    await db.query(`
      ALTER TABLE transactions
        ADD COLUMN IF NOT EXISTS bank_account_id UUID REFERENCES bank_accounts(id) ON DELETE SET NULL
    `);
    console.log('[migrate] ✓ transactions.bank_account_id');

    // 4. Add card_id to transactions
    await db.query(`
      ALTER TABLE transactions
        ADD COLUMN IF NOT EXISTS card_id UUID REFERENCES bank_cards(id) ON DELETE SET NULL
    `);
    console.log('[migrate] ✓ transactions.card_id');

    // 5. Update payment_method column to support all payment types
    await db.query(`
      ALTER TABLE transactions
        ALTER COLUMN payment_method TYPE VARCHAR(30)
    `);
    // Drop old check constraint if it still references only 3 values
    await db.query(`
      DO $$
      DECLARE
        v_constraint TEXT;
      BEGIN
        SELECT constraint_name INTO v_constraint
        FROM information_schema.constraint_column_usage
        WHERE table_name = 'transactions' AND column_name = 'payment_method'
          AND constraint_name LIKE '%payment_method%'
        LIMIT 1;
        IF v_constraint IS NOT NULL THEN
          EXECUTE 'ALTER TABLE transactions DROP CONSTRAINT IF EXISTS ' || quote_ident(v_constraint);
        END IF;
        -- Also try the auto-generated name pattern
        PERFORM constraint_name FROM information_schema.table_constraints
        WHERE table_name = 'transactions' AND constraint_type = 'CHECK'
          AND constraint_name LIKE '%payment%';
      END$$;
    `);
    // Drop all check constraints on payment_method and re-add the expanded one
    await db.query(`
      DO $$
      DECLARE
        r RECORD;
      BEGIN
        FOR r IN
          SELECT tc.constraint_name
          FROM information_schema.table_constraints tc
          JOIN information_schema.check_constraints cc
            ON tc.constraint_name = cc.constraint_name
          WHERE tc.table_name = 'transactions'
            AND tc.constraint_type = 'CHECK'
            AND cc.check_clause LIKE '%payment_method%'
        LOOP
          EXECUTE 'ALTER TABLE transactions DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
        END LOOP;
      END$$;
    `);
    await db.query(`
      ALTER TABLE transactions
        ADD CONSTRAINT transactions_payment_method_check
        CHECK (payment_method IN (
          'cash', 'card', 'transfer',
          'debit_card', 'credit_card', 'prepaid_card',
          'bank_transfer', 'bizum', 'paypal',
          'apple_pay', 'google_pay', 'direct_debit',
          'cheque', 'crypto', 'voucher', 'sepa', 'wire'
        ))
    `).catch(() => {
      // Constraint may already exist with the new values — ignore
    });
    console.log('[migrate] ✓ payment_method constraint expanded');

    // 6. Add external_tx_id to transactions (deduplicación de transacciones bancarias Plaid)
    await db.query(`
      ALTER TABLE transactions
        ADD COLUMN IF NOT EXISTS external_tx_id VARCHAR(255)
    `);
    // Índice único parcial (solo filas donde external_tx_id no es NULL)
    await db.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_external_tx_id
        ON transactions(external_tx_id)
        WHERE external_tx_id IS NOT NULL
    `);
    console.log('[migrate] ✓ transactions.external_tx_id');

    // 7. Ensure categories.display_order column exists (RF-16)
    // Added after initial schema creation — safe to run on existing DBs
    await db.query(`
      ALTER TABLE categories
        ADD COLUMN IF NOT EXISTS display_order INTEGER NOT NULL DEFAULT 0
    `);
    console.log('[migrate] ✓ categories.display_order');

    // 8. Create budgets table if not exists (RF-32)
    await db.query(`
      CREATE TABLE IF NOT EXISTS budgets (
        id               UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id          UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        category         VARCHAR(100)  NOT NULL,
        monthly_limit    NUMERIC(12,2) NOT NULL CHECK (monthly_limit > 0),
        rollover_enabled BOOLEAN       NOT NULL DEFAULT FALSE,
        created_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, category)
      )
    `);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id)`);
    // Add rollover_enabled to existing budgets tables that predate this migration
    await db.query(`
      ALTER TABLE budgets
        ADD COLUMN IF NOT EXISTS rollover_enabled BOOLEAN NOT NULL DEFAULT FALSE
    `);
    console.log('[migrate] ✓ budgets table + rollover_enabled');

    // 9. Add photo_base64 column to users (RF-09)
    await db.query(`
      ALTER TABLE users
        ADD COLUMN IF NOT EXISTS photo_base64 TEXT
    `);
    console.log('[migrate] ✓ users.photo_base64');

    // 10. Add widget_settings column to users
    await db.query(`
      ALTER TABLE users
        ADD COLUMN IF NOT EXISTS widget_settings JSONB
          DEFAULT '{"show_balance":true,"show_today_spent":true,"show_budget_pct":true,"dark_mode":"auto"}'::jsonb
    `);
    console.log('[migrate] ✓ users.widget_settings');

    console.log('[migrate] Migration completed successfully.');
  } catch (err) {
    console.error('[migrate] Migration failed:', err.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

migrate();