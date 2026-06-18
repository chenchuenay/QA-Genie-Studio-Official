import admin from 'firebase-admin';
import { getApp } from 'firebase-admin/app';

try {
  admin.initializeApp({ projectId: 'qa-genie-ai' });
} catch (_) {
  // Already initialized
}

try {
  const func = admin.functions().httpsCallable('getOrCreateGuestToken');
  const result = await func({ deviceId: 'test-device-123' });
  console.log('SUCCESS:', JSON.stringify(result, null, 2));
} catch (e) {
  console.error('ERROR CODE:', e.code);
  console.error('ERROR MSG:', e.message);
  console.error('DETAILS:', JSON.stringify(e.details));
}
