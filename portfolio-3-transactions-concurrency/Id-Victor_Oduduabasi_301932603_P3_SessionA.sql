-- Check patients and their current ward admissions
SELECT
    p.patient_id,
    p.full_name,
    p.phone,
    a.admission_id,
    a.bed_id,
    b.bed_number,
    a.admit_date,
    a.discharge_date
FROM public.patient p
LEFT JOIN public.admission a
    ON p.patient_id = a.patient_id
LEFT JOIN public.bed b
    ON a.bed_id = b.bed_id
ORDER BY p.patient_id ASC, a.admission_id ASC;

-- Check all ward beds and current occupancy
SELECT
    b.bed_id,
    b.bed_number,
    b.ward_name,
    a.admission_id AS active_admission_id,
    a.patient_id AS occupant_patient_id
FROM public.bed b
LEFT JOIN public.admission a
    ON b.bed_id = a.bed_id
   AND a.discharge_date IS NULL
ORDER BY b.bed_id ASC;

SELECT
    b.bed_number,
    b.ward_name,
    a.admission_id AS active_admission_id
FROM public.bed b
LEFT JOIN public.admission a
    ON b.bed_id = a.bed_id
   AND a.discharge_date IS NULL
WHERE b.bed_number = 'GEN-02';

SELECT
    p.full_name,
    p.phone,
    a.admission_id AS active_admission_id
FROM public.patient p
LEFT JOIN public.admission a
    ON p.patient_id = a.patient_id
   AND a.discharge_date IS NULL
WHERE p.phone IN ('+234-800-111-0001', '+234-800-111-0003')
ORDER BY p.phone ASC;

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SHOW transaction_isolation;

INSERT INTO public.admission (patient_id, bed_id, admit_date, discharge_date)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0001'),
    (SELECT bed_id FROM public.bed WHERE bed_number = 'GEN-02'),
    DATE '2026-10-16',
    NULL
);

COMMIT;
