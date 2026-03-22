#define ReleaseDir "build\windows\x64\runner\Release"
#define TempDir GetEnv('LOCALAPPDATA') + "\Temp\StressPilotInstaller\Release"
#define JdkUrl "https://aka.ms/download-jdk/microsoft-jdk-25-windows-x64.zip"

[Setup]
AppId=a8bea9a0-e96d-11f0-85ae-7f61cad0019a
AppName=Stress Pilot
UninstallDisplayName=Stress Pilot
UninstallDisplayIcon={app}\stress_pilot.exe
AppVersion=1.0.2
AppPublisher=Ly Hien Long
AppPublisherURL=
AppSupportURL=https://github.com/Zeann3th/StressPilotV2_App
AppUpdatesURL=
LicenseFile=LICENSE
DefaultDirName={autopf}\Stress Pilot
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=
OutputDir=build\windows\x64\installer\Release
OutputBaseFilename=StressPilot-x86_64-1.0.2-Installer
SetupIconFile={#TempDir}\..\installer.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableDirPage=auto
DisableProgramGroupPage=auto
ArchiveExtraction=full

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

; JDK Download - using native Inno Setup 6.1+ download and extract flags
Source: "{#JdkUrl}"; DestDir: "{tmp}\jdk_extract"; DestName: "jdk25.zip"; ExternalSize: 204472320; Flags: external download extractarchive ignoreversion deleteafterinstall; Check: IsDownloadJdkSelected

[Icons]
Name: "{autoprograms}\Stress Pilot"; Filename: "{app}\stress_pilot.exe"
Name: "{autodesktop}\Stress Pilot";  Filename: "{app}\stress_pilot.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\stress_pilot.exe"; Description: "{cm:LaunchProgram,{#StringChange('Stress Pilot', '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  JdkPage: TWizardPage;
  DownloadJdkRadio, SystemJdkRadio: TNewRadioButton;

procedure InitializeWizard;
begin
  JdkPage := CreateCustomPage(wpReady, 'Java Runtime Environment', 'Stress Pilot requires JDK 25 to run the backend.');

  DownloadJdkRadio := TNewRadioButton.Create(WizardForm);
  DownloadJdkRadio.Parent := JdkPage.Surface;
  DownloadJdkRadio.Caption := 'Download and install Microsoft JDK 25 (Recommended)';
  DownloadJdkRadio.Top := ScaleY(10);
  DownloadJdkRadio.Width := JdkPage.SurfaceWidth;
  DownloadJdkRadio.Checked := True;

  SystemJdkRadio := TNewRadioButton.Create(WizardForm);
  SystemJdkRadio.Parent := JdkPage.Surface;
  SystemJdkRadio.Caption := 'Use system Java (Ensure you have JDK 25 installed and in PATH)';
  SystemJdkRadio.Top := DownloadJdkRadio.Top + ScaleY(30);
  SystemJdkRadio.Width := JdkPage.SurfaceWidth;
end;

function IsDownloadJdkSelected: Boolean;
begin
  Result := DownloadJdkRadio.Checked;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  TmpExtractDir, TargetJdkDir, PsCmd: String;
  ResultCode: Integer;
begin
  if (CurStep = ssPostInstall) and IsDownloadJdkSelected then
  begin
    // Inno Setup extracts jdk25.zip to DestDir when extractarchive flag is used
    TmpExtractDir := ExpandConstant('{tmp}\jdk_extract');
    TargetJdkDir := ExpandConstant('{app}\jdk');

    if DirExists(TmpExtractDir) then
    begin
      WizardForm.StatusLabel.Caption := 'Finalizing JDK installation...';
      
      // 1. Flatten nested folder if any (e.g. {tmp}\jdk_extract\jdk-25.x.x -> {tmp}\jdk_extract\)
      // 2. Move contents to {app}\jdk
      PsCmd := '-NoProfile -NonInteractive -Command ' +
               '"$tmpDir = ''' + TmpExtractDir + '''; ' +
               '$targetDir = ''' + TargetJdkDir + '''; ' +
               '$sub = Get-ChildItem -Path $tmpDir -Directory | Select-Object -First 1; ' +
               'if ($sub) { ' +
               '  Get-ChildItem $sub.FullName | Move-Item -Destination $tmpDir -Force; ' +
               '  Remove-Item $sub.FullName -Recurse -Force ' +
               '}; ' +
               'if (Test-Path $targetDir) { Remove-Item $targetDir -Recurse -Force }; ' +
               'New-Item -ItemType Directory -Path $targetDir -Force; ' +
               'Move-Item -Path ($tmpDir + ''\*'') -Destination $targetDir -Force"';
      
      Exec('powershell.exe', PsCmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;
