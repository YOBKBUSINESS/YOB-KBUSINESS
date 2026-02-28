-- ============================================================
-- Performance Indexes for YOB K Business
-- Run after initial schema migration.
-- ============================================================

-- Producers
CREATE INDEX IF NOT EXISTS idx_producers_status ON producers (status);
CREATE INDEX IF NOT EXISTS idx_producers_locality ON producers (locality);
CREATE INDEX IF NOT EXISTS idx_producers_created ON producers (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_producers_search
  ON producers USING gin (to_tsvector('french', full_name || ' ' || COALESCE(phone, '') || ' ' || locality));

-- Parcels
CREATE INDEX IF NOT EXISTS idx_parcels_producer ON parcels (producer_id);
CREATE INDEX IF NOT EXISTS idx_parcels_status ON parcels (tenure_status);
CREATE INDEX IF NOT EXISTS idx_parcels_area ON parcels (area);

-- Transactions
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions (type);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions (category);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_created ON transactions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_amount ON transactions (amount);

-- Investors
CREATE INDEX IF NOT EXISTS idx_investors_project ON investors (project_id);
CREATE INDEX IF NOT EXISTS idx_investors_total ON investors (total_invested DESC);
CREATE INDEX IF NOT EXISTS idx_investors_created ON investors (created_at DESC);

-- Trainings
CREATE INDEX IF NOT EXISTS idx_trainings_date ON trainings (date DESC);
CREATE INDEX IF NOT EXISTS idx_trainings_status ON trainings (status);

-- Kits
CREATE INDEX IF NOT EXISTS idx_kits_status ON kits (status);
CREATE INDEX IF NOT EXISTS idx_kits_producer ON kits (producer_id);
CREATE INDEX IF NOT EXISTS idx_kits_distributed ON kits (distributed_at DESC);

-- Boreholes
CREATE INDEX IF NOT EXISTS idx_boreholes_status ON boreholes (status);
CREATE INDEX IF NOT EXISTS idx_boreholes_locality ON boreholes (locality);

-- ============================================================
-- Composite indexes for common JOIN + filter queries
-- ============================================================

-- Dashboard: active producers with total contributions
CREATE INDEX IF NOT EXISTS idx_producers_active_contributions
  ON producers (status, total_contributions DESC)
  WHERE status = 'actif';

-- Finance report: income/expense by date range
CREATE INDEX IF NOT EXISTS idx_transactions_type_date
  ON transactions (type, date DESC);

-- Training attendees: training lookups with date filter
CREATE INDEX IF NOT EXISTS idx_trainings_date_status
  ON trainings (date DESC, status);
