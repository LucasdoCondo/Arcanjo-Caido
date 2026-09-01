# 📖 LORE — ARCANJO CAIDO (Bíblia do Mundo v1)

Consolidação da história, atos, regiões, chefes, NPCs e finais — baseada nos
documentos de design do projeto. Tudo aqui é canônico para o conteúdo implementado.

---

## 1. Premissa & Universo

Após a **Terceira Guerra Celestial**, Lúcifer e sua legião não caíram em um
abismo de fogo, mas em **Aeterna, o Vazio Primordial** — o Limbo Cósmico onde a
Terra e os reinos espirituais ruíram. O impacto estilhaçou o tecido da
realidade, arrastando pedaços da Terra histórica, artefatos profanos e ruínas
de civilizações antigas para o mesmo lugar.

Lúcifer acorda **sem memória e sem asas radiantes**, trajando uma armadura de
ferro negro carcomida e portando a **Lâmina do Alvorecer quebrada**. Sua
legião de um terço dos anjos foi dispersa e deformada pelo Vazio.

**Pergunta central:** *A queda foi traição... ou uma libertação? E se Lúcifer
puder escolher de novo?* As Memórias Fragmentadas espalhadas pelo mapa
revelam a verdade do Ato III: **a Queda foi orquestrada por Mammon**.

## 2. Ato Principal (progressão da campanha)

| Ato | Faixa | Resumo |
|---|---|---|
| **I — A Queda e o Despertar** | 0–20h | Lúcifer desperta na Cripta. O Vazio se espalha e apaga a existência; os portões arcanos exigem essência vital dos caídos. |
| **II — Os Príncipes Desgovernan** | 20–55h | Caça aos três Grandes Selos, atravessando biomas dominados por entidades bíblicas e pagãs que escravizam os anjos sobreviventes. |
| **III — A Revelação da Mentira** | 55–75h | As memórias revelam que a Queda foi negociada por Mammon para absorver a luz dos anjos e se tornar o novo Deus do Limbo. |
| **IV — O Trono do Abismo** | 75–80h+ | Investida final na Catedral da Avareza: Belzebuth antes do confronto supremo contra Mammon. |

## 3. As 6 Regiões de Aeterna (mapa completo planejado)

| # | Região | Tema visual | Chefe regional | Habilidade desbloqueada |
|---|---|---|---|---|
| 1 | Cripta das Estrelas Caídas | Ruínas celestiais, cristais, poeira estelar | **Semyaza, o Primeiro Desertor** | Passo das Sombras (Dash) |
| 2 | Floresta dos Esquecidos | Pântano, névoa espessa, templos pagãos | **Baphomet, a Sombra dos Cornos** | Garra do Abismo (Wall Jump) |
| 3 | Abismo de Mercúrio | Cavernas industriais, rios de metal líquido | **Leviatã das Profundezas** | Resistência Química (nadar no mercúrio) |
| 4 | Jardins de Babilônia | Palácios flutuantes, vegetação corrompida | **Lilith, a Primeira Exilada** | Asas Caídas (Pulo Duplo) |
| 5 | Vale da Geena | Deserto de cinzas, lava estagnada, ossos gigantes | **Moloch, o Devorador** | Macho de Ferro (Ground Pound) |
| 6 | Catedral da Avareza | Gótico opulento de ouro escurecido e vitrais de sangue | **Belzebuth** (pré) & **Mammon** (final) | Chave do Trono Primordial |

> **Salas já implementadas no protótipo:** Cripta, Corredor das Cinzas,
> Jardim de Adonai-Gal e Mar de Vidro (biomas-protótipo), Catedral.
> As demais regiões do mapa planejado reutilizam `Room` + `EnemyBase`.

## 4. Chefes — Fases e Padrões (design de combate)

### 🩸 Lilith, a Primeira Exilada (Jardins de Babilônia)
Agilidade extrema, ilusões e magia de sangue.
- **Fase 1 — A Doutrinadora:** *Dança das Lâminas* (teleporta acima e lança 3
  adagas em leque); *Investida Sombra* (dash pela arena com rastro cortante).
