import 'identity_reference.dart';

class RecordsReference {
  static final cases = [
    ReferenceCase(
      title: 'Clinician can add a new patient record with all required fields',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'Clinician is authenticated with appropriate role (Doctor, Nurse, Admin)',
        'Clinician has "Create Record" permission enabled',
        'Patient demographic data is available for entry',
        'System is connected to the patient registry service',
      ],
      testData:
          'patientName=Jane Doe, DOB=1995-03-22, MRN=MRN-2026-8842, visitReason=Annual physical examination, platform=Web',
      steps: [
        'Navigate to the Records section from the main clinical dashboard',
        'Click "Add New Record" button (top-right corner)',
        'Fill in patient demographics: Full Name = Jane Doe, DOB = 1995-03-22',
        'Enter Medical Record Number (MRN): MRN-2026-8842',
        'Select visit type: Annual Physical Examination from the dropdown',
        'Enter visit notes in the clinical notes text area',
        'Attach any relevant documents (lab results, imaging reports)',
        'Click "Save Record" button to persist the record',
        'Verify the record is now listed in the patient records table',
      ],
      expectedResult:
          'A new patient record is created successfully. The record appears in the patient records table with a unique Record ID (e.g., REC-2026-0619-001). All entered fields are saved accurately. The clinician is redirected to the record detail view showing the complete entry. A confirmation toast displays: "Patient record created successfully."',
    ),
    ReferenceCase(
      title: 'Editing a patient record with invalid date format displays validation error',
      type: 'NEGATIVE',
      priority: 'Medium',
      preconditions: [
        'Clinician is viewing an existing patient record (REC-2026-0042)',
        'Record is in "Active" state and not locked by another user',
        'Clinician has "Edit Record" permission',
      ],
      testData:
          'recordId=REC-2026-0042, newDOB=invalid-date-format, platform=Web',
      steps: [
        'Open patient record REC-2026-0042 from the records list',
        'Click "Edit" button to enter edit mode',
        'Locate the Date of Birth field and clear the existing value',
        'Enter invalid date: "invalid-date-format" in the DOB field',
        'Click "Save Changes" button to attempt saving',
        'Observe the validation response on the DOB field',
      ],
      expectedResult:
          'The form does not submit. The Date of Birth field shows a red error border with the message: "Please enter a valid date in MM/DD/YYYY format." All other entered data is preserved. The record remains unchanged in the database.',
    ),
    ReferenceCase(
      title: 'Deleting a patient record requires confirmation and removes record from list',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'Clinician is viewing patient record REC-2026-0042',
        'Record is eligible for deletion (not part of active legal proceedings)',
        'Clinician has "Delete Record" permission',
        'No active dependencies reference this record (e.g., linked prescriptions)',
      ],
      testData:
          'recordId=REC-2026-0042, confirmation=DELETE, platform=Mobile',
      steps: [
        'Navigate to patient record REC-2026-0042 from the records list',
        'Tap the "More Options" menu (three dots icon) in the top-right corner',
        'Tap "Delete Record" from the dropdown menu',
        'Read the confirmation dialog warning about permanent deletion',
        'Type "DELETE" in the confirmation text field to confirm',
        'Tap "Confirm Delete" button',
        'Verify the record is removed from the patient records list',
      ],
      expectedResult:
          'The record is permanently deleted after confirmation. A success toast displays: "Patient record REC-2026-0042 has been deleted." The record no longer appears in search results or the patient records list. The deletion is logged in the audit trail.',
    ),
  ];
}
