-- YOB K BUSINESS - Initial Schema
-- PostgreSQL Migration 001

-- ============================================
-- EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ENUMS
-- ============================================
CREATE TYPE user_role AS ENUM ('direction', 'superviseur', 'comptable', 'partenaire');
CREATE TYPE producer_status AS ENUM ('actif', 'enFormation', 'suspendu');
CREATE TYPE kit_status AS ENUM ('rembourse', 'subventionne');
CREATE TYPE land_tenure_status AS ENUM ('secured', 'pending', 'disputed', 'unknown');
CREATE TYPE transaction_type AS ENUM ('income', 'expense');
CREATE TYPE project_status AS ENUM ('planned', 'inProgress', 'completed', 'onHold');

-- ============================================
-- USERS (Authentication & RBAC)
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    role user_role NOT NULL DEFAULT 'superviseur',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ============================================
-- PRODUCERS
-- ============================================
CREATE TABLE producers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    locality VARCHAR(255) NOT NULL,
    photo_url TEXT,
    id_document_url TEXT,
    cultivated_area DECIMAL(10, 2) NOT NULL DEFAULT 0, -- hectares
    status producer_status NOT NULL DEFAULT 'actif',
    crop_history TEXT[] DEFAULT '{}',
    production_level DECIMAL(10, 2),
    total_contributions DECIMAL(15, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_producers_status ON producers(status);
CREATE INDEX idx_producers_locality ON producers(locality);

-- ============================================
-- PARCELS
-- ============================================
CREATE TABLE parcels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    surface_area DECIMAL(10, 2) NOT NULL, -- hectares
    crop_type VARCHAR(100) NOT NULL,
    tenure_status land_tenure_status NOT NULL DEFAULT 'unknown',
    commode_survey_done BOOLEAN NOT NULL DEFAULT FALSE,
    document_urls TEXT[] DEFAULT '{}',
    producer_id UUID REFERENCES producers(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_parcels_producer ON parcels(producer_id);
CREATE INDEX idx_parcels_crop ON parcels(crop_type);

-- ============================================
-- BOREHOLES & INFRASTRUCTURE
-- ============================================
CREATE TABLE boreholes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    cost DECIMAL(15, 2) NOT NULL DEFAULT 0,
    contractor VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    progress_percent INTEGER NOT NULL DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
    status project_status NOT NULL DEFAULT 'planned',
    photo_urls TEXT[] DEFAULT '{}',
    maintenance_notes TEXT,
    last_maintenance_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_boreholes_status ON boreholes(status);

-- ============================================
-- AGRICULTURAL KITS
-- ============================================
CREATE TABLE agricultural_kits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kit_type VARCHAR(255) NOT NULL,
    distribution_date DATE NOT NULL,
    beneficiary_id UUID NOT NULL REFERENCES producers(id) ON DELETE CASCADE,
    value DECIMAL(15, 2) NOT NULL DEFAULT 0,
    status kit_status NOT NULL DEFAULT 'subventionne',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_kits_beneficiary ON agricultural_kits(beneficiary_id);
CREATE INDEX idx_kits_status ON agricultural_kits(status);

-- ============================================
-- TRAININGS
-- ============================================
CREATE TABLE trainings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255) NOT NULL,
    evaluation_notes TEXT,
    certification_issued BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Training attendance (many-to-many)
CREATE TABLE training_attendees (
    training_id UUID NOT NULL REFERENCES trainings(id) ON DELETE CASCADE,
    producer_id UUID NOT NULL REFERENCES producers(id) ON DELETE CASCADE,
    attended BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (training_id, producer_id)
);

-- ============================================
-- TRANSACTIONS (Finance)
-- ============================================
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type transaction_type NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100),
    reference_id UUID, -- linked entity
    date DATE NOT NULL,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_category ON transactions(category);

-- ============================================
-- INVESTORS
-- ============================================
CREATE TABLE investors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    company VARCHAR(255),
    total_invested DECIMAL(15, 2) NOT NULL DEFAULT 0,
    project_id UUID,
    project_name VARCHAR(255),
    expected_return DECIMAL(5, 2), -- percentage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_investors_email ON investors(email);

-- ============================================
-- CONTRACTS (Producer contracts)
-- ============================================
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    producer_id UUID NOT NULL REFERENCES producers(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    document_url TEXT,
    signed_date DATE,
    expiry_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_contracts_producer ON contracts(producer_id);

-- ============================================
-- UPDATED_AT TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_producers_updated_at BEFORE UPDATE ON producers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_parcels_updated_at BEFORE UPDATE ON parcels FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_boreholes_updated_at BEFORE UPDATE ON boreholes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_kits_updated_at BEFORE UPDATE ON agricultural_kits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trainings_updated_at BEFORE UPDATE ON trainings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_investors_updated_at BEFORE UPDATE ON investors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED: Default admin user (password: admin123)
-- bcrypt hash for 'admin123'
-- ============================================
INSERT INTO users (email, password_hash, full_name, role)
VALUES (
    'admin@yobkbusiness.com',
    '$2b$12$LJ3m4ys3Lk0TSwHBQpOhNODXNSJkLz3cH7Zh5bDJINE5v8RB.IgG.',
    'Administrateur YOB',
    'direction'
);
