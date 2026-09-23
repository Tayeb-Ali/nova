plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "sd.adaa.codeide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "sd.adaa.codeide"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Target 28 to allow exec() from app data directory (Termux bootstrap) on Android 10+;
        // targetSdk 29+ blocks untrusted_app -> app_data_file execute_no_trans (see logcat avc denied).
        targetSdk = 28 //TODO: check this line  to targetSdk = flutter.targetSdkVersion

        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }

        externalNativeBuild {
            cmake {
                cFlags += "-std=c99"
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }

    // Store flavors (Phase 1 production integration):
    // - github: targetSdk 28 + direct exec (current shipping behavior).
    // - play: targetSdk 36 + linker exec via libnova-exec (the tested gate).
    // DEFAULT_EXEC_MODE is read by EnvironmentManager.buildEnvironment so every
    // spawn path follows the flavor without call-site changes.
    // NOVA_REPO_URL: when non-empty the installer points apt at the Nova
    // binary repository instead of the legacy Termux mirror (Phase 2). Empty
    // keeps today's behavior -> bundled Termux bootstrap + packages-cf mirror.
    // Phase 2 download model: bootstraps are NOT bundled in the APK. The setup
    // screen offers slim/full variants hosted remotely; SHAs pin each artifact.
    //   slim -> GitHub Pages (fast, ~67MB each)
    //   full -> GitHub Release assets (offline-everything, ~283MB each)
    flavorDimensions += "store"
    productFlavors {
        create("github") {
            dimension = "store"
            // Inherits defaultConfig targetSdk = 28.
            buildConfigField("String", "DEFAULT_EXEC_MODE", "\"direct\"")
            buildConfigField("String", "NOVA_REPO_URL", "\"https://tayeb-ali.github.io/nova/apt\"")
            buildConfigField("String", "NOVA_REPO_SUITE", "\"stable\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_BASE_URL", "\"https://tayeb-ali.github.io/nova/bootstrap\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_BASE_URL", "\"https://github.com/Tayeb-Ali/nova/releases/download/bootstrap-v1\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_SHA_AARCH64", "\"783355eaa4768f61b44e5e5406d55c8049131272d7d4224ac09dfe03ad70d8b6\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_SHA_X86_64", "\"79df3d4dd3aa32516990ac0a3786e2e2d494196e4f3ccc3c273439bd134b3559\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_SHA_AARCH64", "\"632e0a5b44132cfac22d40baef9a0ebe63c1a2e646e9a8d89c7307695546c5f5\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_SHA_X86_64", "\"2200e3ba57285e9e9e70d5eaa69b9709fbe77468dc79ef9bd1d98340559adecd\"")
        }
        create("play") {
            dimension = "store"
            targetSdk = 36
            buildConfigField("String", "DEFAULT_EXEC_MODE", "\"linker\"")
            buildConfigField("String", "NOVA_REPO_URL", "\"https://tayeb-ali.github.io/nova/apt\"")
            buildConfigField("String", "NOVA_REPO_SUITE", "\"stable\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_BASE_URL", "\"https://tayeb-ali.github.io/nova/bootstrap\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_BASE_URL", "\"https://github.com/Tayeb-Ali/nova/releases/download/bootstrap-v1\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_SHA_AARCH64", "\"783355eaa4768f61b44e5e5406d55c8049131272d7d4224ac09dfe03ad70d8b6\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_SHA_X86_64", "\"79df3d4dd3aa32516990ac0a3786e2e2d494196e4f3ccc3c273439bd134b3559\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_SHA_AARCH64", "\"632e0a5b44132cfac22d40baef9a0ebe63c1a2e646e9a8d89c7307695546c5f5\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_SHA_X86_64", "\"2200e3ba57285e9e9e70d5eaa69b9709fbe77468dc79ef9bd1d98340559adecd\"")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("org.apache.commons:commons-compress:1.27.1")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
