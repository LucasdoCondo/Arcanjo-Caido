# ============================================================================
# [ARCANJO CAIDO] - build_instalador.ps1
# ----------------------------------------------------------------------------
# Exporta o preset "Windows Instalador" (Lucifer.exe + Lucifer.pck separados)
# e, se o Inno Setup 6 estiver instalado, compila o instalador final usando
# o script setup_lucifer.iss.
#
# USO:
#   powershell -ExecutionPolicy Bypass -File build_instalador.ps1
#   powershell -ExecutionPolicy Bypass -File build_instalador.ps1 -GodotPath "C:\...\Godot_v4.7.2-stable_win64.exe" -Version "1.0.0"
#
# SAIDA:
#   C:\Lucifer_Game_Build\Lucifer.exe + Lucifer.pck   (exportacao Godot)
#   C:\Lucifer_Game_Installer\Setup_ARCANJO_CAIDO_v<Version>.exe  (se Inno Setup presente)
# ============================================================================

param(
	[string]$GodotPath = "",
	[string]$Version = "1.0.0-beta-final"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---------------------------------------------------------------------------
# 1. Localizar o executavel do Godot (mesma logica do build_release.ps1)
# ---------------------------------------------------------------------------
if ($GodotPath -eq "") {
	$candidates = @("$projectRoot\Godot", (Split-Path -Parent $projectRoot)) |
		Where-Object { Test-Path $_ }
	foreach ($base in $candidates) {
		$found = Get-ChildItem $base -Recurse -Filter "Godot*_win64.exe" -ErrorAction SilentlyContinue |
			Where-Object { $_.Name -notlike "*console*" } |
			Sort-Object FullName -Descending | Select-Object -First 1
		if ($found) { $GodotPath = $found.FullName; break }
	}
}
if ($GodotPath -eq "" -or -not (Test-Path $GodotPath)) {
	$cmd = Get-Command "godot" -ErrorAction SilentlyContinue
	if ($cmd) { $GodotPath = $cmd.Source }
}
if ($GodotPath -eq "" -or -not (Test-Path $GodotPath)) {
	Write-Host "[ERRO] Godot nao encontrado. Informe com -GodotPath 'C:\...\Godot.exe'" -ForegroundColor Red
	exit 1
}
Write-Host "[BUILD] Godot: $GodotPath" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2. Exportar preset "Windows Instalador" (exe + pck separados)
# ---------------------------------------------------------------------------
$consoleExe = $GodotPath -replace '\.exe$', '_console.exe'
$exporter = if (Test-Path $consoleExe) { $consoleExe } else { $GodotPath }

$buildDir = "C:\Lucifer_Game_Build"
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

Write-Host "[BUILD] Exportando 'Windows Instalador' -> $buildDir\Lucifer.exe ..." -ForegroundColor Cyan
& $exporter --headless --path $projectRoot --export-release "Windows Instalador" "$buildDir/Lucifer.exe"
$failed = ($LASTEXITCODE -ne 0)
if ($failed -or -not (Test-Path "$buildDir\Lucifer.exe") -or -not (Test-Path "$buildDir\Lucifer.pck")) {
	Write-Host "[ERRO] Falha no export. Verifique os templates de exportacao." -ForegroundColor Red
	exit 1
}
$sizeExe = "{0:N1} MB" -f ((Get-Item "$buildDir\Lucifer.exe").Length / 1MB)
$sizePck = "{0:N1} MB" -f ((Get-Item "$buildDir\Lucifer.pck").Length / 1MB)
Write-Host "[OK] Export concluido: Lucifer.exe ($sizeExe) + Lucifer.pck ($sizePck)" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 3. Compilar o instalador com o Inno Setup (se instalado)
# ---------------------------------------------------------------------------
$isccCandidates = @(
	"C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
	"C:\Program Files\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ }
$iscc = if ($isccCandidates) { $isccCandidates[0] } else { (Get-Command iscc -ErrorAction SilentlyContinue).Source }

if (-not $iscc) {
	Write-Host ""
	Write-Host "[AVISO] Inno Setup 6 nao encontrado - instalador NAO compilado." -ForegroundColor Yellow
	Write-Host "  1. Instale em: https://jrsoftware.org/isinfo.php"
	Write-Host "  2. Depois abra setup_lucifer.iss no Inno Setup e tecle Ctrl+F9,"
	Write-Host "     ou rode este script novamente."
	exit 0
}

$installerDir = "C:\Lucifer_Game_Installer"
if (-not (Test-Path $installerDir)) { New-Item -ItemType Directory -Path $installerDir | Out-Null }

Write-Host "[BUILD] Compilando instalador com: $iscc ..." -ForegroundColor Cyan
& $iscc "/DMyAppVersion=$Version" (Join-Path $projectRoot "setup_lucifer.iss")
if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERRO] Falha ao compilar o instalador (verifique o setup_lucifer.iss)." -ForegroundColor Red
	exit 1
}

$setupFile = Join-Path $installerDir "Setup_Arcanjos Caidos Beta Final_v$Version.exe"
$sizeSetup = if (Test-Path $setupFile) { "{0:N1} MB" -f ((Get-Item $setupFile).Length / 1MB) } else { "?" }

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " INSTALADOR GERADO (v$Version)" -ForegroundColor Green
Write-Host "   Export     : $buildDir\Lucifer.exe ($sizeExe) + Lucifer.pck ($sizePck)"
Write-Host "   Instalador : $setupFile ($sizeSetup)"
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Teste final: rode o Setup em outra pasta/maquina, confirme a pasta em"
Write-Host "C:\Program Files\ARCANJO CAIDO, os atalhos e o desinstalador."

