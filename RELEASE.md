# ARCANJO CAIDO — Guia de Build e Lançamento (v1.0.0)

Guia do **Passo 24** para gerar o executável final 100% offline e distribuir em Itch.io/Steam.

---

## 1. Configurações do Projeto (já aplicadas)

| Item | Valor | Onde |
|---|---|---|
| Resolução nativa de renderização | **1920×1080** (janela inicial 1280×720, stretch `canvas_items`/`keep`) | `project.godot` → `[display]` |
| V-Sync | **Ligado por padrão** (`window/vsync/vsync_mode=1`), alternável no menu de Opções | `project.godot` + `DisplayManager` |
| Título da janela | `ARCANJO CAIDO` (derivado de `config/name`) | `project.godot` |
| Versão do jogo | **1.0.0** (`config/version`) | `project.godot` |
| Ícone do aplicativo | `res://icon.svg` (janela + executável) | `project.godot` + `export_presets.cfg` |
| Metadados do .exe | produto, versão `1.0.0.0`, empresa, copyright — visíveis em *Propriedades → Detalhes* do Windows | `export_presets.cfg` → `[preset.0.options]` |

---

## 2. Limpeza de Recursos (o que entra e o que não entra na build)

Configurado em `export_presets.cfg` (`export_filter="all_resources"`):

**Entra no pacote:**
- Todas as cenas, scripts (exceto debug), shaders e assets importados referenciados pelo jogo
- `assets/text/credits.txt` e `data/dialogs.json` — carregados via `FileAccess` em runtime, garantidos pelo `include_filter`

**Fica fora do pacote (`exclude_filter`):**
- `*.md`, `docs/*` — documentação
- `build/*`, `dist/*` — saídas de builds anteriores
- **`scripts/debug/*` — o Dev Menu de QA é removido por completo do lançamento** (o bootstrap no `main_menu.gd` usa `load()` com guarda em `OS.is_debug_build()`, então a ausência do arquivo não gera erro)
- `tmp_validate*.ps1` — validação local

> Os `.txt` de design na raiz do projeto não entram automaticamente: com `all_resources`, arquivos não-resource só são incluídos se casarem o `include_filter`.

---

## 3. Gerar a Build

### Pré-requisito (uma vez só)
Instalar os *Export Templates* da sua versão do Godot:
- Pelo editor: **Editor → Manage Export Templates → Download and Install**
- Ou via linha de comando: `godot --headless --install-export-templates`

### Build automática (recomendado)
```powershell
powershell -ExecutionPolicy Bypass -File build_release.ps1
# com caminho customizado do Godot:
powershell -ExecutionPolicy Bypass -File build_release.ps1 -GodotPath "C:\Godot\Godot_v4.7.2-stable_win64.exe" -Version "1.0.1"
```

O script (`build_release.ps1`):
1. Localiza o executável do Godot (padrão do projeto ou `-GodotPath`)
2. Exporta headless: `--export-release "Windows Offline" build/ARCANJO_CAIDO.exe`
3. Empacota: `dist/ARCANJO_CAIDO_v1.0.0.zip`

### Build manual
```powershell
godot --headless --path . --export-release "Windows Offline" build/ARCANJO_CAIDO.exe
```

### Estrutura de saída
```
build/
  ARCANJO_CAIDO.exe     ← executável único (.pck embutido — não há pasta de dados
                           separada nem DLLs externas: o template do Godot já traz
                           tudo embutido; distribuição de 1 arquivo)
dist/
  ARCANJO_CAIDO_v1.0.0.zip
```

> **Por que um único .exe?** Com `binary_format/embed_pck=true`, os dados do jogo
> ficam dentro do executável — o formato mais simples e à prova de erro para
> Itch.io e Steam. Se preferir `.exe + .pck` separados, troque para `false`.

---

## 4. Instalador Windows (Inno Setup)

Para distribuir um instalador (`Setup_ARCANJO_CAIDO_v1.0.0.exe`) em vez do `.zip`:

1. **Instale o Inno Setup 6** (gratuito): https://jrsoftware.org/isinfo.php
2. **Exporte o preset "Windows Instalador"** (`export_presets.cfg` → `[preset.1]`),
   que gera `C:\Lucifer_Game_Build\Lucifer.exe` + `Lucifer.pck` (PCK separado).
   Automático (também compila o instalador se o Inno Setup já estiver instalado):
   ```powershell
   powershell -ExecutionPolicy Bypass -File build_instalador.ps1
   ```
   Ou manual:
   ```powershell
   godot --headless --path . --export-release "Windows Instalador" C:/Lucifer_Game_Build/Lucifer.exe
   ```
3. **Compile o instalador** — o script já vem pronto e comentado no projeto
   (`setup_lucifer.iss`): abra-o no Inno Setup Compiler e tecle **Ctrl+F9**
   (Build → Compile), ou via linha de comando:
   ```powershell
   & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup_lucifer.iss
   ```
4. O instalador final é salvo em `C:\Lucifer_Game_Installer\Setup_ARCANJO_CAIDO_v1.0.0.exe`.

O que o instalador faz: instala em `C:\Program Files\ARCANJO CAIDO`, cria atalho
no Menu Iniciar (+ desinstalador), atalho opcional na Área de Trabalho (desmarcado
por padrão), wizard em português e opção de executar o jogo ao concluir. O
desinstalador **não apaga** os saves/conquistas (ficam em `user://` → AppData).

### Teste final do instalador
- [ ] Instalar em uma pasta/máquina **diferente** e jogar a partir do atalho
- [ ] Verificar criação em `C:\Program Files\ARCANJO CAIDO` e atalhos
- [ ] Desinstalar e confirmar que a pasta é removida (saves em AppData permanecem)

---

## 5. Distribuição

### Itch.io (via butler)
```powershell
butler push dist/ARCANJO_CAIDO_v1.0.0.zip SEU-USUARIO/arcanjo-caido:windows
```
Ou upload manual do `.zip` na página do jogo (*This file will be played in the browser? → No, Windows*).

### Steam (SteamPipe)
1. No **Steamworks**, crie o app e um depot Windows
2. Descompacte o `.zip` em uma pasta de conteúdo
3. Suba com o `steamcmd` usando um `app_build_<appid>.vdf` apontando para a pasta
4. Ícones de loja/cápsula são gerenciados no Steamworks (o ícone do executável já vem do `icon.svg`)

### Checklist de lançamento
- [ ] Rodar o jogo a partir do `.zip` baixado em **outra máquina sem Godot**
- [ ] Saves/conquistas/configurações gravando em `user://` (100% offline — já auditado no Passo 21)
- [ ] Dev Menu **não** abre com F1 na build release
- [ ] Créditos exibindo o texto de `assets/text/credits.txt`
- [ ] Áudio BGM/SFX/AMB funcionando nos dois alto-falantes
