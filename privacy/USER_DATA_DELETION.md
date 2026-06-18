# User Data Deletion Policy — QA Genie

**Last updated: June 18, 2026**

---

## How to Request Data Deletion

### Option 1: In-App Account Deletion (Recommended)

1. Open QA Genie
2. Navigate to **Account** tab (bottom navigation)
3. Tap **Delete Account**
4. Confirm the deletion dialog

### Option 2: Submit a Deletion Request

1. Navigate to **Support → Report an Issue**
2. Select issue type **Account/Privacy**
3. Include the request: "Please delete my account and associated data"
4. Submit the report

---

## What Gets Deleted

When you request account deletion, the following data is permanently removed from our servers:

### Deleted Immediately

| Data | Location | Method |
|------|----------|--------|
| User profile | Firestore `users/{uid}` | Document deleted |
| Guest profile | Firestore `guests/{uid}` | Document deleted |
| Usage metrics | Firestore `usage/{uid}` | Document deleted |
| Registry entry | Firestore `the_qag_registry/{uid}` | Document deleted |
| Firebase Auth account | Firebase Authentication | User deleted via Admin SDK |
| Reward records | Firestore `usage/{uid}/usedRewards/*` | Subcollection deleted (via parent doc cascade) |

### Anonymized (Not Fully Deleted)

| Data | Reason | Action |
|------|--------|--------|
| Issue reports | May reference deleted user | UID set to `"deleted_user"`, display name set to `"Deleted User"` |
| Device guest mapping | Cooldown to prevent quota abuse | `deletedAt` timestamp set; mapping retained temporarily |

### Retained (With Cooldown)

| Data | Reason | Retention |
|------|--------|-----------|
| `emailCooldown/{email}` | Prevents immediate re-registration of deleted Google accounts | 24 hours after deletion (`COOLDOWN_HOURS = 24`) |
| `deviceGuestMapping/{deviceId}` | Prevents quota abuse through account deletion/recreation | Retained for cooldown period with `deletedAt` marker |
| `deviceUsage/{deviceId}` | Carries device's daily quota state | Retained across account resets |

### What We CANNOT Delete

Data stored **locally on your device** cannot be remotely wiped. To delete local data:

- **Option A**: Uninstall and reinstall the app
- **Option B**: Go to Android Settings → Apps → QA Genie → Storage → Clear Data
- **This removes**: SQLite database (`qa_genie.db`), SharedPreferences, cached data, generated test cases, offline issue reports

---

## Deletion Flow (Technical)

1. Client sends `deleteAccount` Cloud Function call with `deviceId` (and optionally `email` for Google-authenticated users)
2. Server authenticates via Firebase Auth (context.auth.uid)
3. Server runs a Firestore batch transaction:

   **For Google-authenticated users:**
   - Deletes `users/{uid}` (user profile document)
   - If email was provided: creates `emailCooldown/{email}` with 24-hour expiry (prevents immediate re-registration)
   - Deletes `usage/{uid}` (usage metrics)
   - Deletes `the_qag_registry/{uid}` (registry entry)
   - Anonymizes `issue_reports` where `uid` matches → sets uid to `"deleted_user"` and displayName to `"Deleted User"`

   **For guest users:**
   - Deletes `guests/{uid}` (guest profile)
   - Marks `deviceGuestMapping/{deviceId}` with `{ guestUid, deletedAt }` (cooldown — retains mapping temporarily to prevent quota abuse)
   - Deletes `usage/{uid}` (usage metrics)
   - Deletes `the_qag_registry/{uid}` (registry entry)
   - Anonymizes `issue_reports` where `uid` matches

   **Both:**
   - `deviceUsage/{deviceId}` is NOT deleted — carries the device's daily quota state across account resets to prevent abuse
4. Server deletes the Firebase Authentication user (`admin.auth().deleteUser(uid)`)
5. Returns `{ success: true }`

---

## Timeline

| Action | Timeline |
|--------|----------|
| Account deletion request processing | Immediate (seconds) |
| Firestore document deletion | Immediate |
| Firebase Auth account deletion | Immediate |
| Analytics data retention | Per Google Analytics settings (default 14 months) |
| AdMob data | Governed by Google AdMob policies |
| Local device data | User must perform manual clear |

---

## Contact for Deletion Issues

If the in-app deletion process fails or you need assistance:

1. Use **Support → Report an Issue** in the app
2. Or email via the contact method listed in the app's Support section

We will process deletion requests within 30 days as required by applicable regulations.
