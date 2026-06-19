import 'identity_reference.dart';

class CrossDomainReference {
  static final cases = [
    ReferenceCase(
      title:
          'End-to-end: User authenticates, browses products, and completes checkout',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'User has a registered account with verified email and valid payment method',
        'Product catalog contains in-stock items with active pricing',
        'Inventory service is reachable and responses within normal latency',
        'Payment gateway is operational and test mode is enabled',
      ],
      testData:
          'email=jane.doe@example.com, password=Secure@Pass789, product=Wireless Headphones SKU-7755, qty=2, card=VISA-4242, shipping=123 Main St, platform=Mobile',
      steps: [
        'Launch the app and tap "Sign In" — enter email and password to authenticate',
        'Verify user is redirected to the product catalog/dashboard',
        'Search for "Wireless Headphones" using the search bar',
        'Select the first result (SKU-7755, \$49.99) and open product details',
        'Tap "Add to Cart" and verify cart badge updates to 1',
        'Proceed to Checkout via the cart screen',
        'Select saved shipping address: 123 Main St, Springfield, IL',
        'Enter payment card: VISA-4242, Exp 12/28, CVV 345',
        'Tap "Place Order" to complete the purchase',
        'Verify order confirmation screen with order ID and email receipt',
      ],
      expectedResult:
          'The end-to-end flow completes seamlessly. The user authenticates (HTTP 200, session token issued), adds an item to cart (HTTP 200, cart updated), and completes checkout (HTTP 200, order created). The order confirmation displays a unique order ID. A confirmation email is sent. The user is logged out gracefully from all sessions.',
    ),
    ReferenceCase(
      title:
          'Session expiry during checkout forces re-authentication without data loss',
      type: 'SESSION',
      priority: 'High',
      preconditions: [
        'User is authenticated and has added items to the cart',
        'Session is configured to expire after 15 minutes of inactivity',
        'Checkout process has been idle for more than 15 minutes',
        'Cart persistence is enabled (items saved to server-side cart)',
      ],
      testData:
          'session=expired, cartItems=2, email=user@example.com, password=ValidPass123, platform=Web',
      steps: [
        'Log in and add 2 items to the cart (Wireless Headphones, USB-C Cable)',
        'Navigate to the checkout page and begin entering shipping details',
        'Wait 15+ minutes without any interaction with the page',
        'Attempt to click "Continue to Payment" after the idle period',
        'Observe the system response — should redirect to login page',
        'Enter credentials: user@example.com / ValidPass123 to re-authenticate',
        'After login, verify the checkout page still contains the 2 items in the cart',
      ],
      expectedResult:
          'When the user attempts to proceed after session expiry, the system redirects to the login page. After re-authentication, the user is returned to the checkout page. All previously entered shipping details and cart items are preserved. No data loss occurs. A message displays: "Your session expired. Please log in again. Your items have been saved."',
    ),
    ReferenceCase(
      title:
          'Multi-step wizard: User books a telehealth appointment with insurance verification',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'User is authenticated with an active account',
        'Telehealth feature is enabled for the user\'s region',
        'Provider (Dr. Smith) has available telehealth slots',
        'Insurance information (Ins-Policy-123) is on file and valid',
        'Camera and microphone permissions are granted on the device',
      ],
      testData:
          'provider=Dr. Emily Smith, date=2026-07-20, time=2:00 PM, type=Telehealth, insurance=Ins-Policy-123, platform=Mobile',
      steps: [
        'Navigate to the Appointments section and tap "Book Telehealth Visit"',
        'Select provider: Dr. Emily Smith (shows available telehealth slots)',
        'Select date: July 20, 2026 and time: 2:00 PM',
        'Complete insurance verification: system checks Ins-Policy-123 eligibility',
        'Approve insurance estimate: copay \$25.00, covered at 100% after copay',
        'Review and accept the telehealth consent form',
        'Tap "Confirm Booking" to schedule the appointment',
        'Verify the appointment card shows a "Join Call" button for the scheduled time',
      ],
      expectedResult:
          'The telehealth appointment is booked successfully through the multi-step wizard. Insurance verification confirms coverage (Ins-Policy-123, copay \$25.00). The appointment appears in Upcoming Appointments with a "Join Telehealth Call" button that activates 5 minutes before the scheduled time. A confirmation includes the meeting link and pre-visit instructions.',
    ),
  ];
}
