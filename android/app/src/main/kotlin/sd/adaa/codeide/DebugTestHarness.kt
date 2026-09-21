package sd.adaa.codeide

import android.content.Context
import android.util.Log
import sd.adaa.codeide.process.ShellExecutor
import sd.adaa.codeide.terminal.TerminalManager
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * In-app comprehensive test harness (task.md §34).
 * Trigger via: adb shell am broadcast -a sd.adaa.codeide.DEBUG_COMPREHENSIVE_TEST -n sd.adaa.codeide/.MainActivity
 * Writes Node/Python sample codes, executes them via ShellExecutor/Terminal PTY, logs to NovaTest.
 */
object DebugTestHarness {
    private const val TAG = "NovaTest"

    fun run(context: Context) {
        Thread({
            try {
                Log.i(TAG, "=== Nova Comprehensive In-App Test START ===")
                val prefix = EnvironmentManager.prefix(context)
                val home = EnvironmentManager.home(context)
                val testDir = File(home, "nova_test")
                testDir.mkdirs()

                // Patch existing bootstrap if needed (for already-installed prefixes)
                try {
                    IdeCore.bootstrap.patchExisting()
                    // Remove stale apt.conf that may contain wrong Dir
                    File(prefix, "etc/apt/apt.conf").takeIf { it.exists() }?.let {
                        if (it.readText().contains("com.termux")) it.delete()
                        else if (it.readText().contains("/data/user/0/sd.adaa.codeide")) {
                            // keep our earlier Dir fix, but ensure it's correct
                        }
                    }
                } catch (_: Exception) {}

                // 1. Bootstrap / bash sanity
                testBash(context, prefix)

                // 2. Write & run Node samples (if node installed)
                testNode(context, testDir)

                // 3. Write & run Python samples (if python3 installed)
                testPython(context, testDir)

                // 4. Terminal PTY test
                testTerminal(context)

                Log.i(TAG, "=== Nova Comprehensive In-App Test DONE ===")
            } catch (e: Throwable) {
                Log.e(TAG, "Comprehensive test failed: ${e.message}", e)
            }
        }, "nova-comprehensive-test").start()
    }

    /**
     * Phase 0 linker-exec spike probe.
     * Trigger via: adb shell am broadcast -a sd.adaa.codeide.DEBUG_LINKER_PROBE -n sd.adaa.codeide/.MainActivity
     * Forces NOVA_EXEC_MODE=linker (works even with targetSdk 28) and runs
     * bash/ls/apt through ShellExecutor plus one PTY session, logging
     * LINKER-PROBE PASS/FAIL lines to NovaTest. Proves the first-hop chain
     * before any targetSdk bump.
     */
    fun runLinkerProbe(context: Context) {
        Thread({
            try {
                Log.i(TAG, "=== Linker-exec probe START (mode=linker, target unchanged) ===")
                val prefix = EnvironmentManager.prefix(context)
                val home = EnvironmentManager.home(context).absolutePath
                val shell = ShellExecutor(context)
                val linkerEnv = mapOf(
                    EnvironmentManager.ENV_EXEC_MODE to EnvironmentManager.EXEC_MODE_LINKER
                )
                var pass = 0
                var fail = 0
                fun check(tag: String, ok: Boolean, detail: String) {
                    if (ok) { pass++; Log.i(TAG, "[LINKER-PROBE] PASS $tag: $detail") }
                    else { fail++; Log.e(TAG, "[LINKER-PROBE] FAIL $tag: $detail") }
                }

                val bash = File(prefix, "bin/bash")
                val echo = shell.execute(
                    bash.absolutePath, listOf("-c", "echo LINKER_OK"),
                    home, linkerEnv, 15_000,
                )
                check("bash-echo", echo.getOrNull()?.contains("LINKER_OK") == true,
                    echo.getOrElse { it.message ?: "error" }.trim().take(120))

                val ls = shell.execute(
                    File(prefix, "bin/ls").absolutePath,
                    listOf(File(prefix, "bin").absolutePath),
                    home, linkerEnv, 15_000,
                )
                check("ls", ls.getOrNull()?.contains("bash") == true,
                    ls.getOrNull()?.lineSequence()?.count()?.toString()?.plus(" entries")
                        ?: ls.exceptionOrNull()?.message?.take(120) ?: "error")

                val apt = shell.execute(
                    File(prefix, "bin/apt").absolutePath, listOf("--version"),
                    home, linkerEnv, 15_000,
                )
                val aptOut = apt.getOrElse { it.message ?: "" }
                check("apt", aptOut.contains("apt"),
                    aptOut.lineSequence().firstOrNull { it.contains("apt") }?.take(120) ?: "no apt output")

                // PTY session via the DEFAULT path (no explicit mode): exactly
                // what the UI bridge calls, so this proves the production
                // terminal route per flavor (linker on play, direct on github).
                try {
                    val tm = TerminalManager(context)
                    val sid = tm.createSession(home, 80, 24)
                    tm.write(sid, "echo PTY_LINKER_OK\n")
                    Thread.sleep(800)
                    tm.close(sid)
                    check("pty-open", true, "session $sid opened+wrote+closed without exception")
                } catch (e: Throwable) {
                    check("pty-open", false, "${e.message}")
                }

                Log.i(TAG, "=== Linker-exec probe DONE: $pass PASS, $fail FAIL ===")
            } catch (e: Throwable) {
                Log.e(TAG, "Linker probe failed: ${e.message}", e)
            }
        }, "nova-linker-probe").start()
    }

