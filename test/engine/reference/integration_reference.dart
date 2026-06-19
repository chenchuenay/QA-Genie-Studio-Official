import 'identity_reference.dart';

class IntegrationReference {
  static final cases = [
    ReferenceCase(
      title: 'OAuth2 login with a valid Google provider token authenticates user successfully',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'OAuth2 provider (Google) is configured with correct client ID and secret',
        'User has a valid Google account with a verified email',
        'Redirect URI is whitelisted in the Google Cloud Console',
        'Backend API gateway is reachable with CORS configured',
      ],
      testData:
          'provider=google, token=valid-oauth2-token, redirectUri=https://app.qa-genie.com/auth/callback, scope=email+profile, platform=Mobile',
      steps: [
        'Open the Login screen and tap "Sign in with Google" button',
        'Accept the OAuth consent screen showing requested permissions (email, profile)',
        'Wait for OAuth callback — app receives authorization code from Google',
        'Exchange authorization code for access token via POST /auth/oauth/callback',
        'Verify the API response contains a valid session JWT and user profile data',
        'Navigate to the dashboard — user should be authenticated with Google profile picture',
      ],
      expectedResult:
          'The OAuth2 authentication flow completes successfully. The API returns HTTP 200 with an access token and user profile (name, email, avatar). The user is redirected to the dashboard with their Google profile information displayed. A new session is created and linked to the Google account.',
    ),
    ReferenceCase(
      title: 'Webhook delivery with invalid payload signature is rejected with 401',
      type: 'NEGATIVE',
      priority: 'High',
      preconditions: [
        'Webhook endpoint is configured with HMAC-SHA256 signature verification',
        'The webhook secret key is set on both sender and receiver',
        'Request contains an invalid/mismatched X-Hub-Signature-256 header',
      ],
      testData:
          'payload={"event":"order.created","orderId":"ORD-12345"}, signature=invalid-signature, endpoint=https://api.qa-genie.com/webhooks/v1/orders, platform=API',
      steps: [
        'Prepare webhook payload: {"event":"order.created","orderId":"ORD-12345"}',
        'Set X-Hub-Signature-256 header to an invalid HMAC signature value',
        'Send POST request to webhook endpoint: https://api.qa-genie.com/webhooks/v1/orders',
        'Observe the HTTP response status code and body',
        'Check that no event processing occurred on the receiver side',
      ],
      expectedResult:
          'The webhook request is rejected with HTTP 401 Unauthorized. The response body contains: {"error":"Invalid signature","code":"SIGNATURE_MISMATCH"}. No order processing is triggered. The event is logged as "failed - invalid signature" in the webhook delivery logs.',
    ),
    ReferenceCase(
      title: 'API endpoint sync retries on timeout and eventually succeeds on third attempt',
      type: 'POSITIVE',
      priority: 'Medium',
      preconditions: [
        'API endpoint is configured with retry policy (max 3 retries, exponential backoff)',
        'Initial request will timeout due to simulated network latency',
        'Third attempt succeeds — endpoint returns 200 OK',
      ],
      testData:
          'endpoint=GET /api/v2/patients/sync, timeoutMs=5000, retryCount=3, backoff=2s,4s,8s, platform=API',
      steps: [
        'Initiate sync request: GET /api/v2/patients/sync with standard headers',
        'Observe first attempt — connection times out after 5 seconds',
        'Client waits 2 seconds (first backoff interval) and retries',
        'Observe second attempt — also times out after 5 seconds',
        'Client waits 4 seconds (second backoff interval) and retries',
        'Third attempt succeeds — receive HTTP 200 with full patient data payload',
        'Verify data integrity: all 150 patient records are synced correctly',
      ],
      expectedResult:
          'After two timeout retries, the third attempt succeeds with HTTP 200 OK. The response contains the full patient dataset (150 records, 2.3 MB). Data integrity check passes — all required fields are present. The retry mechanism logs all attempts with timestamps. No duplicate records are created.',
    ),
  ];
}
