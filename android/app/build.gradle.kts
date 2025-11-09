// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tu_alimento_diario"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.tu_alimento_diario"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ---- Firma de release (lee android/key.properties) ----
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        // Crea config de release solo si hay key.properties
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                // Ejemplo de key.properties:
                // storePassword=*****
                // keyPassword=*****
                // keyAlias=upload
                // storeFile=app/my-release-key.jks
                val storeFilePath = keystoreProperties["storeFile"] as String?
                if (!storeFilePath.isNullOrBlank()) {
                    storeFile = file(storeFilePath)
                }
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = (keystoreProperties["keyAlias"] as String?) ?: "upload"
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Si existe la config de release, usarla; si no, cae a debug para no romper el build.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")

            // Dejalo desactivado por ahora; podés activarlo cuando pruebes que corre bien en release.
            // minifyEnabled = true
            // shrinkResources = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
        // No cambio tu buildType debug
        // debug { ... (usa por defecto la firma debug) }
    }
}

flutter {
    source = "../.."
}
