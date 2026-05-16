-- LabTrack LIMS - Seed Data
-- Domain: Nicotine product testing (inspired by Labstat)
-- Run after initial schema: psql labtrack < migrations/002_seed_data.sql
-- Default password for all seed users: "password123"

-- Users
INSERT INTO users (username, email, password, role) VALUES
    ('admin',    'admin@labtrack.local',    '$2b$12$LJ3m4qs2XSZ8BfEYB0hXYOqYpF1V3kZBwGJ7p5MwTqJpFoWMKQXi2', 'admin'),
    ('jsmith',   'jsmith@labtrack.local',   '$2b$12$LJ3m4qs2XSZ8BfEYB0hXYOqYpF1V3kZBwGJ7p5MwTqJpFoWMKQXi2', 'analyst'),
    ('mgarcia',  'mgarcia@labtrack.local',  '$2b$12$LJ3m4qs2XSZ8BfEYB0hXYOqYpF1V3kZBwGJ7p5MwTqJpFoWMKQXi2', 'technician')
ON CONFLICT (username) DO NOTHING;

-- Test Definitions (nicotine product testing)
INSERT INTO test_definitions (name, category, unit, min_range, max_range, method) VALUES
    ('Nicotine Content',         'chemistry',      'mg/g',      0,     50.0,   'ISO 10315'),
    ('Tar Yield',                'chemistry',      'mg/cig',    0,     30.0,   'ISO 4387'),
    ('Carbon Monoxide Yield',    'chemistry',      'mg/cig',    0,     25.0,   'ISO 8454'),
    ('TSNAs (Tobacco-Specific Nitrosamines)', 'chemistry', 'ng/g', 0,  5000.0, 'LC-MS/MS'),
    ('Moisture Content',         'physical',       '%',         8.0,   16.0,   'ISO 6488'),
    ('pH of Smoke',              'chemistry',      'pH',        5.5,   8.5,    'CORESTA 69'),
    ('Menthol Content',          'chemistry',      'mg/g',      0,     40.0,   'GC-FID'),
    ('Heavy Metals (Lead)',      'toxicology',     'µg/g',      0,     2.0,    'ICP-MS'),
    ('Heavy Metals (Cadmium)',   'toxicology',     'µg/g',      0,     1.5,    'ICP-MS'),
    ('Heavy Metals (Arsenic)',   'toxicology',     'µg/g',      0,     1.0,    'ICP-MS'),
    ('Benzo[a]pyrene',           'chemistry',      'ng/cig',    0,     50.0,   'GC-MS'),
    ('Formaldehyde',             'chemistry',      'µg/cig',    0,     100.0,  'HPLC-UV'),
    ('Acetaldehyde',             'chemistry',      'µg/cig',    0,     1000.0, 'HPLC-UV'),
    ('Propylene Glycol',         'chemistry',      'mg/mL',     0,     90.0,   'GC-FID'),
    ('Vegetable Glycerin',       'chemistry',      'mg/mL',     0,     90.0,   'GC-FID'),
    ('Puff Count',               'physical',       'puffs',     0,     500.0,  'ISO 20768'),
    ('Draw Resistance',          'physical',       'mmWG',      50,    150.0,  'ISO 6565'),
    ('Filter Ventilation',       'physical',       '%',         0,     80.0,   'ISO 9512'),
    ('Tobacco Weight',           'physical',       'g',         0.5,   1.2,    'Gravimetric'),
    ('Humectant Content',        'chemistry',      '%',         0,     5.0,    'GC-FID')
ON CONFLICT DO NOTHING;

-- Sample data (nicotine products only)
INSERT INTO samples (sample_code, client_name, sample_type, status, received_by, notes) VALUES
    ('LAB-2026-0001', 'Imperial Tobacco Group',     'cigarette',       'completed',  1, 'Regular king-size brand compliance testing'),
    ('LAB-2026-0002', 'VaporTech Inc.',              'e-liquid',        'in_testing', 1, 'Mango flavor e-liquid, nicotine salt 20mg/mL'),
    ('LAB-2026-0003', 'Heritage Tobacco Ltd.',       'smokeless',       'completed',  2, 'Chewing tobacco, annual regulatory submission'),
    ('LAB-2026-0004', 'NicoPatch Solutions',         'nicotine_patch',  'received',   3, 'Transdermal patch 21mg, stability testing'),
    ('LAB-2026-0005', 'CloudNine Vapes',             'e-liquid',        'received',   2, 'Tobacco flavor 12mg/mL, EU TPD compliance'),
    ('LAB-2026-0006', 'Pacific Leaf Corp.',          'cigarette',       'in_testing', 1, 'Light variant, reduced tar claim verification'),
    ('LAB-2026-0007', 'Nordic Snus AB',              'snus',            'received',   3, 'Pouched snus, mint flavor, Swedish market'),
    ('LAB-2026-0008', 'HeatWave Technologies',       'heated_tobacco',  'in_testing', 2, 'Heat-not-burn stick, PMTA submission testing')
