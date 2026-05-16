-- LabTrack LIMS - Initial Schema
-- Run: psql labtrack < migrations/001_initial_schema.sql

CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50) UNIQUE NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,
    role        VARCHAR(20) DEFAULT 'technician'
                CHECK (role IN ('technician', 'analyst', 'admin')),
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS samples (
    id            SERIAL PRIMARY KEY,
    sample_code   VARCHAR(30) UNIQUE NOT NULL,
    client_name   VARCHAR(100) NOT NULL,
    sample_type   VARCHAR(50) NOT NULL,
    status        VARCHAR(20) DEFAULT 'received'
                  CHECK (status IN ('received', 'in_testing', 'completed', 'rejected')),
    received_at   TIMESTAMP DEFAULT NOW(),
    received_by   INTEGER REFERENCES users(id),
    notes         TEXT DEFAULT '',
    created_at    TIMESTAMP DEFAULT NOW(),
    updated_at    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS test_definitions (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    category      VARCHAR(50),
    unit          VARCHAR(30),
    min_range     DECIMAL,
    max_range     DECIMAL,
    method        VARCHAR(100),
    created_at    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sample_tests (
    id              SERIAL PRIMARY KEY,
    sample_id       INTEGER REFERENCES samples(id) ON DELETE CASCADE,
    test_id         INTEGER REFERENCES test_definitions(id),
    assigned_to     INTEGER REFERENCES users(id),
    status          VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    result_value    DECIMAL,
    result_text     TEXT,
    pass_fail       VARCHAR(15)
                    CHECK (pass_fail IN ('pass', 'fail', 'inconclusive')),
    tested_at       TIMESTAMP,
    approved_by     INTEGER REFERENCES users(id),
    approved_at     TIMESTAMP,
    notes           TEXT DEFAULT '',
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id),
    action      VARCHAR(50) NOT NULL,
    entity_type VARCHAR(30),
    entity_id   INTEGER,
    details     JSONB DEFAULT '{}',
    created_at  TIMESTAMP DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_samples_status ON samples(status);
CREATE INDEX IF NOT EXISTS idx_samples_type ON samples(sample_type);
CREATE INDEX IF NOT EXISTS idx_samples_client ON samples(client_name);
CREATE INDEX IF NOT EXISTS idx_sample_tests_sample ON sample_tests(sample_id);
CREATE INDEX IF NOT EXISTS idx_sample_tests_status ON sample_tests(status);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at);
