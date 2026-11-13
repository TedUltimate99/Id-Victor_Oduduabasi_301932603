# Hospital Management System Normalisation

Normalisation is the process of organising data into clean, linked tables so that facts are stored once and changes do not cause errors. Using two fictional hospital visits, the steps below move an unnormalised record through First, Second, and Third Normal Form to match the agreed design.

*(Note: For readability, sample tables focus on key consultation, pharmacy, and ward fields. Other agreed attributes—`phone`, `date_of_birth`, `staff_number`, `license_number`, `specialty`, `fee`, `stock_qty`, `dispensed_date`, and `Invoice` fields—are omitted from the sample rows below and appear in the final structure summary.)*

---

## Starting Point: Unnormalised Form (0NF)

In an unnormalised sheet, each row combines patient details, doctor details, ward stays, and a comma-separated list of prescribed drugs.

**Unnormalised_Records**

| patient_id | patient_name | doctor_id | doctor_name | bed_no | ward_name | daily_rate | visit_date | time_slot | medications_list |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| P01 | Ada Obi | D01 | Dr. Bello | B12 | General | 150.00 | 2026-10-12 | 09:00 | Amoxicillin (20, 500mg), Paracetamol (30, 500mg) |
| P02 | Tunde Eze | D01 | Dr. Bello | B12 | General | 150.00 | 2026-10-12 | 10:00 | Ibuprofen (15, 400mg) |

**Problems in 0NF:**
* **Repeating groups:** `medications_list` packs multiple drugs, quantities, and dosages into a single cell, making it hard to search or calculate stock.
* **Update anomalies:** If `Dr. Bello` changes name or `B12` changes its `daily_rate`, every matching row must be edited.

---

## First Normal Form (1NF)

**Definition:** A table is in **1NF** when every cell holds a single atomic (indivisible) value, repeating groups are removed, and every row has a unique primary key.

**What moved and why:** The repeating drug list is split into separate rows so each cell holds one value. Because `visit_date` and `time_slot` alone cannot uniquely identify a row once multiple drugs appear per visit, the example assumes a combined key of `(patient_id, visit_date, time_slot, drug_name)`.

**Hospital_1NF** *(Combined PK: `patient_id, visit_date, time_slot, drug_name`)*

| patient_id | patient_name | doctor_id | doctor_name | bed_no | ward_name | daily_rate | visit_date | time_slot | drug_name | unit_price | quantity | dosage |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| P01 | Ada Obi | D01 | Dr. Bello | B12 | General | 150.00 | 2026-10-12 | 09:00 | Amoxicillin | 12.00 | 20 | 500mg |
| P01 | Ada Obi | D01 | Dr. Bello | B12 | General | 150.00 | 2026-10-12 | 09:00 | Paracetamol | 5.00 | 30 | 500mg |
| P02 | Tunde Eze | D01 | Dr. Bello | B12 | General | 150.00 | 2026-10-12 | 10:00 | Ibuprofen | 8.00 | 15 | 400mg |

**Removed problem:** Repeating lists are gone; each medication line is now an individual row. However, patient, doctor, and bed details repeat for every drug on Ada Obi's visit.

---

## Second Normal Form (2NF)

**Definition:** A table is in **2NF** when it is in 1NF and every non-key field depends on the **entire** primary key, rather than only part of a combined key (a **partial dependency**).

**What moved and why:**
* `patient_name` depends only on `patient_id` (part of the key). It moves to **Patient**.
* `unit_price` depends only on `drug_name` (part of the key). It moves to **Medication**.
* `doctor_id`, `doctor_name`, `bed_no`, `ward_name`, and `daily_rate` depend only on `(patient_id, visit_date, time_slot)`—the visit itself, not `drug_name`. They move to **Visit_Details**.
* Only `quantity` and `dosage` depend on the full combined key `(patient_id, visit_date, time_slot, drug_name)`. They stay in **Prescription_Line**.

**Patient** *(PK: `patient_id`)*

| patient_id | patient_name |
| :--- | :--- |
| P01 | Ada Obi |
| P02 | Tunde Eze |

**Medication** *(PK: `drug_name`)*

| drug_name | unit_price |
| :--- | :--- |
| Amoxicillin | 12.00 |
| Paracetamol | 5.00 |
| Ibuprofen | 8.00 |

**Visit_Details** *(Combined PK: `patient_id, visit_date, time_slot`; FK: `patient_id`)*

| patient_id | visit_date | time_slot | doctor_id | doctor_name | bed_no | ward_name | daily_rate |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| P01 | 2026-10-12 | 09:00 | D01 | Dr. Bello | B12 | General | 150.00 |
| P02 | 2026-10-12 | 10:00 | D01 | Dr. Bello | B12 | General | 150.00 |

**Prescription_Line** *(Combined PK: `patient_id, visit_date, time_slot, drug_name`; FKs to `Visit_Details` and `Medication`)*

