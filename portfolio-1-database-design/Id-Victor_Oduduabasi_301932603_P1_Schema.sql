BEGIN;

-- 1. Patient: stores individuals receiving hospital care (Rule 1)
CREATE TABLE public.patient (
    patient_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    date_of_birth DATE NOT NULL
);

-- 2. Doctor: stores medical staff conducting consultations (Rule 1)
CREATE TABLE public.doctor (
    doctor_id SERIAL PRIMARY KEY,
    staff_number VARCHAR(20) NOT NULL UNIQUE,
    license_number VARCHAR(30) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(50) NOT NULL
);

-- 3. Bed: stores physical inpatient ward beds (Rule 3)
CREATE TABLE public.bed (
    bed_id SERIAL PRIMARY KEY,
    bed_number VARCHAR(10) NOT NULL UNIQUE,
    ward_name VARCHAR(50) NOT NULL,
    daily_rate NUMERIC(10, 2) NOT NULL CHECK (daily_rate >= 0)
);

-- 4. Medication: stores pharmacy drug inventory
CREATE TABLE public.medication (
    medication_id SERIAL PRIMARY KEY,
    drug_name VARCHAR(100) NOT NULL UNIQUE,
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    stock_qty INT NOT NULL CHECK (stock_qty >= 0)
);

-- 5. Admission: stores inpatient stays linking patients to beds (Rules 3 & 4)
CREATE TABLE public.admission (
    admission_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES public.patient(patient_id),
    bed_id INT NOT NULL REFERENCES public.bed(bed_id),
    admit_date DATE NOT NULL,
    discharge_date DATE,
    CONSTRAINT chk_admission_dates CHECK (discharge_date IS NULL OR discharge_date >= admit_date)
);

-- Partial unique indexes prevent overlapping active admissions per bed and per patient (Rules 3 & 4)
CREATE UNIQUE INDEX idx_active_bed_admission
    ON public.admission (bed_id)
    WHERE discharge_date IS NULL;

CREATE UNIQUE INDEX idx_active_patient_admission
    ON public.admission (patient_id)
    WHERE discharge_date IS NULL;

-- 6. Consultation: stores outpatient visits between patients and doctors (Rule 5)
CREATE TABLE public.consultation (
    consultation_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES public.patient(patient_id),
    doctor_id INT NOT NULL REFERENCES public.doctor(doctor_id),
    visit_date DATE NOT NULL,
    time_slot TIME NOT NULL,
    fee NUMERIC(10, 2) NOT NULL CHECK (fee >= 0),
    CONSTRAINT uq_doctor_slot UNIQUE (doctor_id, visit_date, time_slot),
    CONSTRAINT uq_patient_slot UNIQUE (patient_id, visit_date, time_slot)
);

-- 7. Prescription: stores medication orders linked 1:1 to a consultation (Rules 6 & 7)
CREATE TABLE public.prescription (
    prescription_id SERIAL PRIMARY KEY,
    consultation_id INT NOT NULL UNIQUE REFERENCES public.consultation(consultation_id),
    issued_date DATE NOT NULL,
    dispensed_date DATE
);

-- 8. Prescription_Item: resolves M:N between prescription and medication (Rule 6)
CREATE TABLE public.prescription_item (
    prescription_id INT NOT NULL REFERENCES public.prescription(prescription_id),
    medication_id INT NOT NULL REFERENCES public.medication(medication_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    dosage VARCHAR(50) NOT NULL,
    PRIMARY KEY (prescription_id, medication_id)
);

-- 9. Invoice: stores patient bills and single-step full settlement (Rules 8 & 9)
CREATE TABLE public.invoice (
    invoice_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES public.patient(patient_id),
    issued_date DATE NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    status VARCHAR(10) NOT NULL DEFAULT 'Unpaid' CHECK (status IN ('Unpaid', 'Paid')),
    paid_date DATE,
    paid_amount NUMERIC(10, 2),
    CONSTRAINT chk_invoice_settlement CHECK (
        (status = 'Unpaid' AND paid_date IS NULL AND paid_amount IS NULL)
        OR
        (status = 'Paid' AND paid_date IS NOT NULL AND paid_amount = total_amount)
    )
);

-- Note: Table definitions alone cannot enforce cross-table stock checks, one-time dispensing
-- state transitions (Rule 7), or requiring at least one item per prescription (Rule 6);
-- those rules must be enforced by application transactions or triggers.

COMMIT;