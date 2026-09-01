# ARCANJO CAIDO

Metroidvania 2D offline estilo Hollow Knight, protagonizado por **Lúcifer** no
**Aeterna, o Vazio Primordial** — o Limbo Cósmico onde a Terra e os reinos
espirituais ruíram após a Queda.

## Engine
- **Godot 4.x** (GDScript) — renderer compatível com 2D

## Estrutura do Projeto
```
ARCANJO CAIDO/
├── project.godot              # Configuração + Input Map + 9 autoloads
├── export_presets.cfg         # Preset de build Windows offline
├── data/dialogs.json          # Falas/ramificações dos NPCs
├── docs/BALANCEAMENTO.md      # Referência de valores ajustáveis
├── assets/art/                # Sprite sheets e artes (SVG)
├── scenes/                    # player, test, enemies, bosses, npcs, world, biomas, ui
└── scripts/                   # player, enemies, bosses, npcs, world, core, ui
```

## Controles (Passos 1–2)
| Ação | Teclas |
|---|---|
| Mover | `A`/`D` ou `←`/`→` |
| Pular (altura variável) | `Espaço` ou `Z` |
| Dash de Sombra (com i-frames) | `Shift` ou `X` |
| Atacar (frente / cima / baixo) | `J` (+ `W`/`↑` ou `S`/`↓` no ar) |
| Pogo Strike | `S`/`↓` + `J` no ar, sobre inimigos ou espinhos |
| Cura canalizada (Chama Negra) | Segurar `F` no chão |
| Mapa de Aeterna (pausa) | `M` ou `Tab` |
| Marcar/desmarcar sala no mapa | `E` (com o mapa aberto) |
| Interagir (portas que exigem interação / NPCs) | `E` |
| Pausar (Sigilos, Mapa, Conquistas, Salvar, Opções) | `Esc` ou `P` |
| Avançar diálogos | `E` / `Espaço` / `Enter` (escolhas com o mouse) |
| **Postura Parry** (reflexo perfeito) | `Q` no timing do golpe inimigo |

**Habilidades de exploração (Passo 8 — desbloqueadas pelas Relíquias douradas no Corredor das Cinzas):**
| Habilidade | Como usar |
|---|---|
| 🪜 Garra do Abismo (wall jump) | Encoste numa parede caindo, segure o direcional dela → desliza; `Espaço` salta da parede |
| 🪽 Asas Caídas (pulo duplo) | `Espaço`/`Z` novamente no ar (com jato de fumaça dourada) |
| 🔨 Macho de Ferro (ground pound) | No ar: `S`/`↓` + `Shift`/`X` → despencada com onda de choque; quebra pisos rachados |
| 🕸️ Sombra de Voo (gancho) | No ar: `C` perto de um Nó de Energia (ciano) → é projetado até ele |

## Roadmap de Implementação
- [x] **Passo 1** — PlayerController com FSM (Idle, Walk, Jump, Fall, Dash, Attack), pulo variável, coyote time, jump buffer, Dash de Sombra
- [x] **Passo 2** — Combate: Lâmina do Alvorecer (3 direções), Pogo Strike, Chama Negra + cura canalizada, dano/knockback/i-frames
- [x] **Passo 3** — EnemyBase + Guardião Caído (IA de patrulha/perseguição/ataque, loot das Pratas de Judas com magnetismo)
- [x] **Passo 4** — Save/Load offline (JSON) + Pontos de Descanso + respawn *(ver linhas abaixo: concluído em duas etapas)*
- [x] **Passo 5** — Diálogos modulares (JSON, ramificações, typewriter) para NPCs
- [x] **Passo 6** — Conquistas offline + Sigilos do Banimento
- [x] **Passo 7** — Transição de salas com fade (estado preservado via GameState) + Mapa com fog of war estilo Cassandra (`M`), ícones de banco/NPC, marcadores (`E`)
- [x] **Passo 8** — Habilidades de exploração: Garra do Abismo (wall slide/jump), Asas Caídas (pulo duplo + FX), Macho de Ferro (ground pound + quebra de piso rachado) e Sombra de Voo (gancho em Nós de Energia), com Relíquias de desbloqueio
- [x] **Passo 9** — Mammon, o Ingestionável: Fase 1 no trono (braços/ondas de choque + chuva de moedas), transição aos 50%, Fase 2 móvel (investidas, lingotes, Dreno de Almas) + barra de vida dedicada
- [x] **Passo 10** — HUD (máscaras, Chama Negra, Pratas de Judas), Menu de Pause com 4 abas + 3 Save Slots locais, Menu Principal (Novo Jogo / Carregar / Sair) como main scene
- [x] **Passo 11** — AudioManager: buses Music/SFX/Ambience, crossfade entre trilhas por região/arena de chefe, SFX e trilhas sintetizados em tempo real (100% offline, sem assets externos) com triggers automáticos
- [x] **Passo 12** — Atmosfera: iluminação 2D (aura do Lúcifer, tochas com flicker, CanvasModulate por sala), partículas (Dash, aterrissagem, explosão de moedas) e Parallax em camadas automático
- [x] **Passo 13** — Game Juice: hit stop global nos impactos, camera shake proporcional nos ataques do chefe e câmera com look-ahead suavizado
- [x] **Passo 14** — Otimização (culling de inimigos fora de visão), DisplayManager (fullscreen/borda/resoluções com F11, configurações persistidas) e `export_presets.cfg` para build Windows
- [x] **Passo 4 (final)** — Estátuas de Descanso (cura + Chama + salva no Slot 1) e respawn no último descanso ao morrer
- [x] **Passo 5** — Diálogos modulares (JSON ramificado + typewriter + pausa), NPCs: Cassandra (vende o mapa), Mormo (loja de Sigilos/bênções) e quest do Azazel com escolha moral
- [x] **Passo 6** — Conquistas offline + Sigilos do Banimento equipáveis (inventário no pause, modificadores em tempo real)
- [x] **Passo 15** — Bloom + color grading por bioma, sombras dinâmicas (LightOccluder2D), normal maps (FxUtil), vinheta e névoa volumétrica (shaders), Postura Parry, 3 Sigilos da lore (Azazel/Serpente/Mammon), Memórias Fragmentadas e `docs/LORE.md`
- [x] **Conteúdo v1** — Sprite sheets + AnimationPlayer (Lúcifer 6 anims, Guardião 4 frames, Mammon), biomas novos (Jardim de Adonai-Gal com Espectros voadores + Mar de Vidro) e `docs/BALANCEAMENTO.md`

