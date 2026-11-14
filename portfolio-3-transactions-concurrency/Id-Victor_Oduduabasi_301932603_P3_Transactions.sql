-- Check prescriptions, linked items, and current medication stock
SELECT
    pr.prescription_id,
    pr.consultation_id,
    pr.issued_date,
    pr.dispensed_date,
    pi.medication_id,
    m.drug_name,
    pi.quantity,
    m.stock_qty
FROM public.prescription pr
JOIN public.prescription_item pi
    ON pr.prescription_id = pi.prescription_id
JOIN public.medication m
    ON pi.medication_id = m.medication_id
ORDER BY pr.prescription_id ASC, pi.medication_id ASC;

-- Check current invoices and settlement status
SELECT
    invoice_id,
    patient_id,
    issued_date,
    total_amount,
    status,
    paid_date,
    paid_amount
FROM public.invoice
ORDER BY invoice_id ASC;

SELECT
    pr.prescription_id,
    pr.dispensed_date,
    m.medication_id,
    m.drug_name,
    m.stock_qty
FROM public.prescription pr
JOIN public.prescription_item pi
    ON pr.prescription_id = pi.prescription_id
JOIN public.medication m
    ON pi.medication_id = m.medication_id
WHERE pr.prescription_id = 2;

SELECT
    invoice_id,
    patient_id,
    total_amount,
    status,
    paid_date,
    paid_amount
FROM public.invoice
WHERE invoice_id = 2;

BEGIN;

UPDATE public.prescription
SET dispensed_date = DATE '2026-10-15'
WHERE prescription_id = 2
  AND dispensed_date IS NULL;

UPDATE public.medication
SET stock_qty = stock_qty - 1
WHERE medication_id = 3
  AND stock_qty >= 1;

COMMIT;

-- Repeat check: running the dispense UPDATE again affects 0 rows because dispensed_date is no longer NULL
UPDATE public.prescription
SET dispensed_date = DATE '2026-10-16'
WHERE prescription_id = 2
  AND dispensed_date IS NULL;

  BEGIN;

-- Valid change inside the transaction: settle invoice 2 in full
UPDATE public.invoice
SET status = 'Paid',
    paid_date = DATE '2026-10-15',
    paid_amount = 17500.00
WHERE invoice_id = 2
  AND status = 'Unpaid';

-- Deliberate violation: underpaid amount (10000.00 != 17500.00) violates chk_invoice_settlement (Rule 8)
UPDATE public.invoice
SET paid_amount = 10000.00
WHERE invoice_id = 2;

ROLLBACK;

SELECT
    pr.prescription_id,
    pr.dispensed_date,
    m.medication_id,
    m.drug_name,
    m.stock_qty
FROM public.prescription pr
JOIN public.prescription_item pi
    ON pr.prescription_id = pi.prescription_id
JOIN public.medication m
    ON pi.medication_id = m.medication_id
WHERE pr.prescription_id = 2;

SELECT
    invoice_id,
    patient_id,
    total_amount,
    status,
    paid_date,
    paid_amount
FROM public.invoice
WHERE invoice_id = 2;

