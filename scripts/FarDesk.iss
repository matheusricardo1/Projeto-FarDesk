#define AppName "FarDesk"
#define AppPublisher "FarDesk"
#define AppExeName "FarDesk.exe"
#define AppURL "https://github.com/matheusricardo1/Projeto-FarDesk"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef AppBuild
  #define AppBuild "1"
#endif

[Setup]
AppId={{E6C6BA2D-6C38-4D06-9D6A-7AC6A8F4E38B}
AppName={#AppName}
AppVerName={#AppName} {#AppVersion}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
AppCopyright=Copyright (C) {#GetDateTimeString("yyyy","","")} {#AppPublisher}
DefaultDirName={autopf}\FarDesk
DefaultGroupName=FarDesk
UsePreviousAppDir=yes
UsePreviousGroup=yes
Uninstallable=yes
DirExistsWarning=no
OutputBaseFilename=FarDesk-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
CloseApplications=yes
CloseApplicationsFilter=FarDesk.exe
RestartApplications=no
MinVersion=10.0
SetupMutex=FarDeskSetupMutex
WizardStyle=modern
SetupIconFile=..\app_desktop\windows\runner\resources\app_icon.ico
WizardImageFile=..\build\installer-assets\wizard-image.bmp
WizardSmallImageFile=..\build\installer-assets\wizard-small.bmp
UninstallDisplayIcon={app}\{#AppExeName}
VersionInfoDescription=FarDesk remote desktop client
VersionInfoProductName=FarDesk
VersionInfoProductVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoCopyright=Copyright (C) {#GetDateTimeString("yyyy","","")} {#AppPublisher}

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\app_desktop\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\FarDesk"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{autoprograms}\{cm:UninstallProgram,FarDesk}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\FarDesk"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,FarDesk}"; Flags: nowait postinstall skipifsilent
