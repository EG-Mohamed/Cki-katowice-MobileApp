import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Explicit local QA builds can use the debug key without changing production signing.
val localTestSigning = providers.gradleProperty("localTestSigning").orNull == "true"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val keystoreFile = keystoreProperties["storeFile"]?.let { file(it) }
val realReleaseSigningAvailable = !localTestSigning &&
    keystorePropertiesFile.exists() &&
    keystoreFile?.exists() == true

android {
    namespace = "pl.ckikatowice.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "pl.ckikatowice.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // AGP configures every build type at configuration time regardless
            // of which variant is actually being assembled (e.g. `assembleDebug`
            // still evaluates this block), so falling back to the debug config
            // here must not fail the build outright. The real, loud failure is
            // registered below and only fires when a release task actually runs.
            signingConfig = if (realReleaseSigningAvailable) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

if (!realReleaseSigningAvailable && !localTestSigning) {
    tasks.matching {
        it.name.startsWith("assembleRelease") ||
            it.name.startsWith("bundleRelease") ||
            it.name.startsWith("packageRelease")
    }.configureEach {
        doFirst {
            throw GradleException(
                "Release build requested without a valid upload keystore. " +
                    "Create android/key.properties (see key.properties.example) pointing at a " +
                    "real .jks file, or pass -PlocalTestSigning=true for a local QA build signed " +
                    "with the debug key."
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
}
