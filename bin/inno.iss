#define MyAppName "kaligraf"
#define MyAppVersion "0.20.0"
#define MyAppPublisher "monsterkodi"
#define MyAppURL "https://github.com/monsterkodi/kaligraf"
#define MyAppExeName "kaligraf.exe"

[Setup]
AppId={{08229C08-D169-4B97-A6D0-CC63BAEA3297}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=C:\Users\kodi\s\{#MyAppName}\inno
OutputBaseFilename={#MyAppName}-{#MyAppVersion}-setup
SetupIconFile=C:\Users\kodi\s\{#MyAppName}\img\{#MyAppName}.ico
Compression=lzma
SolidCompression=yes
WizardImageFile=C:\Users\kodi\s\{#MyAppName}\img\innolarge.bmp
WizardSmallImageFile=C:\Users\kodi\s\{#MyAppName}\img\innosmall.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\kodi\s\{#MyAppName}\{#MyAppName}-win32-x64\{#MyAppName}.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\kodi\s\{#MyAppName}\{#MyAppName}-win32-x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

