# tools/audit_prefix.ps1
# Dependency-free PowerShell 5.1 audit for the linker-exec gate.
# Uses only .NET System.IO.Compression (no python, no binutils).
# Scans android/app/src/main/assets/bootstrap-aarch64.zip and bootstrap-x86_64.zip and reports:
#  (1) ELF count (magic 7F 45 4C 46) + STATIC subset (no PT_INTERP type==3 in program headers)
#  (2) files starting with #! with interpreter first-lines (top 30 per zip)
#  (3) whether lib/libtermux-exec-ld-preload.so exists per zip.
#
# ELF parsing notes (pure PowerShell/.NET):
#  EI_CLASS at offset 4 (1=32-bit, 2=64-bit), EI_DATA at offset 5 (1=LE, 2=BE).
#  32-bit: e_phoff @28 u32, e_phentsize @42 u16, e_phnum @44 u16. ph entry 32 bytes, p_type @0 u32.
#  64-bit: e_phoff @32 u64, e_phentsize @54 u16, e_phnum @56 u16. ph entry 56 bytes, p_type @0 u32.
#  PT_INTERP == 3. Absence of PT_INTERP => STATIC (linker64 cannot load these -> blockers).

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$RepoRoot = Split-Path $PSScriptRoot -Parent
$AssetsDir = Join-Path $RepoRoot "android\app\src\main\assets"
$ZipNames = @("bootstrap-aarch64.zip", "bootstrap-x86_64.zip")
$PreloadPath = "lib/libtermux-exec-ld-preload.so"

function Get-U16([byte[]]$b, [int]$off, [bool]$isLE) {
    if (($off + 2) -gt $b.Length) { throw "Get-U16 out of range" }
    if ($isLE) {
        return [System.BitConverter]::ToUInt16($b, $off)
    } else {
        $tmp = New-Object byte[] 2
        $tmp[0] = $b[$off + 1]
        $tmp[1] = $b[$off]
        return [System.BitConverter]::ToUInt16($tmp, 0)
    }
}

function Get-U32([byte[]]$b, [int]$off, [bool]$isLE) {
    if (($off + 4) -gt $b.Length) { throw "Get-U32 out of range" }
    if ($isLE) {
        return [System.BitConverter]::ToUInt32($b, $off)
    } else {
        $tmp = New-Object byte[] 4
        $tmp[0] = $b[$off + 3]
        $tmp[1] = $b[$off + 2]
        $tmp[2] = $b[$off + 1]
        $tmp[3] = $b[$off]
        return [System.BitConverter]::ToUInt32($tmp, 0)
    }
}

function Get-U64([byte[]]$b, [int]$off, [bool]$isLE) {
    if (($off + 8) -gt $b.Length) { throw "Get-U64 out of range" }
    if ($isLE) {
        return [System.BitConverter]::ToUInt64($b, $off)
    } else {
        $tmp = New-Object byte[] 8
        for ($i = 0; $i -lt 8; $i++) {
            $tmp[$i] = $b[$off + 7 - $i]
        }
        return [System.BitConverter]::ToUInt64($tmp, 0)
    }
}

function Read-EntryBytes([System.IO.Compression.ZipArchiveEntry]$entry) {
    $s = $entry.Open()
    try {
        $ms = New-Object System.IO.MemoryStream
        try {
            $buf = New-Object byte[] 8192
            while ($true) {
                $n = $s.Read($buf, 0, $buf.Length)
                if ($n -le 0) { break }
                $ms.Write($buf, 0, $n)
            }
            return $ms.ToArray()
        } finally {
            $ms.Dispose()
        }
    } finally {
        $s.Dispose()
    }
}

