BEGIN;

-- 1. Insert patients (3 fictional patients)
INSERT INTO public.patient (full_name, phone, date_of_birth) VALUES
    ('Adaeze Nwosu', '+234-800-111-0001', '1990-04-15'),
    ('Tunde Adeyemi', '+234-800-111-0002', '1984-09-22'),
    ('Zainab Ibrahim', '+234-800-111-0003', '1998-01-30');

-- 2. Insert doctors with unique staff_number and license_number (Rule 1)
INSERT INTO public.doctor (staff_number, license_number, full_name, specialty) VALUES
    ('DOC-101', 'MDCN-88401', 'Dr. Chinedu Okeke', 'General Medicine'),
    ('DOC-102', 'MDCN-88402', 'Dr. Amina Bello', 'Cardiology');

-- 3. Insert ward beds (Rule 2)
INSERT INTO public.bed (bed_number, ward_name, daily_rate) VALUES
    ('GEN-01', 'General Ward', 15000.00),
    ('GEN-02', 'General Ward', 15000.00),
    ('CAR-01', 'Cardiac Ward', 30000.00);

-- 4. Insert pharmacy medications
INSERT INTO public.medication (drug_name, unit_price, stock_qty) VALUES
    ('Amoxicillin 500mg', 1200.00, 100),
    ('Paracetamol 500mg', 500.00, 200),
    ('Lisinopril 10mg', 2500.00, 50);

-- 5. Insert admissions: one discharged (historical) and one active (NULL discharge_date)
INSERT INTO public.admission (patient_id, bed_id, admit_date, discharge_date) VALUES
    (
        (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0001'),
        (SELECT bed_id FROM public.bed WHERE bed_number = 'GEN-01'),
        '2026-10-01',
        '2026-10-04'
    ),
    (
        (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0002'),
        (SELECT bed_id FROM public.bed WHERE bed_number = 'GEN-01'),
        '2026-10-10',
        NULL
    );

-- 6. Insert consultations (Rule 4)
INSERT INTO public.consultation (patient_id, doctor_id, visit_date, time_slot, fee) VALUES
    (
        (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0001'),
        (SELECT doctor_id FROM public.doctor WHERE staff_number = 'DOC-101'),
        '2026-10-12',
        '09:00:00',
        10000.00
    ),
    (
        (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0003'),
        (SELECT doctor_id FROM public.doctor WHERE staff_number = 'DOC-102'),
        '2026-10-12',
        '10:00:00',
        15000.00
    );

-- 7. Insert prescriptions: one dispensed and one pending (NULL dispensed_date) (Rules 5 & 6)
INSERT INTO public.prescription (consultation_id, issued_date, dispensed_date) VALUES
    (
        (SELECT c.consultation_id
         FROM public.consultation c
         JOIN public.doctor d ON c.doctor_id = d.doctor_id
         WHERE d.staff_number = 'DOC-101' AND c.visit_date = '2026-10-12' AND c.time_slot = '09:00:00'),
        '2026-10-12',
        '2026-10-12'
    ),
    (
        (SELECT c.consultation_id
         FROM public.consultation c
         JOIN public.doctor d ON c.doctor_id = d.doctor_id
         WHERE d.staff_number = 'DOC-102' AND c.visit_date = '2026-10-12' AND c.time_slot = '10:00:00'),
        '2026-10-12',
        NULL
    );

-- 8. Insert prescription items linking medications to prescriptions (Rule 5)
INSERT INTO public.prescription_item (prescription_id, medication_id, quantity, dosage) VALUES
    (
        (SELECT p.prescription_id
         FROM public.prescription p
         JOIN public.consultation c ON p.consultation_id = c.consultation_id
         JOIN public.doctor d ON c.doctor_id = d.doctor_id
         WHERE d.staff_number = 'DOC-101' AND c.visit_date = '2026-10-12' AND c.time_slot = '09:00:00'),
        (SELECT medication_id FROM public.medication WHERE drug_name = 'Amoxicillin 500mg'),
        2,
        '1 capsule 3 times daily'
    ),
    (
        (SELECT p.prescription_id
         FROM public.prescription p
         JOIN public.consultation c ON p.consultation_id = c.consultation_id
         JOIN public.doctor d ON c.doctor_id = d.doctor_id
         WHERE d.staff_number = 'DOC-101' AND c.visit_date = '2026-10-12' AND c.time_slot = '09:00:00'),
        (SELECT medication_id FROM public.medication WHERE drug_name = 'Paracetamol 500mg'),
        1,
        '2 tablets every 8 hours'
    ),
    (
        (SELECT p.prescription_id
         FROM public.prescription p
         JOIN public.consultation c ON p.consultation_id = c.consultation_id
         JOIN public.doctor d ON c.doctor_id = d.doctor_id
         WHERE d.staff_number = 'DOC-102' AND c.visit_date = '2026-10-12' AND c.time_slot = '10:00:00'),
        (SELECT medication_id FROM public.medication WHERE drug_name = 'Lisinopril 10mg'),
        1,
        '1 tablet daily'
    );

-- 9. Insert invoices: one Paid (settled) and one Unpaid (Rules 7 & 8)
INSERT INTO public.invoice (patient_id, issued_date, total_amount, status, paid_date, paid_amount) VALUES
    (
        (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0001'),
        '2026-10-12',
        57900.00,
        'Paid',
        '2026-10-12',
        57900.00
    ),
    (
        (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0003'),
        '2026-10-12',
        17500.00,
        'Unpaid',
        NULL,
        NULL
    );

COMMIT;