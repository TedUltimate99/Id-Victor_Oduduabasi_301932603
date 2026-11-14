# Portfolio 3 Transactions and Concurrency

## Commit and rollback

In [Id-Victor_Oduduabasi_301932603_P3_Transactions.sql](Id-Victor_Oduduabasi_301932603_P3_Transactions.sql), an atomic `BEGIN`–`COMMIT` transaction dispensed pending `prescription_id = 2` (`dispensed_date = '2026-10-15'`) and reduced `Lisinopril 10mg` (`medication_id = 3`) `stock_qty` from `50` to `49` (`UPDATE 1` each), while a repeat `UPDATE` returned `UPDATE 0` because the `WHERE dispensed_date IS NULL` guard prevented double-dispensing (Rule 6). A second transaction validly settled `invoice_id = 2` in full (`17500.00`, `UPDATE 1`) before a deliberate underpayment (`paid_amount = 10000.00`) violated `chk_invoice_settlement` (Rule 8), and `ROLLBACK` undid both statements so `invoice_id = 2` remained `Unpaid` with `NULL` payment fields.

## Isolation and concurrency control

In [Id-Victor_Oduduabasi_301932603_P3_SessionA.sql](Id-Victor_Oduduabasi_301932603_P3_SessionA.sql) and [Id-Victor_Oduduabasi_301932603_P3_SessionB.sql](Id-Victor_Oduduabasi_301932603_P3_SessionB.sql), two independent `psql` connections ran at `READ COMMITTED` isolation (`SHOW transaction_isolation` returned `read committed` in both). Session A inserted an uncommitted active admission (`INSERT 0 1`) for `Adaeze Nwosu` into free ward bed `GEN-02` (`2026-10-16`), and Session B's initial `SELECT` still saw `GEN-02` as unoccupied (`NULL`) because `READ COMMITTED` prevents dirty reads, causing Session B to block while waiting on the partial unique index `idx_active_bed_admission` when it attempted to admit `Zainab Ibrahim` into the same bed. Once Session A executed `COMMIT`, Session B immediately unblocked and failed with `ERROR: duplicate key value violates unique constraint "idx_active_bed_admission"` (`Key (bed_id)=(2) already exists`), rolled back, and verified that only `Adaeze Nwosu` (`admission_id = 7`) occupied `GEN-02` (Rule 2).

## Conclusion

Transactions, `CHECK` constraints, and partial unique indexes protect single-row and unique-key invariants reliably under `READ COMMITTED`, ensuring all-or-nothing updates and blocking duplicate active bed assignments. However, isolation alone does not prevent every conflicting operation across separate tables—such as concurrent dispensing workflows checking `medication.stock_qty` before updating inventory—which still require explicit row-level locks (`SELECT ... FOR UPDATE`), triggers, or `SERIALIZABLE` transactions with retry logic.

## Files

| File | Contents |
| :--- | :--- |
| [Id-Victor_Oduduabasi_301932603_P3_Transactions.sql](Id-Victor_Oduduabasi_301932603_P3_Transactions.sql) | Single-session `COMMIT`, repeat-prevention guard, `ROLLBACK` on constraint violation, and verification queries |
| [Id-Victor_Oduduabasi_301932603_P3_SessionA.sql](Id-Victor_Oduduabasi_301932603_P3_SessionA.sql) | Session A `READ COMMITTED` transaction inserting and committing an active admission for `Adaeze Nwosu` in bed `GEN-02` |
| [Id-Victor_Oduduabasi_301932603_P3_SessionB.sql](Id-Victor_Oduduabasi_301932603_P3_SessionB.sql) | Session B `READ COMMITTED` transaction demonstrating snapshot visibility, index lock wait, `idx_active_bed_admission` error, `ROLLBACK`, and final check |
| [screenshots/Id-Victor_Oduduabasi_301932603_P3_CommitRollback1.png](screenshots/Id-Victor_Oduduabasi_301932603_P3_CommitRollback1.png) | Terminal output showing starting records and the committed prescription dispense and stock deduction |
| [screenshots/Id-Victor_Oduduabasi_301932603_P3_CommitRollback2.png](screenshots/Id-Victor_Oduduabasi_301932603_P3_CommitRollback2.png) | Terminal output showing the repeat-prevention `UPDATE 0`, `chk_invoice_settlement` violation, and `ROLLBACK` |
| [screenshots/Id-Victor_Oduduabasi_301932603_P3_CommitRollback3.png](screenshots/Id-Victor_Oduduabasi_301932603_P3_CommitRollback3.png) | Terminal output verifying final persisted prescription state and reverted `Unpaid` invoice state |
| [screenshots/Id-Victor_Oduduabasi_301932603_P3_SessionsWaiting.png](screenshots/Id-Victor_Oduduabasi_301932603_P3_SessionsWaiting.png) | Side-by-side terminals showing Session A holding an uncommitted insert on `GEN-02` while Session B waits |
| [screenshots/Id-Victor_Oduduabasi_301932603_P3_ConcurrencyResult.png](screenshots/Id-Victor_Oduduabasi_301932603_P3_ConcurrencyResult.png) | Side-by-side terminals showing Session A's `COMMIT`, Session B's `idx_active_bed_admission` error, `ROLLBACK`, and final occupancy check |

## References

* PostgreSQL Global Development Group. (2023). *PostgreSQL 16 Documentation: Chapter 13. Concurrency Control (Transaction Isolation and Explicit Locking)*. https://www.postgresql.org/docs/16/mvcc.html