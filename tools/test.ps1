<#
.SYNOPSIS
    Builds and runs the unit tests, then prints the report.

.DESCRIPTION
    Tests are a separate bundle: test.settings swaps the bootstrap collection for the deftest
    runner. A Windows bundle writes nothing to stdout, so the settings turn on a log file and
    this script reads the report out of it.

    Downloads bob.jar on first use. Finds a Java 25 runtime, preferring the one bundled with the
    Defold editor, since bob refuses anything older.

.PARAMETER Java
    Path to java.exe. Overrides discovery. Also read from the PLINKO_JAVA environment variable.

.PARAMETER Quiet
    Print only the summary line.
#>
param(
    [string] $Java = $env:PLINKO_JAVA,
    [switch] $Quiet
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$bob = Join-Path $root "plans\tools\bob.jar"
$bundle = Join-Path $root "dist\tests"
$engineVersion = "1.13.1"

function Find-Java {
    if ($Java -and (Test-Path $Java)) { return $Java }

    # The editor ships the JDK bob needs, so look there before anything else.
    $candidates = @()
    foreach ($base in @("$env:LOCALAPPDATA\Defold", "$env:ProgramFiles\Defold", "E:\dev\Defold", "D:\Defold", "C:\Defold")) {
        if (Test-Path $base) {
            $candidates += Get-ChildItem -Path $base -Filter "java.exe" -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match "jdk-2[5-9]" } |
                Select-Object -ExpandProperty FullName
        }
    }
    if ($candidates.Count -gt 0) { return $candidates[0] }

    $inPath = (Get-Command java -ErrorAction SilentlyContinue).Source
    if ($inPath) {
        $version = & $inPath -version 2>&1 | Select-Object -First 1
        if ($version -match '"(\d+)') {
            if ([int]$Matches[1] -ge 25) { return $inPath }
        }
    }

    throw "No Java 25+ found. bob.jar needs it. Point PLINKO_JAVA at the java.exe inside your Defold install, e.g. <Defold>\packages\jdk-25+36\bin\java.exe"
}

function Get-Bob {
    if (Test-Path $bob) { return }

    Write-Host "bob.jar not found, downloading $engineVersion from the official release..."
    New-Item -ItemType Directory -Force -Path (Split-Path $bob) | Out-Null
    $url = "https://github.com/defold/defold/releases/download/$engineVersion/bob.jar"
    Invoke-WebRequest -Uri $url -OutFile $bob
}

Get-Bob
$javaExe = Find-Java
Set-Location $root

if (-not $Quiet) { Write-Host "Building test bundle..." }

# bob writes warnings to stderr, which PowerShell turns into a terminating error while
# ErrorActionPreference is Stop. Only the SEVERE lines actually mean failure.
$ErrorActionPreference = "Continue"
$build = & $javaExe -jar $bob --archive --platform x86_64-win32 --settings test.settings --bundle-output $bundle build bundle 2>&1
$ErrorActionPreference = "Stop"
$buildErrors = $build | Where-Object { $_ -match '^\d{4}-\d{2}-\d{2}.*SEVERE' }
if ($buildErrors) {
    Write-Host "BUILD FAILED" -ForegroundColor Red
    $buildErrors | Select-Object -First 10 | ForEach-Object { Write-Host $_ }
    exit 1
}

$exe = Join-Path $bundle "Plinko Tests\PlinkoTests.exe"
$log = Join-Path $bundle "Plinko Tests\log.txt"
Remove-Item $log -ErrorAction SilentlyContinue

if (-not $Quiet) { Write-Host "Running tests..." }

# The working directory matters: test.settings writes the log to "." , which is the process's
# working directory, not the folder holding the executable.
$process = Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -PassThru -WindowStyle Minimized
$process | Wait-Process -Timeout 120 -ErrorAction SilentlyContinue
if (-not $process.HasExited) {
    $process.Kill()
    Write-Host "TESTS TIMED OUT after 120s" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $log)) {
    Write-Host "No log written. The runner never reached deftest.run()." -ForegroundColor Red
    exit 1
}

$lines = Get-Content $log

if (-not $Quiet) {
    # Everything deftest printed: the per-test lines and the failure report.
    $lines |
        Where-Object { $_ -match '\[TEST\]|\[F\]|--- ' } |
        ForEach-Object { $_ -replace '^DEBUG:SCRIPT: ', '' } |
        ForEach-Object { Write-Host $_ }
}

# deftest ends with a line like: 69 tests 69 passed 11122 assertions 0 failed 0 errors ...
$summary = $lines | Select-String "(\d+) tests (\d+) passed (\d+) assertions (\d+) failed (\d+) errors" |
    Select-Object -First 1

if (-not $summary) {
    Write-Host "TESTS DID NOT REPORT — the run ended without a summary." -ForegroundColor Red
    exit 1
}

$counts = $summary.Matches[0].Groups
$total = [int]$counts[1].Value
$passed = [int]$counts[2].Value
$assertions = [int]$counts[3].Value
$failed = [int]$counts[4].Value
$errors = [int]$counts[5].Value

Write-Host ""
if ($failed -eq 0 -and $errors -eq 0 -and $passed -eq $total) {
    Write-Host "ALL TESTS PASSED — $passed of $total, $assertions assertions" -ForegroundColor Green
    exit 0
}

Write-Host "TESTS FAILED — $failed failed, $errors errors, $passed of $total passed" -ForegroundColor Red

# The failure report names what broke; without it the caller has to open the log.
$lines |
    Where-Object { $_ -match '\[F\]|Error|assertion' } |
    ForEach-Object { $_ -replace '^DEBUG:SCRIPT: ', '' } |
    Select-Object -First 20 |
    ForEach-Object { Write-Host "  $_" }

exit 1
