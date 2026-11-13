# Hospital Management System Database Design

## 1. Entities
Nine entities are necessary to support outpatient consultations, inpatient admissions, pharmacy dispensing, and billing without mixing unrelated concepts. Fewer entities would force repeating groups or lose itemised prescription history.

* **Patient**: individuals receiving hospital care.
* **Doctor**: medical staff conducting consultations.
* **Bed**: physical inpatient ward beds.
* **Admission**: inpatient stays linking patients to beds.
* **Consultation**: scheduled outpatient visits between patients and doctors.
* **Medication**: pharmacy drug inventory.
* **Prescription**: medication orders issued from consultations.
* **Prescription_Item**: individual drugs, quantities, and dosages on a prescription (a linking table resolving the many-to-many link between prescriptions and medications).
* **Invoice**: patient bills tracking charges and settlement.

## 2. Attributes and keys
* **Patient**: `patient_id` (`SERIAL`, PK), `full_name` (`VARCHAR(100)`, required), `phone` (`VARCHAR(20)`, required), `date_of_birth` (`DATE`, required).
* **Doctor**: `doctor_id` (`SERIAL`, PK), `staff_number` (`VARCHAR(20)`, UNIQUE, required), `license_number` (`VARCHAR(30)`, UNIQUE, required), `full_name` (`VARCHAR(100)`, required), `specialty` (`VARCHAR(50)`, required).
* **Bed**: `bed_id` (`SERIAL`, PK), `bed_number` (`VARCHAR(10)`, UNIQUE, required), `ward_name` (`VARCHAR(50)`, required), `daily_rate` (`NUMERIC(10,2)`, required).
* **Admission**: `admission_id` (`SERIAL`, PK), `patient_id` (`INT`, FK to `Patient`, required), `bed_id` (`INT`, FK to `Bed`, required), `admit_date` (`DATE`, required), `discharge_date` (`DATE`, optional; NULL while active).
* **Consultation**: `consultation_id` (`SERIAL`, PK), `patient_id` (`INT`, FK to `Patient`, required), `doctor_id` (`INT`, FK to `Doctor`, required), `visit_date` (`DATE`, required), `time_slot` (`TIME`, required), `fee` (`NUMERIC(10,2)`, required).
* **Medication**: `medication_id` (`SERIAL`, PK), `drug_name` (`VARCHAR(100)`, UNIQUE, required), `unit_price` (`NUMERIC(10,2)`, required), `stock_qty` (`INT`, required).
* **Prescription**: `prescription_id` (`SERIAL`, PK), `consultation_id` (`INT`, FK to `Consultation`, UNIQUE, required), `issued_date` (`DATE`, required), `dispensed_date` (`DATE`, optional; NULL until dispensed).
* **Prescription_Item**: `prescription_id` (`INT`, PK, FK to `Prescription`), `medication_id` (`INT`, PK, FK to `Medication`), `quantity` (`INT`, required), `dosage` (`VARCHAR(50)`, required).
* **Invoice**: `invoice_id` (`SERIAL`, PK), `patient_id` (`INT`, FK to `Patient`, required), `issued_date` (`DATE`, required), `total_amount` (`NUMERIC(10,2)`, required), `status` (`VARCHAR(10)`, required), `paid_date` (`DATE`, optional), `paid_amount` (`NUMERIC(10,2)`, optional).

## 3. Relationships
* **Patient – Consultation (1:M)**: One patient books zero or many consultations; each consultation belongs to one patient.
* **Doctor – Consultation (1:M)**: One doctor conducts zero or many consultations; each consultation belongs to one doctor.
* **Patient – Admission (1:M)**: One patient has zero or many admissions over time; each admission belongs to one patient.
* **Bed – Admission (1:M)**: One bed hosts zero or many admissions over time; each admission uses one bed.
* **Consultation – Prescription (1:1)**: One consultation produces zero or one prescription; each prescription links to one consultation.
* **Prescription – Medication (M:N via Prescription_Item)**: One prescription lists one or more medications, and one medication appears on zero or many prescriptions.
* **Patient – Invoice (1:M)**: One patient receives zero or many invoices; each invoice belongs to one patient.

## 4. Business rules and constraints
* **Rule 1**: Primary keys (`patient_id`, `doctor_id`) and `UNIQUE` constraints on `staff_number` and `license_number` prevent duplicate identities.
* **Rule 2**: Intentionally blank in the prompt; no constraint required.
* **Rule 3**: `UNIQUE` on `bed_number` identifies each bed. A partial unique index (`WHERE discharge_date IS NULL`) on `Admission(bed_id)` prevents two active stays in one bed, which a standard key cannot enforce.
* **Rule 4**: A partial unique index (`WHERE discharge_date IS NULL`) on `Admission(patient_id)` prevents concurrent admissions. A `CHECK (discharge_date IS NULL OR discharge_date >= admit_date)` validates dates.
* **Rule 5**: Composite `UNIQUE` constraints on `Consultation(doctor_id, visit_date, time_slot)` and `Consultation(patient_id, visit_date, time_slot)` stop double-booking.
* **Rule 6**: Foreign keys and a composite primary key on `Prescription_Item` link consultations to medications with `CHECK (quantity > 0)`.
* **Rule 7**: `dispensed_date` stays `NULL` until dispensing. A transaction checks `Prescription_Item.quantity <= Medication.stock_qty` before subtracting stock, because keys cannot compare values across tables.
* **Rule 8**: Foreign key `Invoice.patient_id` links each bill to a patient. For example, a $50 consultation plus two $10 tablets stores `70.00` in `total_amount` so historical bills stay fixed if catalog prices later change.
* **Rule 9**: `DEFAULT 'Unpaid'` and `CHECK (status IN ('Unpaid', 'Paid'))` manage status, paired with a check requiring `paid_date` and `paid_amount = total_amount` when `status = 'Paid'`.

## 5. Design assumptions
* **Merged Payment into Invoice**: I chose to store `paid_date` and `paid_amount` inside `Invoice` rather than a separate `Payment` table because Rule 9 requires full settlement in one step, reducing the design from ten entities to nine.
* **Stored `total_amount`**: Storing the calculated total on `Invoice` preserves historical pricing even when medication or bed rates change later.
* **One prescription per consultation**: Making `consultation_id` unique in `Prescription` simplifies pharmacy dispensing per visit.