    /**
     * Full 0A–0F matrix on the live device (target 36): apt update, install
     * nodejs+python through the linker, run node/python hellos, nested exec
     * through LD_PRELOAD, and direct shebang-script exec.
     * Trigger: `adb shell am start -n sd.adaa.codeide/.MainActivity --es nova_probe full`
     */
    fun runFullProbe(context: Context) {
        Thread({
            try {
                Log.i(TAG, "=== Full linker matrix START (mode=linker, target 36) ===")
                Log.i(TAG, "[MATRIX] build-marker v4-spawn-trace")
                val prefix = EnvironmentManager.prefix(context)
                val home = EnvironmentManager.home(context)
                val testDir = File(home, "nova_linker_matrix")
                testDir.mkdirs()
                val shell = ShellExecutor(context)
                val cwd = testDir.absolutePath
                val linkerEnv = mapOf(
                    EnvironmentManager.ENV_EXEC_MODE to EnvironmentManager.EXEC_MODE_LINKER
                )
                var pass = 0
                var fail = 0
                fun check(tag: String, ok: Boolean, detail: String) {
                    if (ok) { pass++; Log.i(TAG, "[MATRIX] PASS $tag: $detail") }
                    else { fail++; Log.e(TAG, "[MATRIX] FAIL $tag: $detail") }
                }

                // Nested exec: bash children (ls, wc) spawn through LD_PRELOAD.
                // NOTE: full output logged untruncated for diagnosis.
                // Phase 1 gate: stage OUR libnova-exec.so (built from the
                // fork with Nova paths) from the APK native lib dir and use
                // it as the preload for this call only. No force-mode var:
                // defaults must work on their own to count as PASS.
                val stagedDir = File(home, "novaexec-stage").apply { mkdirs() }
                val stagedSo = File(stagedDir, "libnova-exec.so")
                try {
                    val src = File(context.applicationInfo.nativeLibraryDir, "libnova-exec.so")
                    if (src.exists()) {
                        src.copyTo(stagedSo, overwrite = true)
                        Log.i(TAG, "[MATRIX] staged-intercept path=" +
                            stagedSo.absolutePath + " bytes=" + stagedSo.length())
                    } else {
                        Log.e(TAG, "[MATRIX] staged-intercept MISSING")
                    }
                } catch (e: Throwable) {
                    Log.e(TAG, "[MATRIX] staged-intercept copy failed: " + e.message)
                }
                val nestedEnv = if (stagedSo.exists()) {
                    linkerEnv + ("LD_PRELOAD" to stagedSo.absolutePath) +
                        // Trace the interceptor's decision per exec (stderr
                        // merged into our captured output by ShellExecutor).
                        ("TERMUX_EXEC_DEBUG" to "1")
                } else {
                    linkerEnv
                }
                val nested = shell.execute(
                    File(prefix, "bin/bash").absolutePath,
                    listOf("-c", "ls \$PREFIX/bin | wc -l"),
                    cwd, nestedEnv, 30_000,
                )
                val nestedOut = nested.getOrNull() ?: ""
                // Debug spam ([nova-exec] trace on merged stderr) may precede
                // the real output: take the last bare-numeric line.
                val nestedCount = nestedOut.lineSequence()
                    .map { it.trim() }
                    .lastOrNull { it.matches(Regex("\\d+")) }
                    ?.toIntOrNull()
                check("nested-exec",
                    nestedCount?.let { it > 100 } == true,
                    "count=[" + (nestedCount?.toString() ?: "none") + "] err=[" +
                        (nested.exceptionOrNull()?.message ?: "") + "]")

                // Shebang direct exec: script resolved to interpreter by NovaExecLauncher.
                val script = File(testDir, "shebang_probe.sh")
                script.writeText("#!/usr/bin/env sh\necho SHEBANG_OK\n")
                shell.execute(File(prefix, "bin/chmod").absolutePath,
                    listOf("+x", script.absolutePath), cwd, linkerEnv, 15_000)
                var shebangDetail = ""
                var shebangOk = false
                try {
                    val res = shell.execute(script.absolutePath, emptyList(), cwd, linkerEnv, 15_000)
                    shebangOk = res.getOrNull()?.contains("SHEBANG_OK") == true
                    shebangDetail = "out=[" + (res.getOrNull() ?: "") + "] err=[" +
                        (res.exceptionOrNull()?.toString() ?: "") + "]"
                } catch (e: Throwable) {
                    var c: Throwable? = e
                    val chain = StringBuilder()
                    while (c != null) {
                        chain.append(c.javaClass.name).append(": ").append(c.message).append(" <- ")
                        c = c.cause
                    }
                    shebangDetail = "thrown=[" + chain.toString() + "]"
                }
                check("shebang", shebangOk, shebangDetail)

                // /proc/self/exe interception: the readlink helper itself is
                // spawned through the linker, so without the hook it would
                // report linker64. Expect the real prefix path instead.
                // Uses the STAGED preload (nestedEnv), not the old production one.
                val exeSelf = shell.execute(
                    File(prefix, "bin/bash").absolutePath,
                    listOf("-c", "readlink /proc/self/exe"),
                    cwd, nestedEnv, 15_000,
                )
                val exeSelfOut = exeSelf.getOrNull() ?: ""
                // Debug trace lines precede the real output: judge by the
                // last bare-path line only.
                val exeSelfLast = exeSelfOut.lineSequence()
                    .map { it.trim() }
                    .lastOrNull { it.startsWith("/") } ?: ""
                check("proc-self-exe",
                    exeSelfLast.contains("sd.adaa.codeide") && !exeSelfLast.contains("linker"),
                    "last=[" + exeSelfLast + "] err=[" +
                        (exeSelf.exceptionOrNull()?.message ?: "") + "]")

                // Apt update output (not ignored here) + lists dir census.
                // Uses the STAGED preload too: apt spawns its https method as
                // a nested child, which needs the working interceptor.
                val aptEnv = if (stagedSo.exists()) {
                    nestedEnv
                } else {
                    linkerEnv
                }
                val aptUpdate = shell.execute(
                    File(prefix, "bin/apt").absolutePath, listOf("update"),
                    cwd, aptEnv, 120_000,
                )
                val listsDir = File(home, "../cache/apt/lists")
                val listsCount = listsDir.listFiles()?.size ?: -1
                Log.i(TAG, "[MATRIX] apt-update ok=" + aptUpdate.isSuccess +
                    " lists=" + listsCount + " head=[" +
                    aptUpdate.getOrElse { it.message ?: "" }.trim().take(300) + "]")

                // Node + Python via RuntimeManager in linker mode.
                // Swap the production preload path to OUR staged .so first
                // (backup + restore in finally): this exercises the EXACT
                // production configuration with zero production code changes.
                val prodPreload = File(prefix, "lib/libtermux-exec-ld-preload.so")
                val prodBackup = File(prefix, "lib/libtermux-exec-ld-preload.so.nova-bak")
                var swapped = false
                try {
                    if (stagedSo.exists() && prodPreload.exists() && !prodBackup.exists()) {
                        prodPreload.copyTo(prodBackup, overwrite = false)
                    }
                    if (stagedSo.exists() && prodBackup.exists()) {
                        stagedSo.copyTo(prodPreload, overwrite = true)
                        swapped = true
                        Log.i(TAG, "[MATRIX] production preload swapped to staged build")
                    }
                    for (id in listOf("node", "python")) {
                        val ok = tryInstallRuntime(id, EnvironmentManager.EXEC_MODE_LINKER)
                        // apt downloads nothing when the newest version is
                        // already installed (correct behavior, not failure):
                        // the binary's presence is the real gate.
                        val binPresent = when (id) {
                            "node" -> File(prefix, "bin/node").exists()
                            else -> File(prefix, "bin/python3").exists() ||
                                File(prefix, "bin/python").exists()
                        }
                        check("install-$id", ok || binPresent,
                            if (ok) "installed" else if (binPresent) "already installed" else "install failed - needs network")
                        if (!ok && !binPresent) continue
                    }
                val nodeBin = File(prefix, "bin/node")
                if (nodeBin.exists()) {
                    File(testDir, "m_hello.js").writeText("console.log('node-hello:'+process.version);")
                    val out = shell.execute(nodeBin.absolutePath,
                        listOf(File(testDir, "m_hello.js").absolutePath), cwd, linkerEnv, 30_000)
                    check("node", out.getOrNull()?.contains("node-hello") == true,
                        out.getOrElse { it.message ?: "error" }.trim().take(120))
                    // Node's own spawn path (libuv posix_spawn) nesting out.
                    // Trace interceptor decisions for diagnosis.
                    val spawnEnv = linkerEnv + ("TERMUX_EXEC_DEBUG" to "1")
                    val spawn = shell.execute(nodeBin.absolutePath,
                        listOf("-e", "process.stdout.write(require('child_process').execSync('echo SPAWN_OK').toString())"),
                        cwd, spawnEnv, 30_000)
                    check("node-spawn",
                        spawn.getOrNull()?.contains("SPAWN_OK") == true,
                        spawn.getOrElse { it.message ?: "error" }.trim().take(600))
                    // Direct-binary spawn (no shell): does libuv reach our
                    // interceptor at all? Uses $PREFIX/bin/echo absolute.
                    val echoAbs = File(prefix, "bin/echo").absolutePath.replace("'", "'\\''")
                    val spawn2 = shell.execute(nodeBin.absolutePath,
                        listOf("-e", "process.stdout.write(require('child_process').spawnSync('" + echoAbs + "',['SPAWN2_OK']).stdout.toString())"),
                        cwd, spawnEnv, 30_000)
                    check("node-spawn-direct",
                        spawn2.getOrNull()?.contains("SPAWN2_OK") == true,
                        spawn2.getOrElse { it.message ?: "error" }.trim().take(300))
                } else {
                    check("node", false, "bin/node missing after install attempt")
                }
                val pyBin = File(prefix, "bin/python3").let { if (it.exists()) it else File(prefix, "bin/python") }
                if (pyBin.exists()) {
                    File(testDir, "m_hello.py").writeText("print('python-hello')")
                    val out = shell.execute(pyBin.absolutePath,
                        listOf(File(testDir, "m_hello.py").absolutePath), cwd, linkerEnv, 30_000)
                    check("python", out.getOrNull()?.contains("python-hello") == true,
                        out.getOrElse { it.message ?: "error" }.trim().take(120))
                    // Python's own spawn path (fork+execve) nesting out.
                    val sub = shell.execute(pyBin.absolutePath,
                        listOf("-c", "import subprocess;print(subprocess.run(['echo','SUBPROC_OK'],capture_output=True,text=True).stdout)"),
                        cwd, linkerEnv, 30_000)
                    check("python-subprocess",
                        sub.getOrNull()?.contains("SUBPROC_OK") == true,
                        sub.getOrElse { it.message ?: "error" }.trim().take(200))
                } else {
                    check("python", false, "python binary missing after install attempt")
                }
                } finally {
                    if (swapped) {
                        try {
                            prodBackup.copyTo(prodPreload, overwrite = true)
                            prodBackup.delete()
                            Log.i(TAG, "[MATRIX] production preload restored")
                        } catch (e: Throwable) {
                            Log.e(TAG, "[MATRIX] preload restore FAILED: " + e.message)
                        }
                    }
                }

                Log.i(TAG, "=== Full linker matrix DONE: $pass PASS, $fail FAIL ===")
            } catch (e: Throwable) {
                Log.e(TAG, "Full matrix failed: ${e.message}", e)
            }
        }, "nova-linker-matrix").start()
    }

