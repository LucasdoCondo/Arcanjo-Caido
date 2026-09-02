; =====================================================================
; SCRIPT DE INSTALAÇÃO - INNO SETUP 6 (GODOT 4.7 — ARCANJO CAIDO)
; ------------------------------------------------------------------------------
; Compila o instalador Setup_Arcanjos Caidos Beta Final_v1.0.0-beta-final.exe a partir da exportação
; do preset "Windows Instalador" (Lucifer.exe + Lucifer.pck em C:\Lucifer_Game_Build).
;
; COMO USAR:
;   1. Exporte o preset "Windows Instalador" na Godot (ou rode build_instalador.ps1)
;   2. Abra este arquivo no Inno Setup Compiler (https://jrsoftware.org/isinfo.php)
;   3. Menu Build > Compile (Ctrl+F9)
;   4. O instalador final aparece em C:\Lucifer_Game_Installer
;
; Por linha de comando (sem abrir a GUI):
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup_lucifer.iss
; =====================================================================

#define MyAppName "Arcanjos Caídos Beta Final"
; A versão pode ser sobrescrita na linha de comando:
;   ISCC.exe /DMyAppVersion=1.0.0 setup_lucifer.iss
#ifndef MyAppVersion
#define MyAppVersion "1.0.0-beta-final"
#endif
#define MyAppPublisher "Equipe Arcanjo Caido"
#define MyAppURL "https://arcanjo-caido.itch.io"
#define MyAppExeName "Lucifer.exe"

; CAMINHO AONDE ESTÃO OS ARQUIVOS EXPORTADOS PELA GODOT NO SEU PC
; (preset "Windows Instalador" do export_presets.cfg)
#define SourceFolderPath "C:\Lucifer_Game_Build"

; CAMINHO ONDE O INSTALADOR FINAL (.EXE) SERÁ SALVO
#define OutputFolderPath "C:\Lucifer_Game_Installer"

[Setup]
; --- Informações básicas do aplicativo ---------------------------------------
; AppId é a identidade única do app: NUNCA mude entre versões, senão o Windows
; trata a atualização como outro programa (e a desinstalação não limpa a antiga).
AppId={{D4B7F2A9-8C3E-4F61-9A5D-2E7B1C8D6F03}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; --- Diretório padrão de instalação no PC do jogador --------------------------
; {autopf} = C:\Program Files (x86) ou C:\Program Files conforme o Windows.
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; --- Configurações do arquivo de saída (o instalador final) -------------------
; OBS: o nome do arquivo NÃO usa os ":" do título — Windows não permite ":" em nomes.
OutputDir={#OutputFolderPath}
OutputBaseFilename=Setup_{#MyAppName}_v{#MyAppVersion}
; O grosso do tamanho é o Lucifer.exe (template Godot ~104 MB), então solid+lzma2
; comprime bem; ultra64 demora alguns minutos na compilação.
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

; --- Ícone do instalador (opcional) --------------------------------------------
; A Godot exporta ícone em .svg; o Inno Setup exige .ico.
; Quando tiver um .ico, descomente a linha abaixo e aponte para ele:
; SetupIconFile={#SourceFolderPath}\game_icon.ico

; --- Metadados exibidos no "Adicionar ou Remover Programas" -------------------
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
; Saves/conquistas/configs ficam em user:// (AppData) — NÃO apagados na desinstalação.

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
; Atalho na Área de Trabalho vem DESMARCADO por padrão (mude para Flags: ""
; se quiser que venha marcado). O atalho do Menu Iniciar é sempre criado.
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Executável principal (template Godot + tudo embutido que a Godot adiciona)
Source: "{#SourceFolderPath}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; O Lucifer.pck (dados do jogo: cenas, scripts, assets importados, dialogs.json...)
; e qualquer outro arquivo que esteja na pasta de exportação — exceto o próprio .exe,
; já incluído acima.
Source: "{#SourceFolderPath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "{#MyAppExeName}"

[Icons]
; Atalho no Menu Iniciar
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; Atalho do Desinstalador no Menu Iniciar
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
; Atalho na Área de Trabalho (só se o usuário marcar a opção na instalação)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Opção para rodar o jogo imediatamente após terminar a instalação
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent