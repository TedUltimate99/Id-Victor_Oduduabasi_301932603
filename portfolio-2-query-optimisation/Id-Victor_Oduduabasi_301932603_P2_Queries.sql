-- List unpaid invoices with patient contact details, ordered by issue date and invoice ID
SELECT
    i.invoice_id,
    p.full_name AS patient_name,
    p.phone,
    i.issued_date,
    i.total_amount,
    i.status
FROM public.invoice i
JOIN public.patient p
    ON i.patient_id = p.patient_id
WHERE i.status = 'Unpaid'
ORDER BY i.issued_date ASC, i.invoice_id ASC;

-- Find ward beds that currently have no active admission (discharge_date IS NULL)
SELECT
    b.bed_id,
    b.bed_number,
    b.ward_name,
    b.daily_rate
FROM public.bed b
WHERE NOT EXISTS (
    SELECT 1
    FROM public.admission a
    WHERE a.bed_id = b.bed_id
      AND a.discharge_date IS NULL
)
ORDER BY b.ward_name ASC, b.bed_number ASC;

-- Count how many prescriptions include each medication, keeping unused drugs at zero
SELECT
    m.medication_id,
    m.drug_name,
    m.stock_qty,
    COUNT(pi.prescription_id) AS times_prescribed
FROM public.medication m
LEFT JOIN public.prescription_item pi
    ON m.medication_id = pi.medication_id
GROUP BY
    m.medication_id,
    m.drug_name,
    m.stock_qty
ORDER BY times_prescribed DESC, m.drug_name ASC;