ON CONFLICT (sample_code) DO NOTHING;

-- Assign tests to samples
INSERT INTO sample_tests (sample_id, test_id, assigned_to, status, result_value, pass_fail, tested_at, approved_by, approved_at) VALUES
    -- Imperial Tobacco cigarette (completed - standard cigarette panel)
    (1, 1, 3, 'completed', 12.4,  'pass', NOW() - INTERVAL '3 days', 2, NOW() - INTERVAL '2 days'),
    (1, 2, 3, 'completed', 10.8,  'pass', NOW() - INTERVAL '3 days', 2, NOW() - INTERVAL '2 days'),
    (1, 3, 3, 'completed', 9.2,   'pass', NOW() - INTERVAL '3 days', 2, NOW() - INTERVAL '2 days'),
    (1, 5, 3, 'completed', 12.1,  'pass', NOW() - INTERVAL '3 days', 2, NOW() - INTERVAL '2 days'),
    (1, 16, 3, 'completed', 8.0,  'pass', NOW() - INTERVAL '3 days', 2, NOW() - INTERVAL '2 days'),

    -- VaporTech e-liquid (in testing - e-liquid panel)
    (2, 1, 3, 'completed', 19.8,   'pass', NOW() - INTERVAL '1 day', NULL, NULL),
    (2, 14, 3, 'in_progress', NULL, NULL,  NULL, NULL, NULL),
    (2, 15, 3, 'pending',    NULL,  NULL,  NULL, NULL, NULL),
    (2, 8, 3, 'pending',     NULL,  NULL,  NULL, NULL, NULL),

    -- Heritage smokeless (completed)
    (3, 1, 3, 'completed', 8.6,    'pass', NOW() - INTERVAL '5 days', 2, NOW() - INTERVAL '4 days'),
    (3, 4, 3, 'completed', 890.0,  'pass', NOW() - INTERVAL '5 days', 2, NOW() - INTERVAL '4 days'),
    (3, 5, 3, 'completed', 14.2,   'pass', NOW() - INTERVAL '5 days', 2, NOW() - INTERVAL '4 days'),
    (3, 6, 3, 'completed', 7.8,    'pass', NOW() - INTERVAL '5 days', 2, NOW() - INTERVAL '4 days'),

    -- Pacific Leaf cigarette (in testing - full smoke analysis)
    (6, 1, 3, 'completed',    8.1,  'pass', NOW() - INTERVAL '1 day', NULL, NULL),
    (6, 2, 3, 'in_progress',  NULL,  NULL,  NULL, NULL, NULL),
    (6, 3, 3, 'pending',      NULL,  NULL,  NULL, NULL, NULL),
    (6, 11, 3, 'pending',     NULL,  NULL,  NULL, NULL, NULL),
    (6, 12, 3, 'pending',     NULL,  NULL,  NULL, NULL, NULL),
    (6, 17, 3, 'pending',     NULL,  NULL,  NULL, NULL, NULL),
    (6, 18, 3, 'pending',     NULL,  NULL,  NULL, NULL, NULL),

    -- HeatWave heated tobacco (in testing - PMTA panel)
    (8, 1, 3, 'in_progress',  NULL,  NULL,  NULL, NULL, NULL),
    (8, 4, 3, 'pending',      NULL,  NULL,  NULL, NULL, NULL),
    (8, 8, 3, 'pending',      NULL,  NULL,  NULL, NULL, NULL),
    (8, 9, 3, 'pending',      NULL,  NULL,  NULL, NULL, NULL),
    (8, 10, 3, 'pending',     NULL,  NULL,  NULL, NULL, NULL),
    (8, 12, 3, 'pending',     NULL,  NULL,  NULL, NULL, NULL),
    (8, 13, 3, 'pending',     NULL,  NULL,  NULL, NULL, NULL)
ON CONFLICT DO NOTHING;
