# ⚖️ BALANCEAMENTO — Referência de Valores (v1)

Todos os valores abaixo são `@export` e podem ser ajustados no Inspetor do
Godot sem tocar em código. Use esta tabela como referência ao equilibrar.

## 🧝 Lúcifer (player_controller.gd)

| Parâmetro | Valor | Nota |
|---|---|---|
| max_speed | 320 px/s | corrida |
| acceleration / friction | 2600 / 3400 | chão; ar usa 1800/900 |
| jump_force | -720 | ~200px de altura |
| gravity / fall multiplier | 2000 / 1.35 | queda mais rápida que subida |
| max_jumps | 1 (2 com Asas Caídas) | |
| dash_speed / duration / cooldown | 700 / 0.18s / 0.45s | i-frames durante |
| max_health | 5 (+1 Sigilo Coração) | |
| attack_damage | 1 | ground pound causa 2 |
| chama_por_golpe | **12** ⚖️ | cura custa 33 ≈ 3 golpes |
| heal_cost / channel | 33 / 0.8s | |
| pogo_force | -560 | |
| iframes_duration | 1.0s | |

## 👹 Inimigos (enemy_base.gd — padrões)

| Parâmetro | Guardião Caído | Espectro do Jardim |
|---|---|---|
| max_hp | 20 | 20 |
| move_speed / chase | 90 / 190 | voador: flutuação + 150 de chase |
| detection_radius | **260** ⚖️ | 230 (herdado) |
| attack_windup | **0.35s** ⚖️ | contato contínuo |
| attack_damage | 1 | 1 (por contato) |
| knockback recebido | 240 | 240 |
| loot | 4 Pratas | 3 Pratas (padrão) |

## 👑 Mammon, o Ingestionável (mammon_boss.gd)

| Parâmetro | Valor | Nota |
|---|---|---|
| max_hp | **80** ⚖️ | ~27 golpes / 13 pogos; Fase 2 aos 40 HP |
| contact_damage | 1 | Fase 2, por toque |
| charge_speed / duration | 720 / 0.45s | investida |
| drain_rate / delay | 25/s após 0.8s parado | dreno de Chama |
| padrões Fase 1 | braços (2.2s) ↔ chuva de moedas (6x) | alternados |
| padrões Fase 2 | investida / 8 lingotes / braços | aleatório a cada ~1.1-2.4s |

## 💰 Economia

| Fonte | Pratas |
|---|---|
| Guardião Caído | 4 |
| Espectro do Jardim | 3 |
| Mammon | 15 (chuva na morte) |
| Sigilo | 40-50 ◇ |
| Mapa da Cassandra | 30 ◇ |
| Bênção (cura 2) | 15 ◇ |

**Regra de bolso:** um ciclo Corredor↔Cripta (2 Guardiões + coleta) rende ~10 ◇;
o jogador deve conseguir o mapa após ~3-4 min de exploração de combate.

## 🧭 Diretrizes de ajuste

1. **Dificuldade do chefe**: ajuste `max_hp` do Mammon na cena (não no script).
2. **Feel do combate**: mexa primeiro em `attack_windup` dos inimigos (telegraph
   mais longo = mais justo), depois em HP.
3. **Economia**: se a progressão estiver lenta, aumente `loot_amount` dos
   inimigos antes de mexer nos preços das lojas.
4. **Nunca ajuste** `Engine.time_scale` (hit stop) — ele é global e sensível.
