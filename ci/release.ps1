<#
.SYNOPSIS
    Publica uma release do Vigia: liga o runner, cria a tag, espera o workflow
    e desliga o runner no fim (mesmo se falhar).
.DESCRIPTION
    O runner self-hosted (actions-runner\ nesta pasta) não roda o tempo todo.
    Este script é o único caminho de release:
      1. confere árvore limpa, branch enviado e tag nova (v<AppVersion>);
      2. sobe o runner escondido e espera ele ficar online no GitHub;
      3. cria e envia a tag; o workflow Release compila e publica;
      4. acompanha o run até terminar e desliga o runner.
.EXAMPLE
    pwsh ci/release.ps1
#>
#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Repo = 'herlondf/vigia',
    [int]$OnlineTimeoutSec = 90
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runnerDir = Join-Path $root 'actions-runner'
$env:MSYS_NO_PATHCONV = '1'

function Step($text) { Write-Host "==> $text" -ForegroundColor Cyan }

function Get-RunnerProcesses {
    Get-Process Runner.Listener, Runner.Worker -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith($runnerDir, 'OrdinalIgnoreCase') }
}

function Stop-Runner {
    $procs = @(Get-RunnerProcesses)
    # O cmd do run.cmd/run-helper.cmd fica órfão se não sair junto.
    $shells = @(Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" |
        Where-Object { $_.CommandLine -like "*$runnerDir*" })
    $procs | Stop-Process -Force
    $shells | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    if ($procs -or $shells) { Step "runner desligado ($($procs.Count + $shells.Count) processo(s))" }
}

function Get-RunnerStatus {
    $name = (Get-Content (Join-Path $runnerDir '.runner') -Raw | ConvertFrom-Json).agentName
    $list = gh api "repos/$Repo/actions/runners" | ConvertFrom-Json
    ($list.runners | Where-Object name -eq $name).status
}

# 1. Pré-condições
Set-Location $root
if (-not (Test-Path (Join-Path $runnerDir '.runner'))) { throw "Runner não configurado em $runnerDir (config.cmd com --labels vigia)" }
$model = Get-Content (Join-Path $root 'src\Vigia.Model.pas') -Raw
$version = [regex]::Match($model, "AppVersion\s*=\s*'([^']+)'").Groups[1].Value
$tag = "v$version"
if (git status --porcelain) { throw 'Há mudanças sem commit. Faça o commit antes da release.' }
git fetch origin --tags --quiet
if (git tag --list $tag) { throw "A tag $tag já existe. Suba AppVersion em src\Vigia.Model.pas." }
$branch = git rev-parse --abbrev-ref HEAD
git push origin $branch --quiet
if ($LASTEXITCODE -ne 0) { throw "push de $branch falhou" }
Step "release $tag a partir de $branch"

try {
    # 2. Liga o runner escondido e espera ficar online
    if (-not (Get-RunnerProcesses)) {
        Start-Process -FilePath (Join-Path $runnerDir 'run.cmd') -WorkingDirectory $runnerDir -WindowStyle Hidden
    }
    $deadline = (Get-Date).AddSeconds($OnlineTimeoutSec)
    while ((Get-RunnerStatus) -ne 'online') {
        if ((Get-Date) -gt $deadline) { throw "Runner não ficou online em $OnlineTimeoutSec s. Ver $runnerDir\_diag" }
        Start-Sleep -Seconds 3
    }
    Step 'runner online'

    # 3. Tag dispara o workflow
    git tag -a $tag -m "Vigia $version"
    git push origin $tag --quiet
    if ($LASTEXITCODE -ne 0) { throw "push da tag $tag falhou" }

    # 4. Acompanha o run da tag até o fim
    $runId = $null
    $deadline = (Get-Date).AddSeconds(60)
    while (-not $runId) {
        if ((Get-Date) -gt $deadline) { throw 'O workflow Release não apareceu para a tag.' }
        Start-Sleep -Seconds 3
        $runId = (gh run list -R $Repo --workflow release.yml --branch $tag --limit 1 --json databaseId |
            ConvertFrom-Json).databaseId
    }
    Step "workflow em andamento (run $runId)"
    gh run watch $runId -R $Repo --exit-status --interval 10
    if ($LASTEXITCODE -ne 0) { throw "O workflow falhou: gh run view $runId -R $Repo --log-failed" }

    $url = gh release view $tag -R $Repo --json url --jq .url
    Step "publicada: $url"
}
finally {
    Stop-Runner
}
