plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.reliefnet.app.relief_net"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.reliefnet.app.relief_net"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Auth0 Flutter (Universal Login redirect). Override via Gradle property, e.g.
        //   ./gradlew assembleDebug -P AUTH0_DOMAIN=dev-xx.us.auth0.com -P AUTH0_SCHEME=reliefnet
        manifestPlaceholders["auth0Domain"] =
            (project.findProperty("AUTH0_DOMAIN") as String?)
                ?: "dev-vbjhh7iok0ix176c.us.auth0.com"
        manifestPlaceholders["auth0Scheme"] =
            (project.findProperty("AUTH0_SCHEME") as String?) ?: "reliefnet"
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
