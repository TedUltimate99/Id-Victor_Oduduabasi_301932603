-- Run each test outside a transaction block so individual errors do not abort subsequent tests.

-- Test 1: Required NOT NULL field (patient.full_name)
-- Expected error: ERROR: null value in column "full_name" of relation "patient" violates not-null constraint
INSERT INTO public.patient (full_name, phone, date_of_birth)
VALUES (NULL, '+234-800-999-0001', '1992-06-10');

-- Test 2: Unique doctor staff_number (Rule 1)
-- Expected error: ERROR: duplicate key value violates unique constraint "doctor_staff_number_key"
INSERT INTO public.doctor (staff_number, license_number, full_name, specialty)
VALUES ('DOC-101', 'MDCN-99999', 'Dr. Kemi Balogun', 'Pediatrics');

-- Test 3: Unique bed_number (Rule 2)
-- Expected error: ERROR: duplicate key value violates unique constraint "bed_bed_number_key"
INSERT INTO public.bed (bed_number, ward_name, daily_rate)
VALUES ('GEN-01', 'General Ward', 15000.00);

-- Test 4: Negative CHECK constraint on medication.stock_qty
-- Expected error: ERROR: new row for relation "medication" violates check constraint "medication_stock_qty_check"
INSERT INTO public.medication (drug_name, unit_price, stock_qty)
VALUES ('Ibuprofen 400mg', 800.00, -5);

-- Test 5: Foreign key violation on admission.patient_id
-- Expected error: ERROR: insert or update on table "admission" violates foreign key constraint "admission_patient_id_fkey"
INSERT INTO public.admission (patient_id, bed_id, admit_date, discharge_date)
VALUES (
    999999,
    (SELECT bed_id FROM public.bed WHERE bed_number = 'GEN-02'),
    '2026-10-15',
    NULL
);

-- Test 6: Partial unique index preventing two active admissions in the same bed (Rule 2)
-- Expected error: ERROR: duplicate key value violates unique constraint "idx_active_bed_admission"
INSERT INTO public.admission (patient_id, bed_id, admit_date, discharge_date)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0003'),
    (SELECT bed_id FROM public.bed WHERE bed_number = 'GEN-01'),
    '2026-10-15',
    NULL
);

-- Test 7: Partial unique index preventing one patient from having two active admissions (Rule 3)
-- Expected error: ERROR: duplicate key value violates unique constraint "idx_active_patient_admission"
INSERT INTO public.admission (patient_id, bed_id, admit_date, discharge_date)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0002'),
    (SELECT bed_id FROM public.bed WHERE bed_number = 'GEN-02'),
    '2026-10-15',
    NULL
);

-- Test 8: CHECK constraint preventing discharge_date earlier than admit_date (Rule 3)
-- Expected error: ERROR: new row for relation "admission" violates check constraint "chk_admission_dates"
INSERT INTO public.admission (patient_id, bed_id, admit_date, discharge_date)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0003'),
    (SELECT bed_id FROM public.bed WHERE bed_number = 'CAR-01'),
    '2026-10-15',
    '2026-10-12'
);

-- Test 9: Composite UNIQUE constraint stopping doctor double-booking (Rule 4)
-- Expected error: ERROR: duplicate key value violates unique constraint "uq_doctor_slot"
INSERT INTO public.consultation (patient_id, doctor_id, visit_date, time_slot, fee)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0003'),
    (SELECT doctor_id FROM public.doctor WHERE staff_number = 'DOC-101'),
    '2026-10-12',
    '09:00:00',
    10000.00
);

-- Test 10: Composite UNIQUE constraint stopping patient double-booking (Rule 4)
-- Expected error: ERROR: duplicate key value violates unique constraint "uq_patient_slot"
INSERT INTO public.consultation (patient_id, doctor_id, visit_date, time_slot, fee)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0001'),
    (SELECT doctor_id FROM public.doctor WHERE staff_number = 'DOC-102'),
    '2026-10-12',
    '09:00:00',
    15000.00
);

-- Test 11: CHECK constraint requiring positive quantity on prescription_item (Rule 5)
-- Expected error: ERROR: new row for relation "prescription_item" violates check constraint "prescription_item_quantity_check"
INSERT INTO public.prescription_item (prescription_id, medication_id, quantity, dosage)
VALUES (
    (SELECT p.prescription_id
     FROM public.prescription p
     JOIN public.consultation c ON p.consultation_id = c.consultation_id
     JOIN public.doctor d ON c.doctor_id = d.doctor_id
     WHERE d.staff_number = 'DOC-102' AND c.visit_date = '2026-10-12' AND c.time_slot = '10:00:00'),
    (SELECT medication_id FROM public.medication WHERE drug_name = 'Paracetamol 500mg'),
    0,
    '1 tablet as needed'
);

-- Test 12: CHECK constraint validating allowed invoice status values (Rule 8)
-- Expected error: ERROR: new row for relation "invoice" violates check constraint "invoice_status_check"
INSERT INTO public.invoice (patient_id, issued_date, total_amount, status, paid_date, paid_amount)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0002'),
    '2026-10-15',
    20000.00,
    'Partial',
    NULL,
    NULL
);

-- Test 13: CHECK constraint enforcing Paid status requires paid_date and full paid_amount (Rule 8)
-- Expected error: ERROR: new row for relation "invoice" violates check constraint "chk_invoice_settlement"
INSERT INTO public.invoice (patient_id, issued_date, total_amount, status, paid_date, paid_amount)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0002'),
    '2026-10-15',
    20000.00,
    'Paid',
    '2026-10-15',
    10000.00
);

-- Verify row counts across all 9 tables after all invalid inserts fail.
-- Expected counts:
-- patient: 3, doctor: 2, bed: 3, medication: 3, admission: 2,
-- consultation: 2, prescription: 2, prescription_item: 3, invoice: 2
SELECT 'patient' AS table_name, COUNT(*) AS row_count FROM public.patient
UNION ALL
SELECT 'doctor', COUNT(*) FROM public.doctor
UNION ALL
SELECT 'bed', COUNT(*) FROM public.bed
UNION ALL
SELECT 'medication', COUNT(*) FROM public.medication
UNION ALL
SELECT 'admission', COUNT(*) FROM public.admission
UNION ALL
SELECT 'consultation', COUNT(*) FROM public.consultation
UNION ALL
SELECT 'prescription', COUNT(*) FROM public.prescription
UNION ALL
SELECT 'prescription_item', COUNT(*) FROM public.prescription_item
UNION ALL
SELECT 'invoice', COUNT(*) FROM public.invoice
ORDER BY table_name;