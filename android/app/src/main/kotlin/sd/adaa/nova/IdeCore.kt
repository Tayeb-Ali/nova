package sd.adaa.nova

import android.content.Context
import sd.adaa.nova.process.ProcessManager
import sd.adaa.nova.project.ProjectManager
import sd.adaa.nova.runtime.BootstrapInstaller
import sd.adaa.nova.runtime.RuntimeManager
import sd.adaa.nova.terminal.TerminalManager

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

    val shell by lazy { sd.adaa.nova.process.ShellExecutor(appContext) }

    val bootstrap by lazy { BootstrapInstaller(appContext) }

    val runtimes by lazy { RuntimeManager(bootstrap, appContext) }

    val terminal by lazy { TerminalManager(appContext) }

    val processes by lazy { ProcessManager(appContext) }

    val files get() = sd.adaa.nova.filesystem.FileSystemManager

    val projects by lazy { ProjectManager(appContext) }

    val git by lazy { sd.adaa.nova.git.GitManager(appContext) }
}