function Test-ElfStatic([byte[]]$bytes) {
    # Returns "DYNAMIC", "STATIC", or "UNKNOWN:<reason>".
    # Caller must have verified ELF magic already.
    if ($bytes.Length -lt 6) { return "UNKNOWN:truncated-eident" }
    $class = $bytes[4]
    $data = $bytes[5]
    $isLE = $true
    if ($data -eq 2) { $isLE = $false }
    elseif ($data -eq 1) { $isLE = $true }
    else { $isLE = $true }

    [uint64]$e_phoff = 0
    [uint16]$e_phentsize = 0
    [uint16]$e_phnum = 0

    if ($class -eq 1) {
        # 32-bit
        if ($bytes.Length -lt 48) { return "UNKNOWN:truncated-ehdr32" }
        $e_phoff = Get-U32 $bytes 28 $isLE
        $e_phentsize = Get-U16 $bytes 42 $isLE
        $e_phnum = Get-U16 $bytes 44 $isLE
    } elseif ($class -eq 2) {
        # 64-bit
        if ($bytes.Length -lt 60) { return "UNKNOWN:truncated-ehdr64" }
        $e_phoff = Get-U64 $bytes 32 $isLE
        $e_phentsize = Get-U16 $bytes 54 $isLE
        $e_phnum = Get-U16 $bytes 56 $isLE
    } else {
        return ("UNKNOWN:bad-class-" + $class)
    }

    if ($e_phnum -eq 0) {
        return "STATIC:no-phnum"
    }
    if ($e_phnum -eq 0xFFFF) {
        return "UNKNOWN:pn-xnum-extended"
    }
    if ($e_phentsize -lt 8) {
        return ("UNKNOWN:bad-phentsize-" + $e_phentsize)
    }

    for ($i = 0; $i -lt $e_phnum; $i++) {
        [uint64]$phOff = $e_phoff + ([uint64]$i * [uint64]$e_phentsize)
        if ($phOff -gt [uint64][int]::MaxValue) {
            return "UNKNOWN:phoff-huge"
        }
        [int]$o = [int]$phOff
        if (($o + 4) -gt $bytes.Length) {
            return "UNKNOWN:truncated-phdr"
        }
        [uint32]$p_type = Get-U32 $bytes $o $isLE
        if ($p_type -eq 3) {
            return "DYNAMIC"
        }
    }
    return "STATIC"
}

function Get-ShebangLine([byte[]]$bytes) {
    # Assumes bytes[0]==0x23 and bytes[1]==0x21. Returns first line string.
    [int]$max = $bytes.Length
    if ($max -gt 512) { $max = 512 }
    [int]$nl = $max
    for ([int]$k = 0; $k -lt $max; $k++) {
        if ($bytes[$k] -eq 10) { $nl = $k; break }
    }
    if ($nl -eq 0) { return "" }
    $line = [System.Text.Encoding]::UTF8.GetString($bytes, 0, $nl)
    $line = $line.TrimEnd("`r", "`n")
    return $line
}

$grandTotalEntries = 0
$grandElf = 0
$grandStatic = 0

