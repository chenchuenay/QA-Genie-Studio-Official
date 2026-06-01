class ExpectedResultBuilder {
  String build({
    required String businessArea,
    required String category,
    required String platform,
  }) {
    if (businessArea == 'authentication') {
      if (category == 'positive') {
        return 'Dashboard loads with user profile and session token is issued.';
      }
      if (category == 'negative') {
        return 'Error message displayed, login blocked, account remains locked.';
      }
      if (category == 'validation') {
        return 'Email field shows "required" error, no API call is made.';
      }
      if (category == 'security') {
        return 'Malicious input is sanitised, no SQL execution occurs.';
      }
      if (category == 'session') {
        return 'User is redirected to login page after session expiry.';
      }
    }
    if (businessArea == 'ecommerce') {
      if (category == 'positive') {
        return 'Order confirmation email sent, inventory updated.';
      }
      if (category == 'negative') {
        return 'Coupon rejected with clear error, original price unchanged.';
      }
      if (category == 'security') {
        return 'Price tampering is detected and transaction is blocked.';
      }
    }
    if (businessArea == 'banking') {
      if (category == 'positive') {
        return 'Transfer successful, balance updated, transaction reference generated.';
      }
      if (category == 'negative') {
        return 'OTP mismatch, transfer cancelled, no funds deducted.';
      }
    }
    // Generic fallback
    if (platform == 'API') {
      if (category == 'negative') return 'API returns a 4xx client error with a clear error message.';
      if (category == 'security') return 'API rejects the malicious payload and returns 403 Forbidden.';
      return 'API returns a successful 2xx response with the expected resource representation.';
    }
    if (category == 'negative' || category == 'validation') {
      return 'The application prevents the invalid action, shows an error message near the affected field, and maintains other user input.';
    }
    if (category == 'security') {
      return 'The input is sanitised, no script executes, and a security notification is shown if applicable.';
    }
    if (category == 'session') {
      return 'If session expired, user is redirected to login; otherwise session persists correctly across actions.';
    }
    return 'The workflow completes successfully, the user sees a confirmation, and the system updates appropriately.';
  }
}