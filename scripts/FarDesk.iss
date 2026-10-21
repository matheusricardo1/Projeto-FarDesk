#define AppName "FarDesk"
#define AppPublisher "FarDesk"
#define AppExeName "FarDesk.exe"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef AppBuild
  #define AppBuild "1"
#endif

[Setup]
AppId={{E6C6BA2D-6C38-4D06-9D6A-7AC6A8F4E38B}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\FarDesk
DefaultGroupName=FarDesk
OutputBaseFilename=FarDesk-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#AppExeName}
VersionInfoDescription=FarDesk remote desktop client
VersionInfoProductName=FarDesk
VersionInfoProductVersion={#AppVersion}

[Files]
Source: "..\app_desktop\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\FarDesk"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\FarDesk"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na área de trabalho"; GroupDescription: "Atalhos:"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Iniciar FarDesk"; Flags: nowait postinstall skipifsilent
