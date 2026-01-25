plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.finora_frontend"
    // Configuración de SDK para compatibilidad con Android 8.0+ (95% de dispositivos activos)
    compileSdk = 36  // Android 15 - Requerido por plugins path_provider_android y shared_preferences_android
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.finora_frontend"
        // Compatibilidad con Android 8.0 (API 26) o superior
        // Cubre aproximadamente 95% de dispositivos Android activos
        minSdk = 26  // Android 8.0 Oreo
        targetSdk = 36  // Android 15 (actualizado para compatibilidad con plugins)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Suprimir warnings de versiones obsoletas de Java
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-options")
}
