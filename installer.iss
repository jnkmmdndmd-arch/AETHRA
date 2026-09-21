#define MyAppName "AETHRA: Wildbound"
#define MyAppVersion "0.3.0"
#define MyAppPublisher "AETHRA"
#define MyAppExeName "AETHRA-Wildbound.exe"

[Setup]
AppId={{5C5E5D1F-8C7E-4F6A-9C26-7A0AF8DFE3B1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\AETHRA Wildbound
DefaultGroupName=AETHRA Wildbound
OutputDir=build
OutputBaseFilename=AETHRA-Wildbound-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayName=AETHRA: Wildbound

[Files]
Source: "build\AETHRA-Wildbound.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\AETHRA: Wildbound"; Filename: "{app}\AETHRA-Wildbound.exe"; WorkingDir: "{app}"
Name: "{userdesktop}\AETHRA: Wildbound"; Filename: "{app}\AETHRA-Wildbound.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\AETHRA-Wildbound.exe"; Description: "تشغيل AETHRA: Wildbound"; Flags: nowait postinstall skipifsilent