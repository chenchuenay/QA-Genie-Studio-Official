import java.util.Properties

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

android {
    namespace = "com.enaykumar.qagenie"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.enaykumar.qagenie"
        minSdk = 24
        targetSdk = 36
        versionCode = 16
        multiDexEnabled = true
    }

    flavorDimensions.add("mode")
    productFlavors {
        create("dev") {
            dimension = "mode"
            applicationId = "com.enaykumar.qagenie_dev"
            versionName = "${flutter.versionName}-dev"
            manifestPlaceholders["appName"] = "QAG Dev"
        }
        create("prod") {
            dimension = "mode"
            versionName = flutter.versionName
            manifestPlaceholders["appName"] = "QA Genie"
        }
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
            storeFile = keystoreFile
            storePassword = keystoreStorePassword
            keyAlias = keystoreKeyAlias
            keyPassword = keystoreKeyPassword
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
        if (name == "extractDeepLinksProdRelease") {
            mustRunAfter("processProdReleaseGoogleServices")
        }
        if (name == "extractDeepLinksDevRelease") {
            mustRunAfter("processDevReleaseGoogleServices")
        }
    }

    tasks.whenTaskAdded {
        if (name == "bundleProdRelease") {
            doLast {
                val dir = file("${project.buildDir}/outputs/bundle/prodRelease")
                val src = dir.resolve("app-prod-release.aab")
                val dst = dir.resolve("QA-Genie_release-v${flutter.versionName}.aab")
                if (src.exists()) { src.renameTo(dst) }
            }
        }
        if (name == "assembleProdRelease") {
            doLast {
                val dir = file("${project.buildDir}/outputs/flutter-apk")
                val src = dir.resolve("app-prod-release.apk")
                val dst = dir.resolve("QA-Genie_release-v${flutter.versionName}.apk")
                if (src.exists()) { src.renameTo(dst) }
            }
        }
        if (name == "bundleDevRelease") {
            doLast {
                val dir = file("${project.buildDir}/outputs/bundle/devRelease")
                val src = dir.resolve("app-dev-release.aab")
                val dst = dir.resolve("QA-Genie_dev-v${flutter.versionName}.aab")
                if (src.exists()) { src.renameTo(dst) }
            }
        }
        if (name == "assembleDevRelease") {
            doLast {
                val dir = file("${project.buildDir}/outputs/flutter-apk")
                val src = dir.resolve("app-dev-release.apk")
                val dst = dir.resolve("QA-Genie_dev-v${flutter.versionName}.apk")
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