| patient_id | visit_date | time_slot | drug_name | quantity | dosage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P01 | 2026-10-12 | 09:00 | Amoxicillin | 20 | 500mg |
| P01 | 2026-10-12 | 09:00 | Paracetamol | 30 | 500mg |
| P02 | 2026-10-12 | 10:00 | Ibuprofen | 15 | 400mg |

*(Note: `Patient` and `Medication` have single-column keys, so partial dependencies cannot exist in them—they are automatically in 2NF.)*

**Removed problem:** Updating a patient's name or a drug's price now happens in one single row instead of every prescription line.

---

## Third Normal Form (3NF)

**Definition:** A table is in **3NF** when it is in 2NF and no non-key field depends on another non-key field (a **transitive dependency**). Every non-key attribute depends only on the primary key.

**What moved and why:** Inside **Visit_Details**, two transitive dependencies remain:
1. `doctor_name` depends on `doctor_id` (a non-key field), not on the visit key. `Doctor` becomes its own table linked via `doctor_id`.
2. `ward_name` and `daily_rate` depend on `bed_no` (a non-key field), not on the visit key. `Bed` becomes its own table, and inpatient stays separate into `Admission` (since a bed stay spans `admit_date` to `discharge_date` independently of an outpatient `Consultation`).

**Doctor** *(PK: `doctor_id`)*

| doctor_id | doctor_name |
| :--- | :--- |
| D01 | Dr. Bello |

**Bed** *(PK: `bed_no`)*

| bed_no | ward_name | daily_rate |
| :--- | :--- | :--- |
| B12 | General | 150.00 |

**Consultation** *(PK: `consultation_id`; FKs: `patient_id`, `doctor_id`)*

| consultation_id | patient_id | doctor_id | visit_date | time_slot |
| :--- | :--- | :--- | :--- | :--- |
| C01 | P01 | D01 | 2026-10-12 | 09:00 |
| C02 | P02 | D01 | 2026-10-12 | 10:00 |

**Admission** *(PK: `admission_id`; FKs: `patient_id`, `bed_no`)*

| admission_id | patient_id | bed_no | admit_date | discharge_date |
| :--- | :--- | :--- | :--- | :--- |
| A01 | P01 | B12 | 2026-10-12 | NULL |
| A02 | P02 | B12 | 2026-10-14 | 2026-10-16 |

**Prescription** *(PK: `prescription_id`; FK & UK: `consultation_id`)*

| prescription_id | consultation_id | issued_date |
| :--- | :--- | :--- |
| RX01 | C01 | 2026-10-12 |
| RX02 | C02 | 2026-10-12 |

**Prescription_Item** *(Combined PK: `prescription_id, medication_id`; FKs: `prescription_id`, `medication_id`)*

| prescription_id | medication_id | quantity | dosage |
| :--- | :--- | :--- | :--- |
| RX01 | M01 | 20 | 500mg |
| RX01 | M02 | 30 | 500mg |
| RX02 | M03 | 15 | 400mg |

**How IDs link the tables:** Foreign keys (`patient_id`, `doctor_id`, `bed_id`, `consultation_id`, `prescription_id`, `medication_id`) connect child rows back to parent rows without repeating descriptive names or rates.

**Removed problem:** Deleting a consultation no longer deletes doctor or bed records (deletion anomaly), and a new bed or doctor can be added before any patient visits (insertion anomaly). Note that `ward_name` remains in `Bed` without further attributes (`ward_phone`, etc.), keeping `Bed` in 3NF.

---

## Surrogate IDs vs. Combined Keys in the Final Design

In the final agreed schema, automatically generated `SERIAL` primary keys (`patient_id`, `doctor_id`, `bed_id`, `admission_id`, `consultation_id`, `medication_id`, `prescription_id`, `invoice_id`) replace natural or combined keys such as `(patient_id, visit_date, time_slot)` and `drug_name`.

* **Why surrogate IDs are used:** Natural values like `drug_name` or `bed_number` can be renamed or mistyped; integer IDs keep foreign key joins compact and stable while `UNIQUE` constraints still protect the natural keys (`staff_number`, `license_number`, `bed_number`, `drug_name`, and `(doctor_id, visit_date, time_slot)`).
* **Why an ID alone does not prove 3NF:** Simply adding `consultation_id` to the original 1NF table would still leave `doctor_name` depending on `doctor_id` and `unit_price` depending on `drug_name`. A table reaches 3NF only when every non-key column depends strictly on the primary key and nothing else.
* **Complete 9-table alignment:** Alongside the tables shown above, `Invoice` (`invoice_id`, `patient_id`, `issued_date`, `total_amount`, `status`, `paid_date`, `paid_amount`) stores patient billing in 3NF because every non-key billing field depends solely on `invoice_id`.