foreach ($zipName in $ZipNames) {
    $zipPath = Join-Path $AssetsDir $zipName
    Write-Host ("=" * 78)
    Write-Host ("ZIP: " + $zipName)
    Write-Host ("PATH: " + $zipPath)
    if (-not (Test-Path -LiteralPath $zipPath)) {
        Write-Host "MISSING ZIP FILE - skipping"
        continue
    }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $totalEntries = 0
        $elfCount = 0
        $dynamicCount = 0
        $staticCount = 0
        $unknownCount = 0
        $staticList = New-Object System.Collections.ArrayList
        $unknownList = New-Object System.Collections.ArrayList
        $shebangList = New-Object System.Collections.ArrayList
        $shebangCount = 0
        $preloadFound = $false
        $execMatches = New-Object System.Collections.ArrayList

        foreach ($entry in $zip.Entries) {
            $full = $entry.FullName
            # Skip directory entries
            if ($full.EndsWith("/")) { continue }
            if (($entry.Name -eq "") -and ($entry.Length -eq 0)) { continue }
            $totalEntries++

            if ($full -eq $PreloadPath) { $preloadFound = $true }
            if ($full.ToLower().Contains("termux-exec")) {
                [void]$execMatches.Add($full)
            }

            # Read bytes once per file entry
            [byte[]]$bytes = $null
            try {
                $bytes = Read-EntryBytes $entry
            } catch {
                [void]$unknownList.Add($full + " || READ-ERROR: " + $_.Exception.Message)
                $unknownCount++
                continue
            }

            if ($bytes.Length -lt 4) { continue }

            $isElf = ($bytes[0] -eq 0x7F -and $bytes[1] -eq 0x45 -and $bytes[2] -eq 0x4C -and $bytes[3] -eq 0x46)
            if ($isElf) {
                $elfCount++
                $verdict = Test-ElfStatic $bytes
                if ($verdict -eq "DYNAMIC") {
                    $dynamicCount++
                } elseif ($verdict.StartsWith("STATIC")) {
                    $staticCount++
                    [void]$staticList.Add($full + " || " + $verdict)
                } else {
                    $unknownCount++
                    [void]$unknownList.Add($full + " || " + $verdict)
                }
                continue
            }

            # Shebang check (only for non-ELF; ELF never starts with #!)
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0x23 -and $bytes[1] -eq 0x21) {
                $shebangCount++
                $line = Get-ShebangLine $bytes
                # Truncate very long lines for report readability
                if ($line.Length -gt 200) { $line = $line.Substring(0, 200) }
                [void]$shebangList.Add($full + " || " + $line)
            }
        }

        $grandTotalEntries += $totalEntries
        $grandElf += $elfCount
        $grandStatic += $staticCount

        Write-Host ("  total file entries : " + $totalEntries)
        Write-Host ("  ELF files (7f 45 4c 46) : " + $elfCount)
        Write-Host ("    DYNAMIC (has PT_INTERP=3) : " + $dynamicCount)
        Write-Host ("    STATIC  (no PT_INTERP, BLOCKER for linker64) : " + $staticCount)
        Write-Host ("    UNKNOWN (parse failure) : " + $unknownCount)
        Write-Host ""
        Write-Host "  STATIC ELF list (critical - linker64 cannot load these):"
        if ($staticList.Count -eq 0) {
            Write-Host "    (none)"
        } else {
            $sorted = $staticList | Sort-Object
            foreach ($s in $sorted) { Write-Host ("    STATIC: " + $s) }
        }
        Write-Host ""
        if ($unknownList.Count -gt 0) {
            Write-Host "  UNKNOWN ELF list (needs manual inspection):"
            $sortedU = $unknownList | Sort-Object
            foreach ($s in $sortedU) { Write-Host ("    UNKNOWN: " + $s) }
            Write-Host ""
        }
        Write-Host ("  Shebang (#!) files : " + $shebangCount + " (showing top 30 sorted)")
        if ($shebangList.Count -eq 0) {
            Write-Host "    (none)"
        } else {
            $sortedSh = $shebangList | Sort-Object | Select-Object -First 30
            foreach ($s in $sortedSh) { Write-Host ("    SHEBANG: " + $s) }
        }
        Write-Host ""
        Write-Host ("  preload " + $PreloadPath + " exists : " + $preloadFound)
        if ($execMatches.Count -gt 0) {
            Write-Host "  *termux-exec* matches in zip:"
            $sortedE = $execMatches | Sort-Object
            foreach ($s in $sortedE) { Write-Host ("    EXEC-MATCH: " + $s) }
        } else {
            Write-Host "  *termux-exec* matches in zip: (none)"
        }
        Write-Host ""
    } finally {
        $zip.Dispose()
    }
}

Write-Host ("=" * 78)
Write-Host ("GRAND TOTAL file entries : " + $grandTotalEntries)
Write-Host ("GRAND TOTAL ELF          : " + $grandElf)
Write-Host ("GRAND TOTAL STATIC (blockers) : " + $grandStatic)
