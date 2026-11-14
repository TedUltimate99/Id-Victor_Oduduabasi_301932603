-- ============================================================================
-- MIT 8103 Portfolio 2: Indexing Benchmark (hospital_management_portfolio)
-- Execution guide:
--   1. Run Section 1 (Setup) ONCE.
--   2. Run Section 2 (Selective Query) ONCE to verify the 5 expected rows.
--   3. Run Section 3 (Before Indexing) ONCE for warm-up, then THREE times for measurement.
--   4. Run Section 4 (Create Index) ONCE.
--   5. Run Section 5 (After Indexing) ONCE for warm-up, then THREE times for measurement.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECTION 1: Benchmark Setup (Run Once)
-- Creates an isolated p2_benchmark schema and populates 100,000 synthetic rows.
-- ----------------------------------------------------------------------------
BEGIN;

CREATE SCHEMA p2_benchmark;

CREATE TABLE p2_benchmark.consultation_history (
    history_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES public.patient(patient_id),
    doctor_id INT NOT NULL REFERENCES public.doctor(doctor_id),
    visit_date DATE NOT NULL,
    time_slot TIME NOT NULL,
    fee NUMERIC(10, 2) NOT NULL CHECK (fee >= 0)
);

-- Generate 100,000 synthetic consultations across 10,000 dates (10 visits/day).
-- Day offset 9861 from 2000-01-01 lands on 2026-12-31 (5 rows for doctor_id = 1).
INSERT INTO p2_benchmark.consultation_history (patient_id, doctor_id, visit_date, time_slot, fee)
SELECT
    ((g - 1) % 3) + 1 AS patient_id,
    ((g - 1) % 2) + 1 AS doctor_id,
    DATE '2000-01-01' + ((g - 1) / 10) AS visit_date,
    TIME '08:00:00' + (((g - 1) % 10) * INTERVAL '30 minutes') AS time_slot,
    CASE WHEN ((g - 1) % 2) = 0 THEN 10000.00 ELSE 15000.00 END AS fee
FROM generate_series(1, 100000) AS g;

COMMIT;

-- Refresh PostgreSQL planner statistics for the new 100,000-row table
ANALYZE p2_benchmark.consultation_history;

-- Verify total row count (expected: 100000)
SELECT COUNT(*) AS total_rows
FROM p2_benchmark.consultation_history;


-- ----------------------------------------------------------------------------
-- SECTION 2: Selective Query Verification (Run Once)
-- Retrieves the 5 consultations for Doctor 1 on 2026-12-31 (history_ids 98611..98619).
-- ----------------------------------------------------------------------------
SELECT
    history_id,
    patient_id,
    doctor_id,
    visit_date,
    time_slot,
    fee
FROM p2_benchmark.consultation_history
WHERE doctor_id = 1
  AND visit_date = DATE '2026-12-31'
ORDER BY time_slot ASC;


-- ----------------------------------------------------------------------------
-- SECTION 3: Execution Plan Before Indexing
-- Run ONCE for buffer warm-up, then THREE times for measurement.
-- ----------------------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    history_id,
    patient_id,
    doctor_id,
    visit_date,
    time_slot,
    fee
FROM p2_benchmark.consultation_history
WHERE doctor_id = 1
  AND visit_date = DATE '2026-12-31'
ORDER BY time_slot ASC;


-- ----------------------------------------------------------------------------
-- SECTION 4: Create Composite B-Tree Index (Run Once)
-- Indexes (doctor_id, visit_date, time_slot) to eliminate full-table scan and sort.
-- ----------------------------------------------------------------------------
CREATE INDEX idx_history_doctor_date_slot
    ON p2_benchmark.consultation_history (doctor_id, visit_date, time_slot);

-- Refresh planner statistics so PostgreSQL recognises the new B-tree index
ANALYZE p2_benchmark.consultation_history;


-- ----------------------------------------------------------------------------
-- SECTION 5: Execution Plan After Indexing
-- Run ONCE for buffer warm-up, then THREE times for measurement.
-- ----------------------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    history_id,
    patient_id,
    doctor_id,
    visit_date,
    time_slot,
    fee
FROM p2_benchmark.consultation_history
WHERE doctor_id = 1
  AND visit_date = DATE '2026-12-31'
ORDER BY time_slot ASC;