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

# MIT 8103 Portfolio 1 Consistency Audit

## 1. Summary Verdict
Your 9 tables, columns, data types, primary keys, foreign keys, unique constraints, and sample data are **100% consistent** across all 7 files. However, there are **two minor rule-numbering/comment mismatches** between `README` and `Schema`/`Design` that you should clean up so an examiner does not spot a numbering shift.

---

## 2. Audit Findings & Quick Fixes

| Category | Status | Details & Action Needed |
| :--- | :--- | :--- |
| **File & Database Naming** | **Pass** | All 7 filenames follow `Id-Victor_Oduduabasi_301932603_P1_<Artifact>` cleanly, and the database name `hospital_management_portfolio` matches everywhere. |
| **Rule Numbering (8 vs. 9 rules)** | **Fix Needed** | In `README`, you have **8 numbered rules** (1 to 8). Earlier in `Design` and `ERDiagram`, Rule 2 was a blank line, which shifted Rules 3–9 down by one number in `Schema` comments (e.g., `Schema` comments say `(Rules 3 & 4)` for `admission`, `(Rule 5)` for `consultation`, `(Rules 6 & 7)` for `prescription`, and `(Rules 8 & 9)` for `invoice`).<br>**Fix:** Update the rule numbers inside the SQL comments of `Schema.sql` (and `Design.md` if you haven't removed the blank Rule 2) so they match the **1–8** numbering in `README.md` (`Admission` = Rules 2 & 3, `Consultation` = Rule 4, `Prescription` = Rules 5 & 6, `Invoice` = Rules 7 & 8). |
| **Table & Column Names** | **Pass** | Every table (`patient`, `doctor`, `bed`, `medication`, `admission`, `consultation`, `prescription`, `prescription_item`, `invoice`) and every column name matches identically across `Design`, `ERDiagram`, `Normalisation`, `Schema`, `SampleData`, and `ConstraintTests`. |
| **Data Types & Keys** | **Pass** | `SERIAL` PKs, `INT` FKs, `VARCHAR` lengths, `NUMERIC(10,2)` currency fields, `DATE` and `TIME` types, `UNIQUE` keys, and partial unique indexes (`idx_active_bed_admission`, `idx_active_patient_admission`) match across `Design`, `ERDiagram`, and `Schema`. |
| **Constraint Test Comments** | **Minor Note** | In `ConstraintTests.sql`, Test 12 expects `invoice_status_check`, whereas PostgreSQL evaluated `chk_invoice_settlement` first (which you already explained accurately in `README.md`). Optionally update the `-- Expected error:` comment above Test 12 in `ConstraintTests.sql` to `chk_invoice_settlement` so the file comment matches the exact terminal output. |
| **Row Counts & Screenshots** | **Pass** | The 9 row counts in `README.md` (`admission: 2`, `bed: 3`, `consultation: 2`, `doctor: 2`, `invoice: 2`, `medication: 3`, `patient: 3`, `prescription: 2`, `prescription_item: 3`) match `SampleData.sql` and all 13 `ConstraintTests.sql` errors are accounted for. |

---

## 3. Exact Comment Updates for `Id-Victor_Oduduabasi_301932603_P1_Schema.sql`
If you want your SQL comments in `Schema.sql` to align 1-to-1 with the 8 rules in `README.md`, update only the rule numbers in those comments (no table changes needed):

* `public.bed`: change `(Rule 3)` $\rightarrow$ `(Rule 2)`
* `public.admission` & partial indexes: change `(Rules 3 & 4)` $\rightarrow$ `(Rules 2 & 3)`
* `public.consultation`: change `(Rule 5)` $\rightarrow$ `(Rule 4)`
* `public.prescription`: change `(Rules 6 & 7)` $\rightarrow$ `(Rules 5 & 6)`
* `public.prescription_item`: change `(Rule 6)` $\rightarrow$ `(Rule 5)`
* `public.invoice`: change `(Rules 8 & 9)` $\rightarrow$ `(Rules 7 & 8)`
* Bottom note: change `(Rule 7)` $\rightarrow$ `(Rule 6)` and `(Rule 6)` $\rightarrow$ `(Rule 5)`