- **Fase 2 — A Rainha das Ilusões (50%):** *Espelho de Sangue* (duas cópias
  ilusórias de dano reduzido — só a original sofre dano real); *Chuva de Rosas
  Espinhosas* (vinhas escurecem a arena, reduzindo o espaço seguro).

### 🦠 Belzebuth, o Senhor da Pestilência (pré-chefe final)
Alta velocidade, mudança de terreno e hordas de projéteis.
- **Fase 1 — Guerreiro Decadente:** *Lança de Enxame* (golpes frontais com
  lança de insetos); *Erupção Praga* (gêiseres de ácido na arena).
- **Fase 2 — Forma Insetóide (40%):** perde as pernas, ganha asas carcomidas e
  voa; *Nuvem de Devoradores* (insetos perseguidores — destrua ou esquive com
  o Passo das Sombras).

### 👑 Mammon, o Ingestionável (chefe final) — **JÁ IMPLEMENTADO**
Colossal, lento, dano devastador e mecânica de ganância.
- **Fase 1 — O Rei de Ouro:** fundido ao trono; punhos gigantes + chuva de
  moedas incandescentes.
- **Fase 2 — Avatar da Avareza (50%):** o trono desmorona; *Chuva da Avareza*
  (lingotes que exigem pulo duplo no timing); *Dreno de Almas* (suga a Chama
  Negra de quem fica parado perto demais).

## 5. NPCs, Lojas e Quests

| NPC | Papel | Status |
|---|---|---|
| **Cassandra, a Cartógrafa Cega** | Vende mapas inacabados; a pena-guia desenha os caminhos | ✅ implementada |
| **Mormo, o Encantador de Relíquias** | Vende Sigilos do Banimento por Pratas de Judas | ✅ implementado |
| **Azazel, o Anjo Acorrentado** | Quest trágica: morte misericordiosa vs. insanidade | ✅ implementado |
| **Charon, o Mercador Itinerante** | Navega pelos rios: consumíveis, mapas de segredos, chaves | 📋 planejado |
| **Memórias Fragmentadas** | Lore do Ato III (a negociação da Queda) | ✅ 3 implementadas |

## 6. Finais Múltiplos

1. **Final Padrão — "Soberano do Vazio"**: derrote Mammon e reivindique o trono.
2. **Final Verdadeiro — "A Verdadeira Libertação"** (100% + quests completas):
   recuse o trono, destrua o tecido de Aeterna e liberte todas as almas do Limbo.

## 7. Conquistas (conforme GDD)

- 🥉 **O Primeiro Tombo** — desperte na Cripta
- 🥈 **Luz Ressoante** — 12 fragmentos da Lâmina do Alvorecer
- 🥈 **Misericórdia ou Maldição?** — quest de Azazel
- 🥇 **Mestre das Relíquias** — todos os Sigilos do Banimento
- 🥇 **Soberano do Vazio** — derrote Mammon e reivindique o Trono
- 💎 **A Verdadeira Libertação** — Final Verdadeiro (100%)

## 8. Combat Design — Recursos e Sinergias

- **Lâmina do Alvorecer**: ataque 3 direções + **Pogo Strike**.
- **Chama Negra**: energia por golpe acertado → Cura Interna canalizada.
- **Postura Parry** ✅: bloqueio no timing exato reflete golpes, staggera
  inimigos e freeze-frames o impacto.
- **Mobilidade por chefes**: Dash → Wall Jump → Resistência → Pulo Duplo →
  Ground Pound — libera **backtracking** (a "Luz Residual" do design).
- **Sigilos do Banimento** (mudam o estilo de jogo):
  - *Lâmina Longa*: alcance +35%
  - *Coração Extra*: +1 de vida
  - *Chama Rápida*: Chama +40% por golpe
  - *Sigilo de Azazel*: alcance +25%, drena vida por golpe
  - *Selo da Serpente*: o Dash envenena inimigos
  - *Marca de Mammon*: +50% de Pratas, mas inimigos causam dano dobrado


