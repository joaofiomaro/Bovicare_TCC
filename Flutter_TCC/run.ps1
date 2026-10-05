#cd Flutter_TCC
#.\run.ps1
# BoviCare — Script de execução rápida
# Uso: .\run.ps1

$AVD_NAME  = "Pixel_8_API35"
$EMULATOR  = "$env:LOCALAPPDATA\Android\sdk\emulator\emulator.exe"
$ADB       = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
$FLUTTER   = "$env:USERPROFILE\flutter\bin\flutter.bat"
$DEVICE_ID = "emulator-5554"

Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "   BoviCare - Flutter Run     " -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""

# 1. Verifica se emulador ja esta rodando
$running = & $ADB devices 2>$null | Select-String "emulator"

if ($running) {
    Write-Host "[OK] Emulador ja esta rodando." -ForegroundColor Cyan
} else {
    Write-Host "[>>] Iniciando emulador $AVD_NAME..." -ForegroundColor Yellow
    Start-Process -FilePath $EMULATOR -ArgumentList "-avd $AVD_NAME -gpu host"

    Write-Host "[..] Aguardando boot do Android (ate 2 min)..." -ForegroundColor Yellow

    $elapsed = 0
    $boot = ""
    while ($boot -ne "1" -and $elapsed -lt 120) {
        Start-Sleep -Seconds 4
        $elapsed += 4
        $boot = & $ADB shell getprop sys.boot_completed 2>$null
        Write-Host "     ${elapsed}s - boot: $boot"
    }

    if ($boot -ne "1") {
        Write-Host "[ERRO] Emulador nao iniciou. Verifique o Android Studio." -ForegroundColor Red
        exit 1
    }

    Write-Host "[OK] Emulador pronto!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# 2. Garante o .env (asset obrigatorio no build; conteudo nao sensivel)
$envFile = Join-Path $PSScriptRoot ".env"
$envExample = Join-Path $PSScriptRoot ".env.example"
if (-not (Test-Path $envFile)) {
    if (Test-Path $envExample) {
        Copy-Item $envExample $envFile
        Write-Host "[OK] .env criado a partir do .env.example" -ForegroundColor Cyan
    } else {
        New-Item -ItemType File -Path $envFile | Out-Null
        Write-Host "[OK] .env vazio criado (o app usa os padroes embutidos)" -ForegroundColor Cyan
    }
}

# 3. Compila e roda o app
Write-Host ""
Write-Host "[>>] Compilando BoviCare..." -ForegroundColor Yellow
Write-Host "[  ] Hot reload: r  |  Restart: R  |  Sair: q" -ForegroundColor DarkGray
Write-Host ""

& $FLUTTER run -d $DEVICE_ID
