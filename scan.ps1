# scan.ps1 — Finora SonarQube Scanner (Windows)
# Uso: .\scan.ps1  (ejecutar desde la raíz del repo)
# Requiere: Flutter SDK, Node.js, npx sonarqube-scanner
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── FASE 1: Flutter tests + coverage ─────────────────────────────────────────
Write-Host "`n[1/3] Ejecutando Flutter tests con coverage..." -ForegroundColor Cyan
Push-Location finora_frontend
try {
    flutter test --coverage
} finally {
    Pop-Location
}

# ── FASE 2: Normalización de lcov.info (Regex Gold Rule) ─────────────────────
# Problema en Windows: flutter genera rutas con '\' y prefijos absolutos.
# SonarQube necesita rutas Unix RELATIVAS al projectBaseDir de cada módulo.
# Regla:
#   1. Sustituir todos los '\' por '/'
#   2. Colapsar cualquier prefijo antes de 'lib/' al prefijo canónico
#      que SonarQube espera: 'SF:finora_frontend/lib/'
Write-Host "`n[2/3] Normalizando rutas en lcov.info..." -ForegroundColor Cyan

$lcovPath = "finora_frontend\coverage\lcov.info"
if (-not (Test-Path $lcovPath)) {
    Write-Error "No se encontró $lcovPath. Asegúrate de que 'flutter test --coverage' completó correctamente."
    exit 1
}

$content = Get-Content $lcovPath -Raw -Encoding UTF8

# Paso 1 — normalizar separadores
$content = $content -replace '\\', '/'

# Paso 2 — asegurar prefijo exacto 'SF:finora_frontend/lib/'
# Captura cualquier cosa antes de 'lib/' (ruta absoluta o relativa) y la reemplaza
$content = $content -replace 'SF:(?:.+/)?lib/', 'SF:finora_frontend/lib/'

Set-Content -Path $lcovPath -Value $content -NoNewline -Encoding UTF8
Write-Host "lcov.info normalizado correctamente." -ForegroundColor Green

# ── FASE 3: SonarQube scan ────────────────────────────────────────────────────
Write-Host "`n[3/3] Ejecutando SonarQube scanner..." -ForegroundColor Cyan
npx sonarqube-scanner

Write-Host "`nScan completado. Revisa los resultados en http://localhost:9000" -ForegroundColor Green