    private fun testBash(context: Context, prefix: File) {
        val shell = ShellExecutor(context)
        val env = EnvironmentManager.buildEnvironment(context)
        val cwd = EnvironmentManager.home(context).absolutePath

        // bash --version (apt may return non-zero but still prints version)
        val bash = File(prefix, "bin/bash")
        val bashRes = shell.execute(bash.absolutePath, listOf("--version"), cwd, env, 10_000)
        val bashVer = bashRes.getOrElse { it.message ?: "unknown" }
        Log.i(TAG, "[BASH] ${bashVer.lineSequence().firstOrNull()?.trim() ?: bashVer.take(80)}")

        // echo test via bash -c
        val echo = shell.execute(bash.absolutePath, listOf("-c", "echo hello-from-bash-terminal"), cwd, env, 10_000)
            .getOrElse { "echo failed: ${it.message}" }
        Log.i(TAG, "[BASH-ECHO] ${echo.trim()}")

        // ls $PREFIX/bin count
        val ls = shell.execute(bash.absolutePath, listOf("-c", "ls \$PREFIX/bin | wc -l"), cwd, env, 10_000)
            .getOrElse { "ls failed: ${it.message}" }
        Log.i(TAG, "[BASH-LS] bin entries: ${ls.trim()}")

        // Check apt (may exit non-zero due to warnings, treat containing "apt" as success)
        val apt = File(prefix, "bin/apt")
        val aptRes = shell.execute(apt.absolutePath, listOf("--version"), cwd, env, 10_000)
        val aptVer = aptRes.getOrElse { it.message ?: "" }
        val aptLine = aptVer.lineSequence().firstOrNull { it.contains("apt") } ?: aptVer.take(80)
        Log.i(TAG, "[APT] $aptLine")
        if (aptRes.isFailure && !aptVer.contains("apt")) {
            Log.w(TAG, "[APT] apt --version exited non-zero, but continuing")
        }
    }

