# Portfolio 2 Query Processing and Optimisation

## Queries and results

Three SQL queries were executed against `hospital_management_portfolio` in [Id-Victor_Oduduabasi_301932603_P2_Queries.sql](Id-Victor_Oduduabasi_301932603_P2_Queries.sql) and verified in [screenshots/Id-Victor_Oduduabasi_301932603_P2_Queries.png](screenshots/Id-Victor_Oduduabasi_301932603_P2_Queries.png):

1. **Unpaid Patient Invoices:** Joining `invoice` and `patient` filtered by `status = 'Unpaid'` returned 1 row: invoice `2` for Zainab Ibrahim (`+234-800-111-0003`), issued on `2026-10-12` for `17500.00`.
2. **Available Ward Beds:** Querying `bed` with `NOT EXISTS` against active admissions (`discharge_date IS NULL`) returned 2 available beds: `CAR-01` (Cardiac Ward, `30000.00`/day) and `GEN-02` (General Ward, `15000.00`/day), while excluding occupied bed `GEN-01`.
3. **Medication Prescription Usage Count:** A `LEFT JOIN` from `medication` to `prescription_item` grouped by medication returned all 3 drugs (`Amoxicillin 500mg`, `Lisinopril 10mg`, and `Paracetamol 500mg`) with `times_prescribed = 1` each, retaining all inventory items regardless of prescription count.

## Index comparison

The selective doctor-and-date query (`WHERE doctor_id = 1 AND visit_date = DATE '2026-12-31' ORDER BY time_slot ASC`) was tested on `p2_benchmark.consultation_history` before and after creating the composite B-tree index `idx_history_doctor_date_slot` on `(doctor_id, visit_date, time_slot)`. Each configuration ran once for cache warm-up followed by three measured `EXPLAIN (ANALYZE, BUFFERS)` executions (returning 10 matching rows out of 100,000 scanned rows per run, captured in [screenshots/Id-Victor_Oduduabasi_301932603_P2_BeforeIndex.png](screenshots/Id-Victor_Oduduabasi_301932603_P2_BeforeIndex.png) and [screenshots/Id-Victor_Oduduabasi_301932603_P2_AfterIndex.png](screenshots/Id-Victor_Oduduabasi_301932603_P2_AfterIndex.png)):

| State | Scan type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Median (ms) | Top-level shared buffer hits (Run 3) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Before index** | Parallel Seq Scan + Sort + Gather Merge | 13.931 | 14.086 | 13.942 | 13.942 | 1509 |
| **After index** | Index Scan (`idx_history_doctor_date_slot`) | 0.057 | 0.052 | 0.063 | 0.057 | 13 |

## Performance analysis

Before indexing, PostgreSQL scanned the entire `p2_benchmark.consultation_history` heap using a `Parallel Seq Scan` (filtering out 99,995 rows per worker), sorted the results in memory with `quicksort`, and merged them via `Gather Merge`, touching 1,509 shared buffers and taking a median of 13.942 ms. After adding the composite B-tree index on `(doctor_id, visit_date, time_slot)`, the planner switched to an `Index Scan` that jumped directly to matching entries already ordered by `time_slot`, eliminating both the full-table scan and the sort step while reducing shared buffer hits from 1,509 to 13 and median execution time to 0.057 ms. While effective for this selective lookup, single-machine timings in a shared Codespace can fluctuate with background CPU load and buffer cache state, and maintaining a multi-column B-tree index adds disk storage overhead and extra write work on every `INSERT`, `UPDATE`, or `DELETE`, meaning an index improves selective reads rather than guaranteeing faster queries in all workloads.

## Files

| File | Contents |
| :--- | :--- |
| [Id-Victor_Oduduabasi_301932603_P2_Queries.sql](Id-Victor_Oduduabasi_301932603_P2_Queries.sql) | Three analytical queries covering unpaid invoices, available beds, and medication usage counts |
| [Id-Victor_Oduduabasi_301932603_P2_Optimisation.sql](Id-Victor_Oduduabasi_301932603_P2_Optimisation.sql) | Isolated `p2_benchmark` setup, composite B-tree index creation, and `EXPLAIN (ANALYZE, BUFFERS)` benchmark script |
| [screenshots/Id-Victor_Oduduabasi_301932603_P2_Queries.png](screenshots/Id-Victor_Oduduabasi_301932603_P2_Queries.png) | Terminal output verifying the results of the three Portfolio 2 queries |
| [screenshots/Id-Victor_Oduduabasi_301932603_P2_BeforeIndex.png](screenshots/Id-Victor_Oduduabasi_301932603_P2_BeforeIndex.png) | `EXPLAIN (ANALYZE, BUFFERS)` execution plan output before creating the composite index |
| [screenshots/Id-Victor_Oduduabasi_301932603_P2_AfterIndex.png](screenshots/Id-Victor_Oduduabasi_301932603_P2_AfterIndex.png) | `EXPLAIN (ANALYZE, BUFFERS)` execution plan output after creating `idx_history_doctor_date_slot` |

## Reference

* PostgreSQL Global Development Group. (2023). *PostgreSQL 16 Documentation: Chapter 11. Indexes and Chapter 14. Performance Tips (Using EXPLAIN)*. https://www.postgresql.org/docs/16/indexes.html