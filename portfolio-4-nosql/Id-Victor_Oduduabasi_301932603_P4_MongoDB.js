// 1. Select the database
use("hospital_management_portfolio");

// 2. Confirm the target collection is currently empty before inserting
print("--- Pre-insert document count ---");
printjson(db.hospital_events.countDocuments({}));

// 3. Insert four fictional hospital activity events (2 ward_admission, 2 consultation_visit)
print("--- Inserting 4 hospital_events documents ---");
printjson(
  db.hospital_events.insertMany([
    {
      _id: "EVT-2026-001",
      event_type: "ward_admission",
      occurred_at: ISODate("2026-10-01T08:30:00Z"),
      patient: {
        full_name: "Adaeze Nwosu",
        phone: "+234-800-111-0001",
        date_of_birth: "1990-04-15"
      },
      details: {
        bed: {
          bed_number: "GEN-01",
          ward_name: "General Ward",
          daily_rate_ngn: 15000.00
        },
        admission_status: "Discharged",
        admit_date: "2026-10-01",
        discharge_date: "2026-10-04"
      }
    },
    {
      _id: "EVT-2026-002",
      event_type: "ward_admission",
      occurred_at: ISODate("2026-10-10T14:15:00Z"),
      patient: {
        full_name: "Tunde Adeyemi",
        phone: "+234-800-111-0002",
        date_of_birth: "1984-09-22"
      },
      details: {
        bed: {
          bed_number: "GEN-01",
          ward_name: "General Ward",
          daily_rate_ngn: 15000.00
        },
        admission_status: "Active",
        admit_date: "2026-10-10",
        discharge_date: null
      }
    },
    {
      _id: "EVT-2026-003",
      event_type: "consultation_visit",
      occurred_at: ISODate("2026-10-12T09:00:00Z"),
      patient: {
        full_name: "Adaeze Nwosu",
        phone: "+234-800-111-0001",
        date_of_birth: "1990-04-15"
      },
      details: {
        doctor: {
          staff_number: "DOC-101",
          license_number: "MDCN-88401",
          full_name: "Dr. Chinedu Okeke",
          specialty: "General Medicine"
        },
        time_slot: "09:00:00",
        fee_ngn: 10000.00,
        prescription: {
          status: "Dispensed",
          issued_date: "2026-10-12",
          dispensed_date: "2026-10-12",
          items: [
            {
              drug_name: "Amoxicillin 500mg",
              quantity: 2,
              dosage: "1 capsule 3 times daily"
            },
            {
              drug_name: "Paracetamol 500mg",
              quantity: 1,
              dosage: "2 tablets every 8 hours"
            }
          ]
        }
      }
    },
    {
      _id: "EVT-2026-004",
      event_type: "consultation_visit",
      occurred_at: ISODate("2026-10-12T10:00:00Z"),
      patient: {
        full_name: "Zainab Ibrahim",
        phone: "+234-800-111-0003",
        date_of_birth: "1998-01-30"
      },
      details: {
        doctor: {
          staff_number: "DOC-102",
          license_number: "MDCN-88402",
          full_name: "Dr. Amina Bello",
          specialty: "Cardiology"
        },
        time_slot: "10:00:00",
        fee_ngn: 15000.00,
        prescription: {
          status: "Pending",
          issued_date: "2026-10-12",
          dispensed_date: null,
          items: [
            {
              drug_name: "Lisinopril 10mg",
              quantity: 1,
              dosage: "1 tablet daily"
            }
          ]
        }
      }
    }
  ])
);

// 4. Query 1: Total event document count
print("--- Query 1: Total event documents ---");
printjson(db.hospital_events.countDocuments({}));

// 5. Query 2: Ordered event history for patient Adaeze Nwosu (+234-800-111-0001)
print("--- Query 2: Ordered event history for Adaeze Nwosu ---");
printjson(
  db.hospital_events
    .find(
      { "patient.phone": "+234-800-111-0001" },
      { _id: 1, event_type: 1, occurred_at: 1, "patient.full_name": 1, details: 1 }
    )
    .sort({ occurred_at: 1 })
    .toArray()
);

// 6. Query 3: Nested-field filter for pending pharmacy prescriptions
print("--- Query 3: Consultations with Pending prescriptions ---");
printjson(
  db.hospital_events
    .find(
      { "details.prescription.status": "Pending" },
      {
        _id: 1,
        occurred_at: 1,
        "patient.full_name": 1,
        "details.doctor.full_name": 1,
        "details.prescription": 1
      }
    )
    .toArray()
);