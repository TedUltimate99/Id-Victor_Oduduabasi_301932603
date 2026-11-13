# Hospital Management System ER Diagram

```mermaid
erDiagram
    direction LR

    Patient {
        SERIAL patient_id PK
        VARCHAR_100 full_name
        VARCHAR_20 phone
        DATE date_of_birth
    }

    Doctor {
        SERIAL doctor_id PK
        VARCHAR_20 staff_number UK
        VARCHAR_30 license_number UK
        VARCHAR_100 full_name
        VARCHAR_50 specialty
    }

    Bed {
        SERIAL bed_id PK
        VARCHAR_10 bed_number UK
        VARCHAR_50 ward_name
        NUMERIC_10_2 daily_rate
    }

    Admission {
        SERIAL admission_id PK
        INT patient_id FK
        INT bed_id FK
        DATE admit_date
        DATE discharge_date
    }

    Consultation {
        SERIAL consultation_id PK
        INT patient_id FK
        INT doctor_id FK
        DATE visit_date
        TIME time_slot
        NUMERIC_10_2 fee
    }

    Medication {
        SERIAL medication_id PK
        VARCHAR_100 drug_name UK
        NUMERIC_10_2 unit_price
        INT stock_qty
    }

    Prescription {
        SERIAL prescription_id PK
        INT consultation_id FK, UK
        DATE issued_date
        DATE dispensed_date
    }

    Prescription_Item {
        INT prescription_id PK, FK
        INT medication_id PK, FK
        INT quantity
        VARCHAR_50 dosage
    }

    Invoice {
        SERIAL invoice_id PK
        INT patient_id FK
        DATE issued_date
        NUMERIC_10_2 total_amount
        VARCHAR_10 status
        DATE paid_date
        NUMERIC_10_2 paid_amount
    }

    Patient ||--o{ Consultation : "books"
    Doctor ||--o{ Consultation : "conducts"
    Patient ||--o{ Admission : "has"
    Bed ||--o{ Admission : "hosts"
    Consultation ||--o| Prescription : "produces"
    Prescription ||--|{ Prescription_Item : "lists"
    Medication ||--o{ Prescription_Item : "appears on"
    Patient ||--o{ Invoice : "receives"
```

## Key and Relationship Notation
* **PK (Primary Key)**: Uniquely identifies each row in a table (such as `patient_id` in `Patient`). In `Prescription_Item`, `prescription_id` and `medication_id` form a composite primary key so the same medication is not listed twice on one prescription.
* **FK (Foreign Key)**: Links a record to a primary key in another table (such as `Admission.bed_id` referencing `Bed.bed_id`).
* **UK (Unique Key)**: Prevents duplicate values in non-primary columns (such as `Doctor.staff_number`, `Doctor.license_number`, `Bed.bed_number`, `Medication.drug_name`, and `Prescription.consultation_id`).
* **Relationship Symbols**:
  * `||` means **exactly one** record is required on that side of the relationship.
  * `o|` means **zero or one** optional record is allowed.
  * `o{` means **zero or many** records are allowed.
  * `|{` means **one or many** records are required.

## Case Study Example
One `Patient` (`||`) books zero or many `Consultation` records (`o{`), while each `Consultation` belongs to exactly one `Patient`. A single `Consultation` (`||`) produces zero or one `Prescription` (`o|`), which in turn lists one or many `Prescription_Item` rows (`|{`), each referencing one `Medication` (`||`) such as Amoxicillin.

## Optional Fields and Additional Logic
* **Optional Fields**: `Admission.discharge_date` remains `NULL` while an inpatient stay is active; `Prescription.dispensed_date` remains `NULL` until pharmacy dispensing occurs; and `Invoice.paid_date` and `Invoice.paid_amount` remain `NULL` while `status` is `Unpaid`.
* **Additional Constraints and Transaction Logic**: Keys alone cannot enforce every business rule. Partial unique indexes (`WHERE discharge_date IS NULL`) on `Admission(bed_id)` and `Admission(patient_id)` prevent overlapping active admissions (Rules 3 and 4). Composite unique constraints on `Consultation(doctor_id, visit_date, time_slot)` and `Consultation(patient_id, visit_date, time_slot)` prevent double-booking (Rule 5). `CHECK` constraints validate date order, positive quantities, and invoice status alignment (Rules 4, 6, and 9). Finally, a database transaction verifies `Prescription_Item.quantity <= Medication.stock_qty` before reducing stock and setting `dispensed_date` (Rule 7).