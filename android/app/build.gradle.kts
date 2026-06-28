import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

val keystoreFilePath = keystoreProperties.getProperty("storeFile")
val keystoreFile = if (keystoreFilePath != null) file(keystoreFilePath) else null
val keystoreStorePassword = keystoreProperties.getProperty("storePassword")
val keystoreKeyAlias = keystoreProperties.getProperty("keyAlias")
val keystoreKeyPassword = keystoreProperties.getProperty("keyPassword")

val dartDefines = (project.findProperty("dart-defines") as? String)?.split(",") ?: emptyList()
val isDevBuild = dartDefines.any { def ->
    try { String(Base64.getDecoder().decode(def)) == "IS_DEV=true" } catch (_: Exception) { false }
}

android {
    namespace = "com.enaykumar.qagenie"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.enaykumar.qagenie"
        minSdk = 24
        targetSdk = 36
        versionCode = 23
        multiDexEnabled = true
        manifestPlaceholders["appName"] = "QA Genie"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    signingConfigs {
        create("release") {
            if (isDevBuild) {
                storeFile = file("qa_genie_dev.jks")
                storePassword = "dev123456"
                keyAlias = "dev"
                keyPassword = "dev123456"
            } else {
                storeFile = keystoreFile
                storePassword = keystoreStorePassword
                keyAlias = keystoreKeyAlias
                keyPassword = keystoreKeyPassword
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    tasks.whenTaskAdded {
        if (name == "bundleRelease") {
            doLast {
                val dir = file("${project.buildDir}/outputs/bundle/release")
                val src = dir.resolve("app-release.aab")
                val dst = dir.resolve("QA-Genie_release-v${flutter.versionName}.aab")
                if (src.exists()) { src.renameTo(dst) }
            }
        }
        if (name == "assembleRelease") {
            doLast {
                val dir = file("${project.buildDir}/outputs/flutter-apk")
                val src = dir.resolve("app-release.apk")
                val dst = dir.resolve("QA-Genie_release-v${flutter.versionName}.apk")
                if (src.exists()) { src.renameTo(dst) }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.unity3d.ads:unity-ads:4.18.0")
    implementation("com.google.ads.mediation:unity:4.18.0.0")
}
