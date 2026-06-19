import 'identity_reference.dart';

class SchedulingReference {
  static final cases = [
    ReferenceCase(
      title: 'Patient books an available appointment slot with a specific provider',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'Patient is authenticated with an active account',
        'Provider (Dr. Smith) has available slots on the selected date',
        'Patient\'s insurance information is valid and on file',
        'Appointment scheduling feature is within business hours',
      ],
      testData:
          'provider=Dr. Emily Smith, date=2026-07-15, time=10:00 AM, reason=Annual checkup, insurance=Ins-Policy-123, platform=Mobile',
      steps: [
        'Open the Appointments section from the patient dashboard',
        'Tap "Book New Appointment" button',
        'Select provider: Dr. Emily Smith from the provider list',
        'Select date: July 15, 2026 from the date picker (calendar view)',
        'Select time slot: 10:00 AM (visible as available — green indicator)',
        'Enter reason for visit: Annual checkup',
        'Verify insurance information: Ins-Policy-123 is active and covers the visit',
        'Tap "Confirm Booking" to finalize the appointment',
        'Verify the appointment appears in the "Upcoming Appointments" list',
      ],
      expectedResult:
          'The appointment is booked successfully. A confirmation screen displays with appointment details: provider name, date, time, and location/telehealth link. The appointment appears in the Upcoming Appointments list with status "Confirmed." A confirmation notification/email is sent to the patient.',
    ),
    ReferenceCase(
      title: 'Rescheduling an appointment to a provider-unavailable time shows conflict error',
      type: 'NEGATIVE',
      priority: 'Medium',
      preconditions: [
        'Patient has a confirmed appointment (APPT-2026-0715-001)',
        'The target time slot (3:00 PM) is marked as unavailable for Dr. Smith',
        'Patient is within the allowed rescheduling window (no less than 24h before)',
      ],
      testData:
          'appointmentId=APPT-2026-0715-001, newDate=2026-07-16, newTime=3:00 PM, platform=Web',
      steps: [
        'Navigate to "My Appointments" section from the patient portal',
        'Find appointment APPT-2026-0715-001 and click "Reschedule"',
        'Select new date: July 16, 2026 from the calendar',
        'Select time: 3:00 PM from the available time slots',
        'Click "Confirm Reschedule" button',
        'Observe the system response for the selected time slot',
      ],
      expectedResult:
          'The reschedule request is rejected with an error message: "The selected time slot (3:00 PM) is not available. Please choose a different time or date." The original appointment remains unchanged with its original date and time. The user can select a different slot.',
    ),
    ReferenceCase(
      title: 'Cancelling an appointment within policy sends cancellation confirmation',
      type: 'POSITIVE',
      priority: 'Medium',
      preconditions: [
        'Patient has a confirmed upcoming appointment (APPT-2026-0715-001)',
        'Cancellation is requested more than 24 hours before the appointment',
        'No cancellation fee applies (within free cancellation window)',
      ],
      testData:
          'appointmentId=APPT-2026-0715-001, reason=Schedule conflict, platform=Mobile',
      steps: [
        'Open the Appointments screen and tap on the upcoming appointment card',
        'Tap "Cancel Appointment" button at the bottom of the detail screen',
        'Select cancellation reason: "Schedule conflict" from the reason picker',
        'Read the cancellation policy summary and verify no fee applies',
        'Tap "Confirm Cancellation" button',
        'Verify the appointment status changes to "Cancelled" with a strikethrough',
      ],
      expectedResult:
          'The appointment is cancelled successfully. A confirmation toast displays: "Your appointment on July 15, 2026 at 10:00 AM has been cancelled." The appointment status changes to "Cancelled" in the list. The slot is released back to the provider\'s availability. A cancellation email is sent to the patient.',
    ),
  ];
}
