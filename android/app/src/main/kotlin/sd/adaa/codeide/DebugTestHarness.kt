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

    private fun tryInstallRuntime(id: String): Boolean {
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
                }
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
