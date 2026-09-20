package sd.adaa.codeide

import android.content.Context
import sd.adaa.codeide.process.ProcessManager
import sd.adaa.codeide.project.ProjectManager
import sd.adaa.codeide.runtime.BootstrapInstaller
import sd.adaa.codeide.runtime.RuntimeManager
import sd.adaa.codeide.terminal.TerminalManager

/**
 * Singleton owning every manager (task.md §26). Managers are created lazily with
 * the application context so processes/terminals survive the Activity.
 */
object IdeCore {
    lateinit var appContext: Context
        private set

    fun init(context: Context) {
        appContext = context.applicationContext
        // Self-heal an already-extracted bootstrap on every launch: re-applies
        // hardcoded-path patches and the apt configuration that keyless embedded
        // installs depend on.
        try {
            if (bootstrap.isInstalled()) bootstrap.patchExisting()
        } catch (_: Throwable) {}
    }

    val shell by lazy { sd.adaa.codeide.process.ShellExecutor(appContext) }

    val bootstrap by lazy { BootstrapInstaller(appContext) }

    val runtimes by lazy { RuntimeManager(bootstrap, appContext) }

    val terminal by lazy { TerminalManager(appContext) }

    val processes by lazy { ProcessManager(appContext) }

    val files get() = sd.adaa.codeide.filesystem.FileSystemManager

    val projects by lazy { ProjectManager(appContext) }

    val git by lazy { sd.adaa.codeide.git.GitManager(appContext) }
}