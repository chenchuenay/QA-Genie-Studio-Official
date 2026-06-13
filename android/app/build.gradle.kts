plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.enaykumar.qagenie"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.enaykumar.qagenie"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        multiDexEnabled = true
    }

    flavorDimensions.add("mode")
    productFlavors {
        create("dev") {
            dimension = "mode"
            versionName = "${flutter.versionName}-dev"
        }
        create("prod") {
            dimension = "mode"
            versionName = flutter.versionName
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

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}