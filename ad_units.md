### QA_Genie AD UNITS

## rewarded_tc_generation

Complete the instructions in the Google Mobile Ads SDK guide using this app ID:
QA Genieca-app-pub-5950082050771694~6664703624
Follow the rewarded implementation guide to integrate the SDK. You'll specify ad type and placement when you integrate the code using this ad unit ID:
rewarded_tc_generationca-app-pub-5950082050771694/8569180768

## rewarded_tc_export

Complete the instructions in the Google Mobile Ads SDK guide using this app ID:
QA Genieca-app-pub-5950082050771694~6664703624
Follow the rewarded implementation guide to integrate the SDK. You'll specify ad type and placement when you integrate the code using this ad unit ID:
rewarded_tc_exportca-app-pub-5950082050771694/2889478678

## rewarded_summary_export

Complete the instructions in the Google Mobile Ads SDK guide using this app ID:
QA Genieca-app-pub-5950082050771694~6664703624
Follow the rewarded implementation guide to integrate the SDK. You'll specify ad type and placement when you integrate the code using this ad unit ID:
rewarded_summary_exportca-app-pub-5950082050771694/6327533956

## interstitial_general

Complete the instructions in the Google Mobile Ads SDK guide using this app ID:
QA Genieca-app-pub-5950082050771694~6664703624
Follow the interstitial implementation guide to integrate the SDK. You'll specify ad type and placement when you integrate the code using this ad unit ID:
interstitial_generalca-app-pub-5950082050771694/4276085687

## suites_native_sponsored

Complete the instructions in the Google Mobile Ads SDK guide using this app ID:
QA Genieca-app-pub-5950082050771694~6664703624
Follow the native advanced implementation guide to integrate the SDK. You'll specify ad type, size and placement when you integrate the code using this ad unit ID:
suites_native_sponsoredca-app-pub-5950082050771694/9143895834

### AD MEDIATION

#### Native Dependencies (`android/app/build.gradle.kts`)

```kotlin
dependencies {
    // ...
    implementation("com.unity3d.ads:unity-ads:4.18.0")
    implementation("com.google.ads.mediation:unity:4.18.0.0")
    // AppLovin (TODO)
    // Mintegral (TODO)
    // InMobi (TODO)
}
```

#### UNITY ADS

APP ID (Game ID): `800077172`

Placement       | ID
----------------|--------------------------
Rewarded        | Rewarded_Android
Banner          | Banner_Android
Interstitial    | Interstitial_Android

**AdMob Mediation setup (per ad unit):**
1. Go to AdMob → Mediation → Create mediation group
2. Add ad unit IDs for rewarded_tc_generation, rewarded_tc_export, rewarded_summary_export
3. Add Unity Ads as ad source → enter App ID `800077172`, Placement ID `Rewarded_Android`
4. Repeat for banner/suites_native_sponsored → use `Banner_Android`
5. Repeat for interstitial_general → use `Interstitial_Android`

#### NETWORKS TO ADD (TODO — after account creation & placement IDs)
- AppLovin — add `build.gradle.kts` dependency + AdMob Mediation source
- Mintegral — add `build.gradle.kts` dependency + AdMob Mediation source
- InMobi — add `build.gradle.kts` dependency + AdMob Mediation source
