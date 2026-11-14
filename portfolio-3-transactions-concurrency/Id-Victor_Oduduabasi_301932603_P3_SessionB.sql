BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SHOW transaction_isolation;

-- Under READ COMMITTED, Session B cannot see Session A's uncommitted insert
SELECT
    b.bed_number,
    a.admission_id AS active_admission_id
FROM public.bed b
LEFT JOIN public.admission a
    ON b.bed_id = a.bed_id
   AND a.discharge_date IS NULL
WHERE b.bed_number = 'GEN-02';

-- Session B attempts to admit Zainab Ibrahim into GEN-02 and blocks/waits
INSERT INTO public.admission (patient_id, bed_id, admit_date, discharge_date)
VALUES (
    (SELECT patient_id FROM public.patient WHERE phone = '+234-800-111-0003'),
    (SELECT bed_id FROM public.bed WHERE bed_number = 'GEN-02'),
    DATE '2026-10-16',
    NULL
);

ROLLBACK;

SELECT
    a.admission_id,
    p.full_name,
    b.bed_number,
    a.admit_date,
    a.discharge_date
FROM public.admission a
JOIN public.patient p
    ON a.patient_id = p.patient_id
JOIN public.bed b
    ON a.bed_id = b.bed_id
WHERE b.bed_number = 'GEN-02'
  AND a.discharge_date IS NULL;

  