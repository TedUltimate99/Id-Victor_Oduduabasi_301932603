# Portfolio 1 Database Design and Modelling

## Case study

A hospital management system tracks patients, doctors, consultations, inpatient ward beds, pharmacy prescriptions, and patient billing. Staff manage registrations, bed admissions, medication dispensing, and invoices, while doctors conduct consultations and issue prescriptions. Staff also monitor available ward beds and unpaid invoices.

## Users

Patients attend consultations, occupy ward beds, receive medications, and pay invoices. Receptionists register patients, book consultations, assign ward beds, and process payments. Doctors conduct consultations, request admissions, and issue prescriptions. Pharmacists dispense prescribed medications and update drug inventory.

## Main operations

Register a patient; schedule a consultation; admit and discharge a patient to a ward bed; issue and dispense a prescription; generate an invoice and record payment; view available beds and unpaid invoices.

## Business rules

1. Each patient has a unique patient ID, and each doctor has a unique staff ID and medical license number.

2. Each bed has a unique bed number, assigned to a named ward, and can hold at most one active admission at a time.

3. A patient can have at most one active ward admission, and the discharge date cannot be earlier than the admission date.

4. Each consultation links one patient to one doctor for a specific date and time slot, preventing double-booking of either party.

5. Each prescription links one consultation to one or more listed medications, capturing quantity and dosage.

6. A prescription can be dispensed only once, and the dispensed quantity cannot exceed available medication stock.

7. Each invoice belongs to one patient and records a total amount covering consultation, ward stay, and medication charges.

8. Invoice status defaults to Unpaid upon creation and changes to Paid only when the full payment date and amount are recorded.

## Scope

One hospital facility using fictional records across patient registration, outpatient consultations, inpatient bed admissions, pharmacy dispensing, and billing. Separate ward tables, insurance claims, lab tests, surgical scheduling, and user authentication are outside this scope.