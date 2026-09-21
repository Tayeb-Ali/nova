package sd.adaa.codeide

import android.content.Context
import android.os.Build
import java.io.File

/**
 * Central path + environment definitions for the embedded Termux-style runtime.
 * Layout (see plan.md):
 *   filesDir/usr       bootstrap prefix (PREFIX)
 *   filesDir/home      HOME
 *   filesDir/projects  IDE workspace
 *   filesDir/cache     scratch
 */
object EnvironmentManager {
    const val PACKAGE_NAME = "sd.adaa.codeide"

    /** aarch64 bootstrap pinned in-repo (default for arm64 phones). */
    const val ARCH_AARCH64 = "aarch64"
    const val BOOTSTRAP_ASSET_AARCH64 = "bootstrap-aarch64.zip"
    const val BOOTSTRAP_SHA256_AARCH64 = "4fa66c681eefb16b71d2fa5118609f5bb5ce449fc815edee2762e22b1a9b7a26"

    /** x86_64 bootstrap pinned in-repo (for x86_64 emulators / Android-x86 devices). */
    const val ARCH_X86_64 = "x86_64"
    const val BOOTSTRAP_ASSET_X86_64 = "bootstrap-x86_64.zip"
    const val BOOTSTRAP_SHA256_X86_64 = "f73fd8ea465b5065d94e5af27bce893f3968d3ec901f02f42ef3b71e4a231e2c"

    const val EVENTS_CHANNEL = "sd.adaa.codeide/events"

    /**
     * First-hop execution mode for spawned prefix binaries.
     * Phase 0 linker-exec spike: `direct` preserves current behavior exactly;
     * `linker` routes the first hop through `/system/bin/linker64` so the
     * kernel only ever sees a system binary being exec'd (the mechanism the
     * target-36 model will rely on). Opt-in only — default is `direct`.
     */
    const val EXEC_MODE_DIRECT = "direct"
    const val EXEC_MODE_LINKER = "linker"
    const val ENV_EXEC_MODE = "NOVA_EXEC_MODE"
    const val SYSTEM_LINKER = "/system/bin/linker64"

    fun filesDir(context: Context): File = context.filesDir

    fun prefix(context: Context): File = File(filesDir(context), "usr")

    fun home(context: Context): File = File(filesDir(context), "home")

    fun projectsDir(context: Context): File = File(filesDir(context), "projects")

    fun cacheDir(context: Context): File = File(filesDir(context), "cache")

    /**
     * Resolves the bootstrap ABI for this device: aarch64 on arm64,
     * x86_64 on x86_64, arm on armeabi-v7a, i686 on x86.
     */
    fun arch(): String {
        val abi = Build.SUPPORTED_ABIS.firstOrNull()?.lowercase().orEmpty()
        return when {
            abi.contains("aarch64") || abi.contains("arm64") -> ARCH_AARCH64
            abi.contains("x86_64") -> ARCH_X86_64
            abi.contains("armeabi") || abi.startsWith("arm") -> "arm"
            abi.contains("x86") -> "i686"
            else -> ARCH_AARCH64
        }
    }

    fun bootstrapAssetName(): String = "bootstrap-${arch()}.zip"

    /** Returns null when no bootstrap asset is bundled for this ABI. */
    fun bootstrapSha256(): String? = when (arch()) {
        ARCH_AARCH64 -> BOOTSTRAP_SHA256_AARCH64
        ARCH_X86_64 -> BOOTSTRAP_SHA256_X86_64
        else -> null
    }

    fun bootstrapZip(context: Context): File = File(filesDir(context), "bootstrap-${arch()}.zip")

    fun isBootstrapInstalled(context: Context): Boolean =
        File(prefix(context), "bin/bash").exists()

    fun bootstrapVersion(context: Context): String? {
        val stamp = File(filesDir(context), ".bootstrap-version")
        return if (stamp.exists()) stamp.readText().trim() else null
    }

    /**
     * Environment for every spawned shell/process (task.md §18 §19).
     */
    fun buildEnvironment(context: Context, projectPath: String? = null, execMode: String = EXEC_MODE_DIRECT): Map<String, String> {
        val prefix = prefix(context)
        val home = home(context)
        val base = mapOf(
            "PREFIX" to prefix.absolutePath,
            "HOME" to home.absolutePath,
            "TMPDIR" to File(prefix, "tmp").absolutePath,
            "LANG" to "C.UTF-8",
            "TERM" to "xterm-256color",
            "PATH" to "${prefix.absolutePath}/bin",
            "LD_LIBRARY_PATH" to "${prefix.absolutePath}/lib",
            "LD_PRELOAD" to "${prefix.absolutePath}/lib/libtermux-exec-ld-preload.so",
            "TERMUX_APP__PACKAGE_NAME" to PACKAGE_NAME,
            "TERMUX_MAIN_PACKAGE_FORMAT" to "debian",
            "ANDROID_DATA" to "/data",
            "EXTERNAL_STORAGE" to "/sdcard",
            ENV_EXEC_MODE to execMode,
        )
        return if (projectPath != null) {
            base + mapOf("APP_WORKSPACE" to projectPath)
        } else {
            base
        }
    }
}