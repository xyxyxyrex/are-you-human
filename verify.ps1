$ErrorActionPreference = "Stop"
$GodotVersion = "4.7.2-stable"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsDir = Join-Path $RepoRoot ".tools\godot"

$GodotExe = $null
if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) {
    $GodotExe = $env:GODOT_BIN
} elseif (Test-Path (Join-Path $ToolsDir "Godot_v$GodotVersion`_win64.exe")) {
    $GodotExe = Join-Path $ToolsDir "Godot_v$GodotVersion`_win64.exe"
} elseif (Test-Path (Join-Path $ToolsDir "Godot_v$GodotVersion`_windows_arm64.exe")) {
    $GodotExe = Join-Path $ToolsDir "Godot_v$GodotVersion`_windows_arm64.exe"
} elseif (Get-Command godot -ErrorAction SilentlyContinue) {
    $GodotExe = (Get-Command godot).Source
} elseif (Test-Path (Join-Path $env:USERPROFILE "Downloads\Godot_v$GodotVersion`_win64.exe")) {
    $GodotExe = Join-Path $env:USERPROFILE "Downloads\Godot_v$GodotVersion`_win64.exe"
}

if (-not $GodotExe) {
    Write-Host "Godot $GodotVersion not found yet. Running setup.ps1 -SkipVerify first..."
    & (Join-Path $RepoRoot "setup.ps1") -SkipVerify
    $GodotExe = Join-Path $ToolsDir "Godot_v$GodotVersion`_win64.exe"
}

$py = Get-Command python -ErrorAction SilentlyContinue
if ($py) {
    Write-Host "=== 1. Project Resource & Scene Integrity Check ==="
    & $py.Source (Join-Path $RepoRoot ".agents\skills\godot-nodes-scenes\scripts\check_godot_project.py") $RepoRoot
    if ($LASTEXITCODE -ne 0) { throw "check_godot_project.py failed." }
}

$checks = @(
    @{ name = "2. Strict GDScript Compile Check"; args = @("--headless", "--path", $RepoRoot, "--script", (Join-Path $RepoRoot ".agents\skills\godot-gdscript\assets\check_scripts_compile.gd")) },
    @{ name = "3. Audio Bus Wiring Check"; args = @("--headless", "--path", $RepoRoot, "--script", (Join-Path $RepoRoot ".agents\skills\godot-audio\assets\check_audio_buses.gd")) },
    @{ name = "4. End-to-End Campaign & Layout Test Suite"; args = @("--headless", "--path", $RepoRoot, "--scene", "res://tests/test_runner.tscn") }
)

foreach ($c in $checks) {
    Write-Host "=== $($c.name) ==="
    $logFile = Join-Path $RepoRoot "verify_step.log"
    if (Test-Path $logFile) { Remove-Item $logFile -Force }
    $proc = Start-Process -FilePath $GodotExe -ArgumentList ($c.args + @("--log-file", $logFile)) -Wait -PassThru -NoNewWindow
    if (Test-Path $logFile) {
        Get-Content $logFile
        Remove-Item $logFile -Force
    }
    if ($proc.ExitCode -ne 0) {
        throw "$($c.name) failed with exit code $($proc.ExitCode)"
    }
}

Write-Host "ALL VERIFICATION CHECKS PASSED!"
