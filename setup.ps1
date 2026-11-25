param(
    [switch]$SkipVerify
)

$ErrorActionPreference = "Stop"
$GodotVersion = "4.7.2-stable"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsDir = Join-Path $RepoRoot ".tools\godot"

function Resolve-GodotExe {
    if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) { return $env:GODOT_BIN }
    $localWin64 = Join-Path $ToolsDir "Godot_v$GodotVersion`_win64.exe"
    $localArm64 = Join-Path $ToolsDir "Godot_v$GodotVersion`_windows_arm64.exe"
    if (Test-Path $localWin64) { return $localWin64 }
    if (Test-Path $localArm64) { return $localArm64 }
    $onPath = Get-Command godot -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    $dlFallback = Join-Path $env:USERPROFILE "Downloads\Godot_v$GodotVersion`_win64.exe"
    if (Test-Path $dlFallback) { return $dlFallback }
    return $null
}

$GodotExe = Resolve-GodotExe
if (-not $GodotExe) {
    New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
    $isArm = ($env:PROCESSOR_ARCHITECTURE -eq "ARM64")
    $assetName = if ($isArm) { "Godot_v$GodotVersion`_windows_arm64.exe.zip" } else { "Godot_v$GodotVersion`_win64.exe.zip" }
    $url = "https://github.com/godotengine/godot/releases/download/$GodotVersion/$assetName"
    $zipPath = Join-Path $ToolsDir $assetName

    Write-Host "Downloading Godot $GodotVersion from $url ..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Write-Host "Extracting Godot $GodotVersion to $ToolsDir ..."
    Expand-Archive -Path $zipPath -DestinationPath $ToolsDir -Force
    Remove-Item $zipPath -Force
    $GodotExe = Resolve-GodotExe
}

if (-not $GodotExe -or -not (Test-Path $GodotExe)) {
    throw "Failed to locate or install Godot $GodotVersion."
}

Write-Host "Using Godot binary: $GodotExe"
Write-Host "Importing project assets & building class cache..."
$importLog = Join-Path $RepoRoot "import_setup.log"
$p = Start-Process -FilePath $GodotExe -ArgumentList @("--headless", "--path", $RepoRoot, "--import", "--log-file", $importLog) -Wait -PassThru -NoNewWindow
if (Test-Path $importLog) { Remove-Item $importLog -Force }
if ($p.ExitCode -ne 0) {
    throw "Godot --import exited with code $($p.ExitCode)"
}

if (-not $SkipVerify) {
    & (Join-Path $RepoRoot "verify.ps1")
}

Write-Host ""
Write-Host "Setup complete! Launch the game with .\run_game.bat or open the editor with .\open_editor.bat"
