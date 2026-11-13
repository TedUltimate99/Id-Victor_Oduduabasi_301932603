# Portfolio 1 Database Design and Modelling

## Case study

A hospital management system tracks patients, doctors, consultations, inpatient ward beds, pharmacy prescriptions, and patient billing. Staff manage registrations, bed admissions, medication dispensing, and invoices, while doctors conduct consultations and issue prescriptions. Staff also monitor available ward beds and unpaid invoices.

## Users

Patients attend consultations, occupy ward beds, receive medications, and pay invoices. Receptionists register patients, book consultations, assign ward beds, and process payments. Doctors conduct consultations, request admissions, and issue prescriptions. Pharmacists dispense prescribed medications and update drug inventory.

## Main operations

Register a patient; schedule a consultation; admit and discharge a patient to a ward bed; issue and dispense a prescription; generate an invoice and record payment; view available beds and unpaid invoices.

## Business rules

1. Each patient has a unique patient ID, and each doctor has a unique staff ID and medical license number.

2. Each bed has a unique bed number, assigned to a named ward, and can hold at most one active admission at a time.

3. A patient can have at most one active ward admission, and the discharge date cannot be earlier than the admission date.

4. Each consultation links one patient to one doctor for a specific date and time slot, preventing double-booking of either party.

5. Each prescription links one consultation to one or more listed medications, capturing quantity and dosage.

6. A prescription can be dispensed only once, and the dispensed quantity cannot exceed available medication stock.

7. Each invoice belongs to one patient and records a total amount covering consultation, ward stay, and medication charges.

8. Invoice status defaults to Unpaid upon creation and changes to Paid only when the full payment date and amount are recorded.

## Scope

One hospital facility using fictional records across patient registration, outpatient consultations, inpatient bed admissions, pharmacy dispensing, and billing. Separate ward tables, insurance claims, lab tests, surgical scheduling, and user authentication are outside this scope.

## Design and implementation files

| File | Contents |
| :--- | :--- |
| [Id-Victor_Oduduabasi_301932603_P1_Design.md](Id-Victor_Oduduabasi_301932603_P1_Design.md) | Entity definitions, PostgreSQL data types, keys, relationships, rule mapping, and design assumptions |
| [Id-Victor_Oduduabasi_301932603_P1_ERDiagram.md](Id-Victor_Oduduabasi_301932603_P1_ERDiagram.md) | Mermaid entity-relationship diagram, key notation, cardinalities, and optional field notes |
| [Id-Victor_Oduduabasi_301932603_P1_Normalisation.md](Id-Victor_Oduduabasi_301932603_P1_Normalisation.md) | Step-by-step normalisation from 0NF to 3NF using fictional hospital records |
| [Id-Victor_Oduduabasi_301932603_P1_Schema.sql](Id-Victor_Oduduabasi_301932603_P1_Schema.sql) | PostgreSQL 16 DDL script creating all 9 tables, keys, partial unique indexes, and CHECK constraints |
| [Id-Victor_Oduduabasi_301932603_P1_SampleData.sql](Id-Victor_Oduduabasi_301932603_P1_SampleData.sql) | Transactional script inserting valid fictional records across all 9 tables |
| [Id-Victor_Oduduabasi_301932603_P1_ConstraintTests.sql](Id-Victor_Oduduabasi_301932603_P1_ConstraintTests.sql) | Deliberately invalid `INSERT` statements testing constraints followed by a 9-table row-count query |
| [screenshots/](screenshots/) | Terminal captures of database connection, table creation, data insertion, constraint errors, and final row counts (`Id-Victor_Oduduabasi_301932603_P1_DatabaseConnection.png`, `Id-Victor_Oduduabasi_301932603_P1_TableCreation.png`, `Id-Victor_Oduduabasi_301932603_P1_TableList.png`, `Id-Victor_Oduduabasi_301932603_P1_Constraints1.png`–`3.png`, `Id-Victor_Oduduabasi_301932603_P1_InsertData1.png`–`2.png`, `Id-Victor_Oduduabasi_301932603_P1_ConstraintTests1.png`–`2.png`, and `Id-Victor_Oduduabasi_301932603_P1_RecordCounts.png`) |

## Implementation

The database `hospital_management_portfolio` runs on PostgreSQL inside the `workspaces/Id-Victor_Oduduabasi_301932603` Codespace. The schema script creates nine tables in the `public` schema (`patient`, `doctor`, `bed`, `medication`, `admission`, `consultation`, `prescription`, `prescription_item`, and `invoice`) using `SERIAL` primary keys, foreign key references, `NOT NULL` requirements, `UNIQUE` constraints on natural identifiers and time slots, `CHECK` constraints for valid numeric ranges, date order, and invoice settlement, and partial unique indexes (`WHERE discharge_date IS NULL`) on `admission(bed_id)` and `admission(patient_id)` to prevent overlapping active ward stays.

Valid fictional records were loaded inside a single `BEGIN`/`COMMIT` transaction in `Id-Victor_Oduduabasi_301932603_P1_SampleData.sql`, looking up generated parent IDs via unique values. The negative tests in `Id-Victor_Oduduabasi_301932603_P1_ConstraintTests.sql` were executed individually in `psql` outside a transaction block so that each rejected `INSERT` could be observed without aborting subsequent tests, followed by a `UNION ALL` row-count query across all nine tables.

## Test results

All valid sample records were accepted into the nine tables, covering active and discharged ward admissions, dispensed and pending prescriptions, and paid and unpaid invoices. All 13 deliberately invalid `INSERT` statements in `Id-Victor_Oduduabasi_301932603_P1_ConstraintTests.sql` were rejected with the expected PostgreSQL errors: `NOT NULL` violation on `patient.full_name`; duplicate `UNIQUE` violations on `doctor.staff_number` (`DOC-101`) and `bed.bed_number` (`GEN-01`); `CHECK` failure on negative `medication.stock_qty` (`-5`); foreign key failure for non-existent `patient_id` (`999999`) in `admission`; partial unique index violations on `idx_active_bed_admission` and `idx_active_patient_admission`; `chk_admission_dates` failure when `discharge_date` preceded `admit_date`; composite slot conflicts on `uq_doctor_slot` and `uq_patient_slot`; `prescription_item_quantity_check` failure for zero quantity; and `chk_invoice_settlement` failures for an invalid `'Partial'` status and an underpaid `'Paid'` invoice.

After all invalid statements failed, the final row counts matched the exact expected baseline across every table: `admission` (2), `bed` (3), `consultation` (2), `doctor` (2), `invoice` (2), `medication` (3), `patient` (3), `prescription` (2), and `prescription_item` (3).

Table definitions alone do not enforce cross-table stock checks, one-time dispensing state transitions (Rule 6), or requiring at least one item per prescription (Rule 5); those operational checks remain untested at the DDL level because they require application transactions or database triggers.