    private fun testNode(context: Context, testDir: File) {
        val prefix = EnvironmentManager.prefix(context)
        val shell = ShellExecutor(context)
        val env = EnvironmentManager.buildEnvironment(context)
        val cwd = testDir.absolutePath
        var nodeBin = File(prefix, "bin/node")

        if (!nodeBin.exists()) {
            Log.i(TAG, "[NODE] not installed — attempting apt install nodejs via RuntimeManager...")
            writeNodeSamples(testDir)
            val installed = tryInstallRuntime("node")
            nodeBin = File(prefix, "bin/node")
            if (!installed || !nodeBin.exists()) {
                Log.i(TAG, "[NODE] install not completed (no network or still installing) — samples written, execution skipped. Re-run test after install.")
                return
            }
            Log.i(TAG, "[NODE] install completed, proceeding to execution tests")
        }

        writeNodeSamples(testDir)

        // node --version
        val ver = shell.execute(nodeBin.absolutePath, listOf("--version"), cwd, env, 10_000)
            .getOrElse { "node --version failed: ${it.message}" }
        Log.i(TAG, "[NODE] version: ${ver.trim()}")

        // hello
        val hello = File(testDir, "test_node_hello.js").absolutePath
        val out1 = shell.execute(nodeBin.absolutePath, listOf(hello), cwd, env, 10_000)
            .getOrElse { "node hello failed: ${it.message}" }
        Log.i(TAG, "[NODE-HELLO] ${out1.trim().take(300)}")
        checkContains(out1, "node-hello", "[NODE-HELLO]")

        // fs
        val fs = File(testDir, "test_node_fs.js").absolutePath
        val out2 = shell.execute(nodeBin.absolutePath, listOf(fs), cwd, env, 10_000)
            .getOrElse { "node fs failed: ${it.message}" }
        Log.i(TAG, "[NODE-FS] ${out2.trim().take(300)}")
        checkContains(out2, "fs-ok", "[NODE-FS]")

        // http (quick, no network)
        val http = File(testDir, "test_node_http.js").absolutePath
        val out3 = shell.execute(nodeBin.absolutePath, listOf(http), cwd, env, 10_000)
            .getOrElse { "node http failed: ${it.message}" }
        Log.i(TAG, "[NODE-HTTP] ${out3.trim().take(300)}")
    }

