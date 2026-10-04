<#
.SYNOPSIS
    Compila o Vigia em Release, roda o self-check e gera o instalador por usuário.
.DESCRIPTION
    Funciona na pasta de trabalho e no checkout do runner self-hosted.
    Precisa do RAD Studio 12 (Studio 22.0), da ComponentesUI e do Inno Setup 6.
    A ComponentesUI vem de -CuiRoot, da variável VIGIA_CUI ou de ..\Delphi\ComponentesUI.
    Saída: dist\Vigia-Setup-<versão>.exe
.EXAMPLE
    pwsh ci/build-release.ps1
#>
#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$CuiRoot = $env:VIGIA_CUI,
    [string]$Bds = $(if ($env:BDS) { $env:BDS } else { 'C:\Program Files (x86)\Embarcadero\Studio\22.0' }),
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $CuiRoot) { $CuiRoot = Join-Path $root '..\Delphi\ComponentesUI' }
$CuiRoot = [IO.Path]::GetFullPath($CuiRoot)

function Step($text) { Write-Host "==> $text" -ForegroundColor Cyan }

# Versão: única fonte é AppVersion em Vigia.Model.pas.
$model = Get-Content (Join-Path $root 'src\Vigia.Model.pas') -Raw
$version = [regex]::Match($model, "AppVersion\s*=\s*'([^']+)'").Groups[1].Value
if (-not $version) { throw 'AppVersion não encontrado em src\Vigia.Model.pas' }
Step "Vigia $version"

if (-not (Test-Path (Join-Path $CuiRoot 'src\core'))) { throw "ComponentesUI não encontrada em $CuiRoot (use -CuiRoot ou VIGIA_CUI)" }
$rsvars = Join-Path $Bds 'bin\rsvars.bat'
if (-not (Test-Path $rsvars)) { throw "RAD Studio não encontrado: $rsvars (use -Bds)" }
$msbuild = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\MSBuild.exe'

function Build($dproj, $cfg) {
    Step "build $(Split-Path $dproj -Leaf) ($cfg)"
    $cmd = "call `"$rsvars`" && `"$msbuild`" `"$dproj`" /t:Build /p:Config=$cfg /p:Platform=Win32 " +
        "/p:CUI=`"$CuiRoot`" /nologo /v:minimal"
    $out = cmd /c $cmd 2>&1
    if ($LASTEXITCODE -ne 0) {
        $out | Where-Object { $_ -match 'error|Fatal' } | Select-Object -First 20 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "build de $dproj falhou"
    }
    $warn = @($out | Where-Object { $_ -match ': warning ' -and $_ -match '\\Vigia\\' }).Count
    Write-Host "    ok, $warn aviso(s) do Vigia"
}

Build (Join-Path $root 'src\Vigia.dproj') 'Release'
if (-not $SkipTests) {
    Build (Join-Path $root 'tests\VigiaTests.dproj') 'Debug'
    Step 'self-check'
    $out = & (Join-Path $root 'bin\tests\Win32\Debug\VigiaTests.exe') 2>&1
    $out | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" }
    if (($out | Select-Object -Last 1) -notmatch 'TUDO OK') { throw 'self-check falhou' }
}

# Inno Setup: instalado por usuário (winget --scope user) ou no PATH.
$iscc = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { $iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source }
if (-not $iscc) { throw 'ISCC.exe não encontrado. Instale: winget install JRSoftware.InnoSetup --scope user' }

Step 'instalador'
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
& $iscc /Q "/DAppVersion=$version" "/DBinDir=$(Join-Path $root 'bin\Win32\Release')" "/DOutDir=$dist" (Join-Path $root 'installer\Vigia.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC saiu com $LASTEXITCODE" }

$setup = Join-Path $dist "Vigia-Setup-$version.exe"
if (-not (Test-Path $setup)) { throw "instalador não gerado: $setup" }
Step ("pronto: {0} ({1:N1} MB)" -f $setup, ((Get-Item $setup).Length / 1MB))

if ($env:GITHUB_OUTPUT) {
    "version=$version" | Add-Content $env:GITHUB_OUTPUT
    "setup=$setup" | Add-Content $env:GITHUB_OUTPUT
}
