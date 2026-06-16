[2026-06-14 15:30:00] | Stale Quota UI | UsageManager state not refreshed on app foreground | OPEN
[2026-06-14 15:30:00] | Auth Database Race | DatabaseService initialized before AuthService user is ready | OPEN
[2026-06-14 15:30:00] | Input Overflow | TextFields missing length constraints allowing prompt injection | OPEN
[2026-06-14 16:00:00] | Non-Atomic Guest Registry | registry update outside of guestCounter transaction | OPEN
[2026-06-14 16:00:00] | Identity Initialization Race | DatabaseService.initDatabase called with placeholder before Guest identity assignment | OPEN
[2026-06-14 16:00:00] | Stale Identity UI | HomeScreen identity not observing registry updates | OPEN
[2026-06-14 16:30:00] | MasterTable empty state | UI renders blank screen on empty test case array | OPEN
[2026-06-14 16:30:00] | Excessive Firestore Writes | autoSave triggers on every keystroke causing billing bloat | OPEN
[2026-06-14 16:30:00] | Stale AppBar Metrics | PreviewScreen header fails to reflect case count updates after fallback generation | OPEN
[2026-06-14 17:00:00] | Export File Collision | Race condition in file naming allowing PDF overwrites | OPEN
[2026-06-14 17:00:00] | PDF Sanitization Escape | AI-generated complex UTF-8 chars crash PDF adapter | OPEN
[2026-06-14 17:00:00] | Navigation Lockout | User can navigate away while MasterTable is in edit mode | OPEN
[2026-06-14 17:30:00] | Unauthorized Suite Access | Repository queries lack ownership validation (UID check) | RESOLVED
[2026-06-14 17:30:00] | Data Load Performance | Suite listing loads all records, lacking pagination | OPEN
[2026-06-14 17:30:00] | Stale Transparency Disclosure | Footer text not updated to "Hybrid-logic generation orchestrated..." | RESOLVED
[2026-06-14 18:00:00] | IDOR Suite Deletion | Deletion/Rename logic lacks user ownership validation | OPEN
[2026-06-14 18:00:00] | Unbounded Rename Input | Rename dialog permits empty or excessively large strings | RESOLVED
[2026-06-14 18:00:00] | UI Flicker on Refresh | Refreshing list relies on full rebuild, causing jumpy UI | RESOLVED
[2026-06-14 18:30:00] | Pro-Bypass Vulnerability | Backend relies on client-provided isPro flag | RESOLVED
[2026-06-14 18:30:00] | Native Ad Leak | NativeAdWidget fails to dispose of ad resource on scroll | OPEN
[2026-06-14 18:30:00] | AdMob Lifecycle Crash | Attempting to show rewarded ad while app is backgrounded | OPEN

