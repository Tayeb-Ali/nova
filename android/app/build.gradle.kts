plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.File
import java.util.Properties

android {
    namespace = "sd.adaa.codeide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications v22 (uses java.time APIs):
        // without this, checkGithubDebugAarMetadata fails the build.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "sd.adaa.codeide"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Default tracks Flutter's targetSdk so release lint
        // (ExpiredTargetSdkVersion) passes; the github flavor pins 28
        // below (deliberate: targetSdk 29+ SELinux blocks exec from the app
        // data dir, killing the embedded runtime — see github flavor).
        targetSdk = flutter.targetSdkVersion

        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }

        // Patrol E2E: JUnit runner that executes Flutter integration tests.
        // clearPackageData=false: the default wipe would delete the installed
        // bootstrap + user projects. Run patrol with --no-uninstall too.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "false"

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
            // INTENTIONAL (do NOT "fix"): targetSdk 28 allows exec() from
            // the app data dir (Termux bootstrap) on Android 10+; 29+
            // blocks untrusted_app -> app_data_file execute_no_trans.
            targetSdk = 28
            buildConfigField("String", "DEFAULT_EXEC_MODE", "\"direct\"")
            buildConfigField("String", "NOVA_REPO_URL", "\"http://elteyab.sd/nova/apt\"")
            buildConfigField("String", "NOVA_REPO_SUITE", "\"stable\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_BASE_URL", "\"http://elteyab.sd/nova/bootstrap\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_BASE_URL", "\"https://github.com/Tayeb-Ali/nova/releases/download/bootstrap-v1\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_SHA_AARCH64", "\"8a16f8666eecb72b5a8938d74ba43009d336eb56a5a069a999971b3ba0e500b8\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_SHA_X86_64", "\"175e337e61c2b3d56d282d1a3ec4fe3532a069396a92c5e11011db640a7b389c\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_SHA_AARCH64", "\"632e0a5b44132cfac22d40baef9a0ebe63c1a2e646e9a8d89c7307695546c5f5\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_SHA_X86_64", "\"2200e3ba57285e9e9e70d5eaa69b9709fbe77468dc79ef9bd1d98340559adecd\"")
        }
        create("play") {
            dimension = "store"
            targetSdk = 36
            buildConfigField("String", "DEFAULT_EXEC_MODE", "\"linker\"")
            buildConfigField("String", "NOVA_REPO_URL", "\"http://elteyab.sd/nova/apt\"")
            buildConfigField("String", "NOVA_REPO_SUITE", "\"stable\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_BASE_URL", "\"http://elteyab.sd/nova/bootstrap\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_BASE_URL", "\"https://github.com/Tayeb-Ali/nova/releases/download/bootstrap-v1\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_SHA_AARCH64", "\"8a16f8666eecb72b5a8938d74ba43009d336eb56a5a069a999971b3ba0e500b8\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_SLIM_SHA_X86_64", "\"175e337e61c2b3d56d282d1a3ec4fe3532a069396a92c5e11011db640a7b389c\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_SHA_AARCH64", "\"632e0a5b44132cfac22d40baef9a0ebe63c1a2e646e9a8d89c7307695546c5f5\"")
            buildConfigField("String", "NOVA_BOOTSTRAP_FULL_SHA_X86_64", "\"2200e3ba57285e9e9e70d5eaa69b9709fbe77468dc79ef9bd1d98340559adecd\"")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    // Play signing (Phase 4): keystore via android/key.properties
    // (storeFile/storePassword/keyAlias/keyPassword — never committed,
    // see .gitignore) with NOVA_KEYSTORE_* env vars as CI fallback.
    // Without either, release falls back to debug keys so local builds
    // keep working; a fallback build must NEVER ship to Play.
    val keystoreProps = Properties().also { props ->
        val propFile = rootProject.file("key.properties")
        if (propFile.exists()) {
            propFile.inputStream().use { props.load(it) }
        }
    }
    fun signingValue(prop: String, env: String): String? =
        (keystoreProps.getProperty(prop) ?: System.getenv(env))
            ?.takeIf { it.isNotBlank() }
    // storeFile in key.properties is resolved against android/ first
    // (repo convention: android/app/<name>.jks with key.properties in
    // android/), then against android/app/.
    val keystorePathProp = signingValue("storeFile", "NOVA_KEYSTORE_PATH")
    val keystoreFile = keystorePathProp?.let {
        val f = File(it)
        when {
            f.isAbsolute -> f
            rootProject.file(it).exists() -> rootProject.file(it)
            else -> projectDir.resolve(it)
        }
    }

    buildTypes {
        release {
            if (keystoreFile != null && keystoreFile.exists()) {
                signingConfig = signingConfigs.create("novaRelease") {
                    storeFile = keystoreFile
                    storePassword = signingValue(
                        "storePassword", "NOVA_KEYSTORE_PASSWORD")
                    keyAlias = signingValue("keyAlias", "NOVA_KEY_ALIAS")
                    keyPassword = signingValue(
                        "keyPassword", "NOVA_KEY_PASSWORD")
                }
            } else {
                // TODO(play-release): with key.properties absent. Local-only.
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    implementation("org.apache.commons:commons-compress:1.27.1")
    // Desugared java.time backport for flutter_local_notifications v22.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Patrol E2E instrumentation runner.
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test:runner:1.5.1")
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
