import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.charset.StandardCharsets
import java.util.Properties
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream
import org.gradle.api.GradleException

val supportedReleaseAbis = listOf("arm64-v8a", "armeabi-v7a")
val unsupportedBundleAbis = listOf("x86", "x86_64")

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
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
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.manaposter.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = adMobAppIdProvider.get()
        ndk {
            abiFilters += supportedReleaseAbis
        }
    }

    packaging {
        jniLibs {
            // Mana Poster targets Android phones. Keep x86 variants out of the
            // release bundle so heavy native editor/video libraries ship only
            // for ARM devices.
            excludes += unsupportedBundleAbis.map { "**/$it/*.so" }
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
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.activity:activity-ktx:1.9.0")
    implementation("androidx.work:work-runtime-ktx:2.10.5")
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:review:2.0.2")
}

val releaseBundlePath =
    layout.buildDirectory.file("outputs/bundle/release/app-release.aab")

fun deleteInvalidFlutterDepfile(variant: String) {
    val depfile = layout.buildDirectory.file("intermediates/flutter/$variant/flutter_build.d").get().asFile
    if (!depfile.exists()) {
        return
    }
    val prefix = depfile.inputStream().use { input ->
        val buffer = ByteArray(256)
        val bytesRead = input.read(buffer)
        if (bytesRead <= 0) {
            ""
        } else {
            String(buffer, 0, bytesRead, StandardCharsets.UTF_8)
        }
    }
    if (!prefix.contains(": ")) {
        logger.lifecycle("Deleting invalid Flutter depfile: ${depfile.absolutePath}")
        depfile.delete()
    }
}

deleteInvalidFlutterDepfile("debug")
deleteInvalidFlutterDepfile("release")
deleteInvalidFlutterDepfile("profile")

fun shouldStripBundleEntry(path: String): Boolean =
    unsupportedBundleAbis.any { abi ->
        path.startsWith("base/lib/$abi/") ||
            path.startsWith("BUNDLE-METADATA/com.android.tools.build.debugsymbols/$abi/")
    }

val sanitizeReleaseBundleAbis by tasks.registering {
    dependsOn("bundleRelease")
    doLast {
        val bundleFile = releaseBundlePath.get().asFile
        if (!bundleFile.exists()) {
            throw GradleException("Release AAB not found: ${bundleFile.absolutePath}")
        }

        val tempFile = File(bundleFile.parentFile, "${bundleFile.name}.tmp")
        if (tempFile.exists()) {
            tempFile.delete()
        }

        ZipFile(bundleFile).use { source ->
            ZipOutputStream(FileOutputStream(tempFile)).use { output ->
                source.entries().asSequence().forEach { entry ->
                    if (shouldStripBundleEntry(entry.name)) {
                        return@forEach
                    }
                    val copy = ZipEntry(entry.name).apply {
                        method = entry.method
                        comment = entry.comment
                        extra = entry.extra
                        time = entry.time
                        if (entry.method == ZipEntry.STORED) {
                            size = entry.size
                            compressedSize = entry.compressedSize
                            crc = entry.crc
                        }
                    }
                    output.putNextEntry(copy)
                    if (!entry.isDirectory) {
                        source.getInputStream(entry).use { input ->
                            input.copyTo(output)
                        }
                    }
                    output.closeEntry()
                }
            }
        }

        if (!bundleFile.delete() || !tempFile.renameTo(bundleFile)) {
            throw GradleException("Failed to replace sanitized AAB at ${bundleFile.absolutePath}")
        }
    }
}

val verifyReleaseBundleAbis by tasks.registering {
    dependsOn(sanitizeReleaseBundleAbis)
    doLast {
        val bundleFile = releaseBundlePath.get().asFile
        val bundledLibs = mutableListOf<String>()
        ZipFile(bundleFile).use { bundle ->
            bundle.entries().asSequence().forEach { entry ->
                if (entry.name.startsWith("base/lib/")) {
                    bundledLibs += entry.name
                }
                if (shouldStripBundleEntry(entry.name)) {
                    throw GradleException(
                        "Unsupported ABI entry still present in release AAB: ${entry.name}",
                    )
                }
            }
        }
        logger.lifecycle("Verified release AAB native libs: ${bundledLibs.joinToString()}")
    }
}

tasks.whenTaskAdded {
    if (name == "bundleRelease") {
        finalizedBy(verifyReleaseBundleAbis)
    }
}
