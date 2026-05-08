import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val adMobAppIdProvider = providers
    .gradleProperty("MANA_POSTER_ADMOB_APP_ID")
    .orElse(providers.environmentVariable("MANA_POSTER_ADMOB_APP_ID"))
    .orElse("ca-app-pub-6393573098485696~1876908235")

val keystoreStoreFileProvider = providers
    .gradleProperty("MANA_POSTER_KEYSTORE_FILE")
    .orElse(providers.environmentVariable("MANA_POSTER_KEYSTORE_FILE"))
val keystoreAliasProvider = providers
    .gradleProperty("MANA_POSTER_KEY_ALIAS")
    .orElse(providers.environmentVariable("MANA_POSTER_KEY_ALIAS"))
val keystoreStorePasswordProvider = providers
    .gradleProperty("MANA_POSTER_KEYSTORE_PASSWORD")
    .orElse(providers.environmentVariable("MANA_POSTER_KEYSTORE_PASSWORD"))
val keystoreKeyPasswordProvider = providers
    .gradleProperty("MANA_POSTER_KEY_PASSWORD")
    .orElse(providers.environmentVariable("MANA_POSTER_KEY_PASSWORD"))

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

val hasEnvReleaseKeystore =
    !keystoreStoreFileProvider.orNull.isNullOrBlank() &&
        !keystoreAliasProvider.orNull.isNullOrBlank() &&
        !keystoreStorePasswordProvider.orNull.isNullOrBlank() &&
        !keystoreKeyPasswordProvider.orNull.isNullOrBlank()
val hasFileReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "com.manaposter.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.manaposter.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = adMobAppIdProvider.get()
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    packaging {
        jniLibs {
            keepDebugSymbols += listOf("**/libonnxruntime.so")
        }
    }

    signingConfigs {
        create("release") {
            val envStoreFile = keystoreStoreFileProvider.orNull
            val envAlias = keystoreAliasProvider.orNull
            val envStorePassword = keystoreStorePasswordProvider.orNull
            val envKeyPassword = keystoreKeyPasswordProvider.orNull

            if (!envStoreFile.isNullOrBlank() &&
                !envAlias.isNullOrBlank() &&
                !envStorePassword.isNullOrBlank() &&
                !envKeyPassword.isNullOrBlank()
            ) {
                storeFile = file(envStoreFile)
                keyAlias = envAlias
                storePassword = envStorePassword
                keyPassword = envKeyPassword
            } else if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (!hasEnvReleaseKeystore && !hasFileReleaseKeystore) {
                throw GradleException(
                    "Release signing is not configured. Set MANA_POSTER_KEYSTORE_* env vars or provide android/key.properties before building a release.",
                )
            }
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