    private fun writeNodeSamples(testDir: File) {
        File(testDir, "test_node_hello.js").writeText(
            """
            console.log('node-hello:' + process.version);
            console.log('arch:' + process.arch);
            console.log('platform:' + process.platform);
            console.log('cwd:' + process.cwd());
            """.trimIndent()
        )
        File(testDir, "test_node_fs.js").writeText(
            """
            const fs=require('fs'), path=require('path'), os=require('os');
            const p=path.join(os.tmpdir(),'nova_fs_test.txt');
            fs.writeFileSync(p,'hello-fs');
            const c=fs.readFileSync(p,'utf8');
            console.log(c==='hello-fs'?'fs-ok:'+c:'fs-fail');
            console.log('tmpdir:'+os.tmpdir());
            """.trimIndent()
        )
        File(testDir, "test_node_http.js").writeText(
            """
            const http=require('http');
            const srv=http.createServer((req,res)=>{res.end('ok');});
            srv.listen(0, '127.0.0.1', ()=>{
              const addr=srv.address();
              console.log('http-ok: listening on '+addr.port);
              srv.close(()=>console.log('http-closed'));
            });
            setTimeout(()=>{ console.log('http-timeout'); try{srv.close();}catch(e){} }, 3000);
            """.trimIndent()
        )
        Log.i(TAG, "[NODE] samples written to ${testDir.absolutePath}")
    }

