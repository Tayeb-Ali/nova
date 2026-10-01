# On-device mini-app tests for every Nova language (arm-test.md section 6).
# Usage: .\tools\lang-tests\run_lang_tests.ps1 [-Serial <serial>] [-Only php,node,...]
# Single attached device is used when -Serial is omitted.
param(
  [string]$Serial = "",
  [string]$Only = ""
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
# Comma-separated filter (e.g. -Only "php,node"); empty = run everything.
$wanted = @($Only -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

function Invoke-Adb {
  param([string[]]$AdbArgs)
  if ($Serial -ne "") { adb.exe -s $Serial @AdbArgs } else { adb.exe @AdbArgs }
}

function Run-Remote($scriptBody, $label) {
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "nova_lang_$label.sh"
  $scriptBody | Out-File -FilePath $tmp -Encoding ascii -NoNewline
  Invoke-Adb @("push", $tmp, "/data/local/tmp/nova_lang_$label.sh") | Out-Null
  $out = Invoke-Adb @("shell", "run-as sd.adaa.codeide sh /data/local/tmp/nova_lang_$label.sh")
  return $out
}

$prefix = 'cd files; export PATH=$PWD/usr/bin:$PATH; export LD_LIBRARY_PATH=$PWD/usr/lib; export PREFIX=$PWD/usr; export HOME=$PWD/home; mkdir -p home/langtests; cd home/langtests'

$tests = @(
  @{ id = "php";      marker = "PHP-OK";    body = "$prefix; php `$Here/test.php" },
  @{ id = "node";     marker = "NODE-OK";   body = "$prefix; node `$Here/test.js" },
  @{ id = "python";   marker = "PY-OK";     body = "$prefix; python3 `$Here/test.py" },
  @{ id = "ruby";     marker = "RUBY-OK";   body = "$prefix; ruby `$Here/test.rb" },
  @{ id = "git";      marker = "GIT-OK";    body = "$prefix; rm -rf t; git init -q t; cd t; echo x > f; git add .; git -c user.email=t@t -c user.name=t commit -qm.; git log --oneline | head -1; echo GIT-OK" },
  @{ id = "composer"; marker = "Composer version"; body = "$prefix; composer --version" },
  @{ id = "openssh";  marker = "OpenSSH_";  body = "$prefix; ssh -V 2>&1; echo SSH-DONE" },
  @{ id = "java";     marker = "JAVA-OK";   body = "$prefix; javac `$Here/HelloWorld.java -d . && java -cp . HelloWorld" },
  @{ id = "kotlin";   marker = "KOTLIN-OK"; body = "$prefix; kotlinc `$Here/hello.kt -d hello.jar && java -jar hello.jar" },
  @{ id = "go";       marker = "GO-OK";     body = "$prefix; go build -o hello_go `$Here/main.go && ./hello_go" },
  @{ id = "rust";     marker = "RUST-OK";   body = "$prefix; rustc -O `$Here/main.rs -o hello_rs && ./hello_rs" },
  @{ id = "dart";     marker = "DART-OK";   body = "$prefix; dart run `$Here/main.dart" },
  @{ id = "c";        marker = "C-OK";      body = "$prefix; cc `$Here/hello.c -o hello_c && ./hello_c" }
)

# Push sources once (into a directory run-as can read).
Invoke-Adb @("shell", "mkdir -p /data/local/tmp/nova_src") | Out-Null
foreach ($f in @("test.php", "test.js", "test.py", "test.rb", "HelloWorld.java", "hello.kt", "main.go", "main.rs", "main.dart", "hello.c")) {
  Invoke-Adb @("push", (Join-Path $Here $f), "/data/local/tmp/nova_src/$f") | Out-Null
}
$HereRemote = "/data/local/tmp/nova_src"

$failed = @()
foreach ($t in $tests) {
  if ($wanted.Count -gt 0 -and -not ($wanted -contains $t.id)) { continue }
  $body = $t.body -replace '\$Here', $HereRemote
  $out = Run-Remote $body $t.id
  if ($out -match [regex]::Escape($t.marker)) {
    Write-Output "PASS $($t.id): $($t.marker)"
  } else {
    Write-Output "FAIL $($t.id): marker '$($t.marker)' not found"
    Write-Output $out
    $failed += $t.id
  }
}

if ($failed.Count -gt 0) { Write-Output "FAILED: $($failed -join ',')"; exit 1 }
Write-Output "ALL LANG TESTS PASSED"
