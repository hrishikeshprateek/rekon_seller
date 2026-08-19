import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // Updated application package / namespace
    namespace = "com.reckon.reckonbiz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // applicationId is set per product flavor below (reckon / amareorder).
        // namespace stays com.reckon.reckonbiz so MainActivity + MethodChannels
        // (com.reckon.reckonbiz/files, /screenshot) work for every flavor.
        // Android 10 (API 29) — required minimum.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Default app name; each flavor overrides via manifestPlaceholders.
        manifestPlaceholders["appLabel"] = "Reckon Seller 2.0"
    }

    flavorDimensions += "brand"
    productFlavors {
        create("reckon") {
            dimension = "brand"
            applicationId = "com.reckon.reckonbiz"
            manifestPlaceholders["appLabel"] = "Reckon Seller 2.0"
        }
        create("amareorder") {
            dimension = "brand"
            applicationId = "com.reckon.amareorder"
            manifestPlaceholders["appLabel"] = "Amar eOrder"
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing if key.properties is absent, so
            // `flutter run --release` still works without the upload keystore.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