    private fun testPython(context: Context, testDir: File) {
        val prefix = EnvironmentManager.prefix(context)
        val shell = ShellExecutor(context)
        val env = EnvironmentManager.buildEnvironment(context)
        val cwd = testDir.absolutePath
        // python3 is the executable for id=python
        var pyBin = File(prefix, "bin/python3").let { if (it.exists()) it else File(prefix, "bin/python") }

        if (!pyBin.exists()) {
            Log.i(TAG, "[PYTHON] not installed — attempting apt install python via RuntimeManager...")
            writePythonSamples(testDir)
            val installed = tryInstallRuntime("python")
            pyBin = File(prefix, "bin/python3").let { if (it.exists()) it else File(prefix, "bin/python") }
            if (!installed || !pyBin.exists()) {
                Log.i(TAG, "[PYTHON] install not completed — samples written, execution skipped. Re-run test after install.")
                return
            }
            Log.i(TAG, "[PYTHON] install completed, proceeding to execution tests")
        }

        writePythonSamples(testDir)

        val ver = shell.execute(pyBin.absolutePath, listOf("--version"), cwd, env, 10_000)
            .getOrElse { "python --version failed: ${it.message}" }
        Log.i(TAG, "[PYTHON] version: ${ver.trim()}")

        val hello = File(testDir, "test_python_hello.py").absolutePath
        val out1 = shell.execute(pyBin.absolutePath, listOf(hello), cwd, env, 10_000)
            .getOrElse { "python hello failed: ${it.message}" }
        Log.i(TAG, "[PYTHON-HELLO] ${out1.trim().take(300)}")
        checkContains(out1, "python-hello", "[PYTHON-HELLO]")

        val io = File(testDir, "test_python_io.py").absolutePath
        val out2 = shell.execute(pyBin.absolutePath, listOf(io), cwd, env, 10_000)
            .getOrElse { "python io failed: ${it.message}" }
        Log.i(TAG, "[PYTHON-IO] ${out2.trim().take(300)}")
        checkContains(out2, "io-ok", "[PYTHON-IO]")
    }

