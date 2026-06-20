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
        versionCode = 2
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
            )
        }
    }

    tasks.whenTaskAdded {
        if (name == "extractDeepLinksProdRelease") {
            mustRunAfter("processProdReleaseGoogleServices")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
