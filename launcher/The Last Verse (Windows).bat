@echo off
rem The Last Verse - Launcher fuer Spieltester (Windows)
rem Laedt Godot und das Spiel aus GitHub, aktualisiert bei jedem Start und startet das Spiel.
title The Last Verse
powershell -NoProfile -ExecutionPolicy Bypass -Command "$code = (Get-Content -LiteralPath '%~f0' -Raw -Encoding UTF8) -split ('#'+'POWERSHELL'+'#'); Invoke-Expression $code[1]"
if errorlevel 1 pause
exit /b
#POWERSHELL#
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = 'mrkderchef/thelastverse'
$Branch = 'main'
$GodotVersion = '4.7.2-stable'
$Dir = Join-Path $env:LOCALAPPDATA 'TheLastVerseLauncher'
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
Set-Location -LiteralPath $Dir

Write-Host ''
Write-Host '  THE LAST VERSE  -  Shakespeare and London Times'
Write-Host '  ------------------------------------------------'
Write-Host ''

function Fail($message) {
	Write-Host ''
	Write-Host "  !! $message" -ForegroundColor Red
	Write-Host ''
	Read-Host '  Enter druecken zum Schliessen'
	exit 1
}

# 1. Die Godot-Laufzeit (einmalig, ca. 70 MB).
$Godot = Join-Path $Dir "Godot_v$($GodotVersion)_win64.exe"
if (-not (Test-Path -LiteralPath $Godot)) {
	Write-Host '  Lade die Spiel-Engine (einmalig) ...'
	try {
		Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/godotengine/godot-builds/releases/download/$GodotVersion/Godot_v$($GodotVersion)_win64.exe.zip" -OutFile 'godot.zip'
		Expand-Archive -LiteralPath 'godot.zip' -DestinationPath $Dir -Force
		Remove-Item 'godot.zip'
	} catch { Fail 'Download der Engine fehlgeschlagen. Internetverbindung pruefen.' }
	if (-not (Test-Path -LiteralPath $Godot)) { Fail 'Die Engine konnte nicht entpackt werden.' }
}

# 2. Die neueste Spielversion aus dem Repository.
$Latest = ''
try { $Latest = (Invoke-RestMethod -UseBasicParsing -Uri "https://api.github.com/repos/$Repo/commits/$Branch").sha } catch { }
$Current = ''
if (Test-Path 'version.txt') { $Current = (Get-Content 'version.txt' -Raw).Trim() }
$Game = Join-Path $Dir 'game'
$Import = $false
if ($Latest -and $Latest -ne $Current) {
	if (Test-Path $Game) { Write-Host '  Neue Version gefunden - wird geladen ...' } else { Write-Host '  Lade das Spiel ...' }
	try {
		Invoke-WebRequest -UseBasicParsing -Uri "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" -OutFile 'game.zip'
		if (Test-Path 'unpacked') { Remove-Item 'unpacked' -Recurse -Force }
		Expand-Archive -LiteralPath 'game.zip' -DestinationPath 'unpacked' -Force
		Remove-Item 'game.zip'
	} catch { Fail 'Download des Spiels fehlgeschlagen.' }
	$New = Get-ChildItem 'unpacked' -Directory | Select-Object -First 1
	if (-not (Test-Path (Join-Path $New.FullName 'project.godot'))) { Fail 'Das heruntergeladene Spiel ist unvollstaendig.' }
	# Der Import-Cache bleibt erhalten, damit Updates schnell gehen.
	$Cache = Join-Path $Game '.godot'
	if (Test-Path $Cache) { Move-Item $Cache (Join-Path $New.FullName '.godot') }
	if (Test-Path $Game) { Remove-Item $Game -Recurse -Force }
	Move-Item $New.FullName $Game
	Remove-Item 'unpacked' -Recurse -Force
	Set-Content 'version.txt' $Latest
	$Import = $true
} elseif (-not $Latest) {
	Write-Host '  (Keine Verbindung zu GitHub - starte die zuletzt geladene Version.)'
}
if (-not (Test-Path (Join-Path $Game 'project.godot'))) { Fail 'Das Spiel ist noch nicht geladen. Beim ersten Start wird Internet benoetigt.' }

# 3. Vorbereiten (nach jedem Update) und starten.
if ($Import -or -not (Test-Path (Join-Path $Game '.godot\imported'))) {
	Write-Host '  Bereite das Spiel vor ... (beim ersten Mal 1-3 Minuten)'
	Start-Process -FilePath $Godot -ArgumentList @('--headless', '--path', "`"$Game`"", '--import') -Wait -WindowStyle Hidden
}
Write-Host '  Viel Spass! Das Fenster oeffnet sich gleich.'
Start-Process -FilePath $Godot -ArgumentList @('--path', "`"$Game`"")
Start-Sleep -Seconds 2