## 🗺️ Mundo (Salas conectadas)

```
[Cripta das Estrelas Caídas] ── [Corredor das Cinzas] ── [Catedral da Avareza (BOSS)]
    2 células · banco · Mormo        │ 1 célula · banco      1 célula · Mammon
                                     ├── [Jardim de Adonai-Gal] ── [Mar de Vidro]
                                        2 células · Espectros       1 célula · espinhos
```

- **Cripta das Estrelas Caídas**: Guardiões, dummy de treino, espinhos, Mormo (loja)
- **Corredor das Cinzas**: relíquias de habilidades, nós de gancho, pisos rachados, Cassandra + Azazel
- **Jardim de Adonai-Gal**: bioma verde, **Espectros voadores** (perseguição aérea em 2D)
- **Mar de Vidro**: bioma gélido, Guardiões + campos de espinhos
- **Catedral da Avareza**: arena do chefe final

## 🎨 Arte e Animações

- **Lúcifer**: sprite sheet de 10 frames (`assets/art/lucifer_sheet.svg`) com
  `AnimationPlayer` (`idle`, `walk`, `jump`, `fall`, `dash`, `attack`) dirigido pela FSM
- **Guardião Caído**: sheet de 4 frames (patrulha/telegraph/ferido)
- **Mammon**: arte própria do trono/avatar (tint de fase na transição)
- Tudo em SVG placeholder — substituível por pixel art sem mudar código

## ⚖️ Balanceamento

Veja `docs/BALANCEAMENTO.md` para a tabela completa de valores ajustáveis
(pelo Inspetor, sem código) e diretrizes de ajuste.

## 🌌 Iluminação e Pós-Processamento (Passo 15)

- **Bloom (glow)**: ativado por sala via `WorldEnvironment` (`hdr_2d` habilitado) —
  chamas, olhos de chefes e a Chama Negra brilham na tela
- **Color grading por bioma**: Cripta fria/azulada (saturação 0.9), Catedral
  dourada (saturação 1.15 + brilho 1.05), Jardim fresco, Mar gelado
- **Sombras dinâmicas**: `LightOccluder2D` gerado automaticamente em todas as
  plataformas/sólidos + no corpo do Lúcifer; as tochas projetam sombras reais
- **Normal maps**: pipeline pronto via `FxUtil.apply_flat_normal()` — troque a
  textura neutra por normal maps reais gerados no Aseprite/Krita quando a arte
  final chegar
- **Vinheta e névoa**: shaders em `shaders/vignette.gdshader` e
  `shaders/fog.gdshader` (névoa de duas camadas em movimento lento)

## 📖 Lore

A bíblia do mundo completa (atos, 6 regiões planejadas, fases de Lilith e
Belzebuth, NPCs, finais e conquistas) está em `docs/LORE.md`.

## Como Abrir
1. Instale o **Godot 4.2+** (https://godotengine.org/download)
2. Abra o Godot → **Import** → selecione a pasta `ARCANJO CAIDO`
3. Pressione `F5` — o jogo abre no **Menu Principal** ("Novo Jogo" inicia na Cripta das Estrelas Caídas)

## Persistência Offline (onde os dados são gravados)
Todos os dados ficam estritamente em `user://` (local, sem rede):
- `user://save_slot_0..2.json` — os 3 Save Slots
- `user://achievements.json` — conquistas desbloqueadas
- `user://settings.json` — vídeo (tela/resolução) e volumes de áudio

## Build para Distribuição (Windows)
1. Baixe os **Export Templates** em `Editor → Manage Export Templates` (mesma versão do Godot)
2. `Project → Export...` → o preset **"Windows Offline"** já está configurado (`export_presets.cfg`)
3. Clique em **Export Project** → gera `build/ARCANJO_CAIDO.exe` (com PCK embutido, jogo 100% offline)
4. Alternativa por linha de comando:
   ```
   godot --headless --path "ARCANJO CAIDO" --export-release "Windows Offline" build/ARCANJO_CAIDO.exe
   ```
