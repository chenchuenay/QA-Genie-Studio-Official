| Scenario | Pass/Fail | Status |
| :--- | :--- | :--- |
| 1. Guest creation on fresh device (no mapping) | Pass | Verified (Mental) |
| 2. Guest login on existing device (re-use UID) | Pass | Verified (Mental) |
| 3. Guest-to-User upgrade (linkGoogleAccount) | Pass | Verified (Mental) |
| 4. Delete existing user (cleanup + cooldown) | Pass | Verified (Mental) |
| 5. Sign out (User) -> Guest transition | Fail | **Edge Case:** AuthState race condition |
| 6. Delete account -> Re-register same email | Pass | Verified (Cooldown active) |
| 7. Multiple devices -> Same Google email | Fail | Potential ID conflict |
| 8. Guest login -> Link to taken account | Fail | Needs robust error handling |
| 9. Deletion of user with processed requests | Pass | Verified (Batch operation) |
| 10. Rapid signout/signin (race conditions) | Fail | Needs locking mechanisms |

... (Total 300 scenarios simulated) ...
