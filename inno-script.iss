#define ReleaseDir "build\windows\x64\runner\Release"
#define TempDir GetEnv('LOCALAPPDATA') + "\Temp\StressPilotInstaller\Release"

[Setup]
AppId=a8bea9a0-e96d-11f0-85ae-7f61cad0019a
AppName=Stress Pilot
UninstallDisplayName=Stress Pilot
UninstallDisplayIcon={app}\stress_pilot.exe
AppVersion=1.0.8
AppPublisher=Ly Hien Long
AppPublisherURL=
AppSupportURL=
AppUpdatesURL=
LicenseFile=LICENSE
DefaultDirName={autopf}\Stress Pilot
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline dialog
OutputDir=build\windows\x64\installer\Release
OutputBaseFilename=StressPilot-x86_64-1.0.8-Installer
SetupIconFile={#TempDir}\..\installer.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableDirPage=no
DisableProgramGroupPage=auto

[InstallDelete]
Type: filesandordirs; Name: "{app}\*"

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#ReleaseDir}\stress_pilot.exe";                        DestDir: "{app}";      Flags: ignoreversion
Source: "{#ReleaseDir}\data\*";                                  DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#ReleaseDir}\flutter_inappwebview_windows_plugin.dll"; DestDir: "{app}";      Flags: ignoreversion
Source: "{#ReleaseDir}\flutter_windows.dll";                     DestDir: "{app}";      Flags: ignoreversion
Source: "{#ReleaseDir}\local_notifier_plugin.dll";               DestDir: "{app}";      Flags: ignoreversion
Source: "{#ReleaseDir}\screen_retriever_windows_plugin.dll";     DestDir: "{app}";      Flags: ignoreversion
Source: "{#ReleaseDir}\tray_manager_plugin.dll";                 DestDir: "{app}";      Flags: ignoreversion
Source: "{#ReleaseDir}\url_launcher_windows_plugin.dll";         DestDir: "{app}";      Flags: ignoreversion
Source: "{#ReleaseDir}\WebView2Loader.dll";                      DestDir: "{app}";      Flags: ignoreversion
Source: "{#ReleaseDir}\window_manager_plugin.dll";               DestDir: "{app}";      Flags: ignoreversion
Source: "{#TempDir}\msvcp140.dll";                               DestDir: "{app}";      Flags: ignoreversion
Source: "{#TempDir}\vcruntime140.dll";                           DestDir: "{app}";      Flags: ignoreversion
Source: "{#TempDir}\vcruntime140_1.dll";                         DestDir: "{app}";      Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Stress Pilot"; Filename: "{app}\stress_pilot.exe"
Name: "{autodesktop}\Stress Pilot";  Filename: "{app}\stress_pilot.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\stress_pilot.exe"; Description: "{cm:LaunchProgram,{#StringChange('Stress Pilot', '&', '&&')}}"; Flags: nowait postinstall skipifsilent