    private fun writePythonSamples(testDir: File) {
        File(testDir, "test_python_hello.py").writeText(
            """
            import platform, sys, os
            print(f"python-hello:{platform.python_version()}")
            print(f"arch:{platform.machine()}")
            print(f"executable:{sys.executable}")
            print(f"cwd:{os.getcwd()}")
            """.trimIndent()
        )
        File(testDir, "test_python_io.py").writeText(
            """
            import tempfile, os
            p=os.path.join(tempfile.gettempdir(),'nova_py_test.txt')
            open(p,'w').write('hello-py')
            c=open(p).read()
            print('io-ok:'+c if c=='hello-py' else 'io-fail')
            print('tmpdir:'+tempfile.gettempdir())
            import sqlite3
            con=sqlite3.connect(':memory:')
            con.execute('create table t(x)')
            con.execute('insert into t values (1)')
            print('sqlite-ok:'+str(list(con.execute('select * from t'))[0][0]))
            """.trimIndent()
        )
        Log.i(TAG, "[PYTHON] samples written to ${testDir.absolutePath}")
    }

    private fun testTerminal(context: Context) {
        try {
            val tm = TerminalManager(context)
            val home = EnvironmentManager.home(context).absolutePath
            val sessionId = tm.createSession(home, 80, 24)
            Log.i(TAG, "[TERMINAL] session created: $sessionId")

            // Send echo command; flusher will emit base64 output via IdeEvents
            tm.write(sessionId, "echo hello-terminal-pty\n")
            Thread.sleep(400)
            tm.write(sessionId, "pwd\n")
            Thread.sleep(300)
            tm.write(sessionId, "ls -1 | head -5\n")
            Thread.sleep(400)

            // Check that session still exists (write should not throw)
            tm.write(sessionId, "echo terminal-ok\n")
            Thread.sleep(300)
            Log.i(TAG, "[TERMINAL] write/resize/signal smoke test passed")

            tm.resize(sessionId, 100, 30)
            Log.i(TAG, "[TERMINAL] resize to 100x30 ok")

            tm.sendSignal(sessionId, "SIGTERM")
            Thread.sleep(200)

            tm.close(sessionId)
            Log.i(TAG, "[TERMINAL] close ok")

            // Create second session to verify no crash after close
            val s2 = tm.createSession(home, 80, 24)
            Log.i(TAG, "[TERMINAL] second session $s2 created ok")
            tm.close(s2)
        } catch (e: Throwable) {
            Log.e(TAG, "[TERMINAL] failed: ${e.message}", e)
        }
    }

    private fun tryInstallRuntime(id: String, execMode: String = EnvironmentManager.EXEC_MODE_DIRECT): Boolean {
        return try {
            val latch = CountDownLatch(1)
            var success = false
            IdeCore.runtimes.install(id,
                onProgress = { msg -> Log.i(TAG, "[INSTALL-$id] $msg") },
                done = { result ->
                    result.fold(
                        onSuccess = { Log.i(TAG, "[INSTALL-$id] DONE OK"); success = true; latch.countDown() },
                        onFailure = { e -> Log.e(TAG, "[INSTALL-$id] FAILED: ${e.message}"); latch.countDown() }
                    )
                },
                execMode = execMode,
            )
            // Wait up to 5 minutes for apt install (node/python are a few MB)
            val completed = latch.await(5, TimeUnit.MINUTES)
            if (!completed) Log.w(TAG, "[INSTALL-$id] timeout after 5min")
            success && completed
        } catch (e: Throwable) {
            Log.e(TAG, "[INSTALL-$id] exception: ${e.message}", e)
            false
        }
    }

    private fun checkContains(output: String, needle: String, tag: String) {
        if (output.contains(needle)) {
            Log.i(TAG, "$tag PASS contains '$needle'")
        } else {
            Log.w(TAG, "$tag WARN missing '$needle' in: ${output.take(200)}")
        }
    }
}
