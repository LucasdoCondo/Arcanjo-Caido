# ============================================================================
# [ARCANJO CAIDO] — build_release.ps1 (Passo 24.3)
# ----------------------------------------------------------------------------
# Compila o jogo em executável Windows 100% offline e empacota o .zip de
# distribuição (Itch.io / Steam / drive).
#
# USO:
#   powershell -ExecutionPolicy Bypass -File build_release.ps1
#   powershell -ExecutionPolicy Bypass -File build_release.ps1 -GodotPath "C:\caminho\Godot_v4.7.2-stable_win64.exe"
#
# SAIDA:
#   build/ARCANJO_CAIDO.exe                      ← executável (pck embutido)
#   dist/ARCANJO_CAIDO_v1.0.0.zip                ← pacote pronto para distribuir
#
# REQUISITOS:
#   - Godot 4.x (o script procura no caminho padrao do projeto ou use -GodotPath)
#   - templates de exportacao instalados (Editor → Manage Export Templates,
#     ou godot --headless --install-export-templates)
#   - NAO precisa do .NET/Visual Studio: export Windows Desktop usa o template
#     pronto e nao compila DLLs — o .exe ja traz tudo que o jogo precisa.
# ============================================================================

param(
	[string]$GodotPath = "",
	[string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---------------------------------------------------------------------------
# 1. Localizar o executavel do Godot
# ---------------------------------------------------------------------------
if ($GodotPath -eq "") {
	# Procura em: ./Godot (local), pasta pai (../Godot — layout atual do projeto) e PATH
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
	# Ultima tentativa: Godot no PATH
	$cmd = Get-Command "godot" -ErrorAction SilentlyContinue
	if ($cmd) { $GodotPath = $cmd.Source }
}
if ($GodotPath -eq "" -or -not (Test-Path $GodotPath)) {
	Write-Host "[ERRO] Godot nao encontrado. Informe com -GodotPath 'C:\...\Godot.exe'" -ForegroundColor Red
	exit 1
}
Write-Host "[BUILD] Godot: $GodotPath" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2. Exportar (headless, sem editor)
# ---------------------------------------------------------------------------
# Usa o _console.exe quando disponivel: executaveis GUI (win64.exe) nao
# bloqueiam o PowerShell nem definem $LASTEXITCODE de forma confiavel.
$consoleExe = $GodotPath -replace '\.exe$', '_console.exe'
$exporter = if (Test-Path $consoleExe) { $consoleExe } else { $GodotPath }

if (-not (Test-Path "build")) { New-Item -ItemType Directory -Path "build" | Out-Null }
Write-Host "[BUILD] Exportando 'Windows Offline' -> build/ARCANJO_CAIDO.exe ..." -ForegroundColor Cyan
if ($exporter -ne $GodotPath) {
	# Console exe: aguarda e captura exit code normalmente.
	& $exporter --headless --path $projectRoot --export-release "Windows Offline" "build/ARCANJO_CAIDO.exe"
	$failed = ($LASTEXITCODE -ne 0)
} else {
	# GUI exe: aguarda via Start-Process e valida pelo arquivo gerado.
	$proc = Start-Process -FilePath $exporter -ArgumentList "--headless","--path","`"$projectRoot`"","--export-release","`"Windows Offline`"","build/ARCANJO_CAIDO.exe" -Wait -PassThru
	$failed = $false
}
if ($failed -or -not (Test-Path "build/ARCANJO_CAIDO.exe")) {
	Write-Host "[ERRO] Falha no export. Verifique os templates de exportacao." -ForegroundColor Red
	exit 1
}

# ---------------------------------------------------------------------------
# 3. Empacotar o .zip de distribuicao
# ---------------------------------------------------------------------------
if (-not (Test-Path "dist")) { New-Item -ItemType Directory -Path "dist" | Out-Null }
$zipName = "ARCANJO_CAIDO_v$Version.zip"
$zipPath = Join-Path "dist" $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Write-Host "[BUILD] Empacotando $zipName ..." -ForegroundColor Cyan
Compress-Archive -Path "build/ARCANJO_CAIDO.exe" -DestinationPath $zipPath -CompressionLevel Optimal

$sizeExe = "{0:N1} MB" -f ((Get-Item "build/ARCANJO_CAIDO.exe").Length / 1MB)
$sizeZip = "{0:N1} MB" -f ((Get-Item $zipPath).Length / 1MB)

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " BUILD CONCLUIDA (v$Version)" -ForegroundColor Green
Write-Host "   Executavel : build/ARCANJO_CAIDO.exe ($sizeExe)"
Write-Host "   Pacote     : $zipPath ($sizeZip)"
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Para publicar:"
Write-Host "  Itch.io : butler push dist/ARCANJO_CAIDO_v$Version.zip usuario/arcanjo-caido:windows"
Write-Host "  Steam   : use o zip como conteudo do depot via SteamPipe (steamcmd)"
