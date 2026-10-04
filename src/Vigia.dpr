program Vigia;

uses
  Winapi.Windows,
  System.SysUtils,
  Vcl.Forms,
  UI.Runtime.Vcl,
  Vigia.UI.Main in 'Vigia.UI.Main.pas',
  Vigia.Model in 'Vigia.Model.pas',
  Vigia.Secrets in 'Vigia.Secrets.pas',
  Vigia.Store in 'Vigia.Store.pas',
  Vigia.Providers in 'Vigia.Providers.pas',
  Vigia.UI.Account in 'Vigia.UI.Account.pas',
  Vigia.Diff in 'Vigia.Diff.pas',
  Vigia.TrayIcon in 'Vigia.TrayIcon.pas',
  Vigia.UI.Common in 'Vigia.UI.Common.pas',
  Vigia.UI.Detail in 'Vigia.UI.Detail.pas',
  Vigia.UI.Views in 'Vigia.UI.Views.pas',
  Vigia.UI.Status in 'Vigia.UI.Status.pas',
  Vigia.UI.Notify in 'Vigia.UI.Notify.pas',
  Vigia.AI in 'Vigia.AI.pas',
  Vigia.UI.Tags in 'Vigia.UI.Tags.pas',
  Vigia.Update in 'Vigia.Update.pas';

var
  Mutex: THandle;

begin
  // Uma instância por usuário do Windows: outro usuário na mesma sessão
  // (Executar como) abre o dele. Banco, tokens e autostart já são por usuário.
  Mutex := CreateMutex(nil, True, PChar('Local\Vigia.' +
    StringReplace(GetEnvironmentVariable('USERDOMAIN') + '.' + GetEnvironmentVariable('USERNAME'),
      '\', '.', [rfReplaceAll])));
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    // Já está na bandeja: só pede para abrir a janela.
    // Broadcast não chega: o form é dono-da-Application. Acha pela legenda.
    PostMessage(FindWindow('TMainForm', PChar('Vigia ' + AppVersion)),
      RegisterWindowMessage(ShowMessageName), 0, 0);
    Exit;
  end;
  try
    Application.Initialize;
    Application.ShowMainForm := False;
    Application.Title := 'Vigia';
    Application.CreateForm(TMainForm, MainForm);
    // --show abre a janela já na largada (útil para captura e teste).
    if FindCmdLineSwitch('show') then
      MainForm.Show;
    Application.Run;
  finally
    CloseHandle(Mutex);
  end;
end.
