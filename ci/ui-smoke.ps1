<#
.SYNOPSIS
    Teste de tela do Vigia: sobe o app isolado contra um Jira falso e confere
    janela, abas, busca e Configurações por UI Automation.
.DESCRIPTION
    Isolado do Vigia do usuário: LOCALAPPDATA próprio (banco novo), USERNAME
    próprio (outro mutex de instância única) e conta com id 9001 (token falso
    "demo" no Credential Manager, apagado no fim). Precisa de Python 3 e de
    sessão interativa (o runner roda na sessão do usuário).
.EXAMPLE
    pwsh ci/ui-smoke.ps1 -Exe bin\Win32\Release\Vigia.exe
#>
#Requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$Exe,
    [int]$Port = 18090,
    [int]$WaitSec = 20
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Exe = (Resolve-Path $Exe).Path
$version = [regex]::Match((Get-Content (Join-Path $root 'src\Vigia.Model.pas') -Raw), "AppVersion\s*=\s*'([^']+)'").Groups[1].Value
$work = Join-Path ([IO.Path]::GetTempPath()) "vigia-smoke-$PID"
$db = Join-Path $work 'Vigia\vigia.db'
$failed = 0

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type @"
using System; using System.Runtime.InteropServices;
public class SmokeCred {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
  public struct C { public int Flags; public int Type; public string TargetName; public string Comment; public long LastWritten;
    public int BlobSize; public IntPtr Blob; public int Persist; public int AttrCount; public IntPtr Attrs; public string Alias; public string User; }
  [DllImport("advapi32.dll", CharSet=CharSet.Unicode)] public static extern bool CredWriteW(ref C c, int f);
  [DllImport("advapi32.dll", CharSet=CharSet.Unicode)] public static extern bool CredDeleteW(string t, int ty, int f);
  public static bool Write(string t, string v) { var b = System.Text.Encoding.UTF8.GetBytes(v); var c = new C();
    c.Type = 1; c.TargetName = t; c.BlobSize = b.Length; c.Persist = 2; c.User = "smoke";
    c.Blob = Marshal.AllocHGlobal(b.Length); Marshal.Copy(b, 0, c.Blob, b.Length);
    try { return CredWriteW(ref c, 0); } finally { Marshal.FreeHGlobal(c.Blob); } }
}
"@

function Check($name, [bool]$ok) {
    if ($ok) { Write-Host "    ok    $name" -ForegroundColor Green }
    else { Write-Host "    FALHOU $name" -ForegroundColor Red; $script:failed++ }
}

function Start-Vigia {
    $psi = [Diagnostics.ProcessStartInfo]::new($Exe, '-show')
    $psi.UseShellExecute = $false
    $psi.EnvironmentVariables['LOCALAPPDATA'] = $work
    $psi.EnvironmentVariables['TEMP'] = $work
    $psi.EnvironmentVariables['USERNAME'] = 'vigia-smoke'
    [Diagnostics.Process]::Start($psi)
}

function Sql($code) {
    $py = "import sqlite3; c = sqlite3.connect(r'$db'); $code; c.commit()"
    python -c $py
}

$server = $null; $app = $null
try {
    New-Item -ItemType Directory -Force $work | Out-Null
    $server = Start-Process python -ArgumentList "`"$(Join-Path $root 'ci\fake-jira.py')`" $Port" -PassThru -WindowStyle Hidden
    [SmokeCred]::Write('Vigia:9001', 'demo') | Out-Null

    # 1ª subida só cria o banco; a conta entra direto nele.
    $app = Start-Vigia; Start-Sleep 6; $app.Kill(); $app.WaitForExit()
    Sql ("c.execute(""insert into account (id, name, kind, base_url, login, enabled, events, due_days, warn_days, critical_days) " +
        "values (9001, 'Smoke', 1, 'http://127.0.0.1:$Port', '', 1, 2047, 2, 5, 2)""); " +
        "c.execute(""insert or replace into setting (name, value) values ('lang', 'pt')"")")

    $app = Start-Vigia
    Start-Sleep $WaitSec
    Write-Host "==> teste de tela (Vigia $version)" -ForegroundColor Cyan

    # Pela janela do processo do teste: o Vigia do usuário pode estar aberto com a mesma versão.
    $N = [Windows.Automation.AutomationElement]::NameProperty
    $CT = [Windows.Automation.AutomationElement]::ControlTypeProperty
    $main = [Windows.Automation.AutomationElement]::RootElement.FindFirst('Children',
        [Windows.Automation.AndCondition]::new(
            [Windows.Automation.PropertyCondition]::new([Windows.Automation.AutomationElement]::ProcessIdProperty, $app.Id),
            [Windows.Automation.PropertyCondition]::new([Windows.Automation.AutomationElement]::ClassNameProperty, 'TMainForm')))
    Check "janela 'Vigia $version' aberta" (($null -ne $main) -and ($main.Current.Name -eq "Vigia $version"))
    if ($main) {
        foreach ($tab in 'Dashboard', 'Issues', 'Contas', 'Configurações') {
            $c = [Windows.Automation.AndCondition]::new([Windows.Automation.PropertyCondition]::new($N, $tab),
                [Windows.Automation.PropertyCondition]::new($CT, [Windows.Automation.ControlType]::TabItem))
            $el = $main.FindFirst('Descendants', $c)
            $ok = $false
            if ($el) {
                $el.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Select()
                Start-Sleep -Milliseconds 600
                $ok = $el.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Current.IsSelected
            }
            Check "aba $tab abre" $ok
        }
        $btn = $main.FindFirst('Descendants', [Windows.Automation.PropertyCondition]::new($N, 'Procurar agora'))
        Check 'Configurações mostram Atualizações' ($null -ne $btn)
    }
    $count = python -c "import sqlite3; print(sqlite3.connect(r'$db').execute('select count(*) from item_snapshot where account_id=9001').fetchone()[0])"
    Check "busca no Jira falso salvou 12 issues (veio $count)" ($count -eq '12')
    Check 'app continua rodando' (-not $app.HasExited)
}
finally {
    if ($app -and -not $app.HasExited) { $app.Kill() }
    if ($server -and -not $server.HasExited) { $server.Kill() }
    [SmokeCred]::CredDeleteW('Vigia:9001', 1, 0) | Out-Null
    Start-Sleep 1
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}
if ($failed) { throw "$failed verificação(ões) do teste de tela falharam" }
Write-Host '    teste de tela ok' -ForegroundColor Green
