; Instalador por usuário do Vigia (não pede administrador).
; Gerado por ci/build-release.ps1, que passa a versão e a pasta do build:
;   ISCC /DAppVersion=0.20.0 /DBinDir=..\bin\Win32\Release /DOutDir=..\dist Vigia.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef BinDir
  #define BinDir "..\bin\Win32\Release"
#endif
#ifndef OutDir
  #define OutDir "..\dist"
#endif

[Setup]
AppId={{6C1F2D7A-4B8E-4E59-9C3A-2F7D5B1E8A40}
AppName=Vigia
AppVersion={#AppVersion}
AppVerName=Vigia {#AppVersion}
AppPublisher=Herlon Filgueira
AppPublisherURL=https://github.com/herlondf/vigia
DefaultDirName={localappdata}\Programs\Vigia
DefaultGroupName=Vigia
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
OutputDir={#OutDir}
OutputBaseFilename=Vigia-Setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\Vigia.exe
UninstallDisplayName=Vigia
CloseApplications=force
RestartApplications=no
ArchitecturesAllowed=x86compatible
ShowLanguageDialog=auto

[Languages]
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BinDir}\Vigia.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BinDir}\sk4d.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BinDir}\assets\assistant\*.json"; DestDir: "{app}\assets\assistant"; Flags: ignoreversion

[Icons]
Name: "{userprograms}\Vigia"; Filename: "{app}\Vigia.exe"; Parameters: "-show"
Name: "{userdesktop}\Vigia"; Filename: "{app}\Vigia.exe"; Parameters: "-show"; Tasks: desktopicon

[Registry]
; O app grava aqui quando "Iniciar com o Windows" está ligado; sai junto na desinstalação.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "Vigia"; ValueType: none; Flags: uninsdeletevalue dontcreatekey

[Run]
Filename: "{app}\Vigia.exe"; Parameters: "-show"; Description: "{cm:LaunchProgram,Vigia}"; Flags: nowait postinstall skipifsilent
; Atualização pelo próprio app (/RELAUNCH=1): reabre o Vigia no fim da instalação silenciosa.
Filename: "{app}\Vigia.exe"; Parameters: "{code:RelaunchArgs}"; Flags: nowait skipifnotsilent; Check: RelaunchRequested

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM Vigia.exe /FI ""USERNAME eq {username}"""; Flags: runhidden; RunOnceId: "StopVigia"

[Code]
function RelaunchRequested: Boolean;
begin
  Result := ExpandConstant('{param:RELAUNCH|0}') = '1';
end;

function RelaunchArgs(Param: string): string;
begin
  if ExpandConstant('{param:SHOW|0}') = '1' then
    Result := '-show'
  else
    Result := '';
end;
