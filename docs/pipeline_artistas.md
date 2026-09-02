# Pipeline de Arte — Arcanjos Caídos
## Guia Técnico para Estilo Legend of Mana + Hollow Knight

---

## 1. Especificações Técnicas de Exportação

### Resolução e Atlas
- **Resolução base do jogo**: 1920x1080 (viewport interno escala para 1280x720)
- **Sprites de personagem**: 64x64 pixels por frame (quadro-a-quadro)
- **Tiles de cenário**: 32x32 ou 64x64 pixels
- **Atlas de sprites**: Máximo 2048x2048 (use TexturePacker ou similar)
- **Backgrounds**: 1920x1080 mínimo, preferencialmente 3840x2160 para paralaxe

### Formatos de Arquivo
- **Arte final**: PNG (lossless) com canal alpha
- **Normal Maps**: PNG 8-bit RGB (formato OpenGL: X+, Y+, Z+)
- **LUTs de correção de cor**: PNG 256x16 ou 1024x32

---

## 2. Taxas de Quadro para Animações

| Tipo de Animação | FPS | Frames Mínimos |
|------------------|-----|----------------|
| Idle personagem | 8-12 | 4-6 |
| Walk/Run personagem | 12 | 6-8 |
| Ataque | 15-20 | 4-6 |
| VFX (partículas) | 20-30 | 8-12 |
| Background parallax | Estático | 1 |
| Vegetação (wind shader) | Shader-based | N/A |

---

## 3. Paleta de Cores

### Tema Ciano (Mágica/Bioluminescente)
```
Primária:    #00E6FF (0, 0.9, 1.0)
Secundária:  #0088AA
Destaque:    #80FFFF
Sombra:      #003344
```

### Tema Dourado (Sagrado/Fogo)
```
Primária:    #FFB347 (1.0, 0.7, 0.2)
Secundária:  #CC7700
Destaque:    #FFE066
Sombra:      #553300
```

### Tema Corrupção (Magenta/Violeta)
```
Primária:    #E63399 (0.9, 0.2, 0.6)
Secundária:  #9933CC
Destaque:    #FF80FF
Sombra:      #330033
```

### Tema Natureza (Legend of Mana)
```
Folha:       #44AA66
Casca:       #8B6914
Flor:        #FFB7C5
Água:        #2288AA
```

### Tema Caverna (Hollow Knight)
```
Pedra:       #333842
Musgo:       #3A5F3A
Fungo:       #6644AA
Abismo:      #0A0A0F
```

---

## 4. Criação de Normal Maps

### Ferramentas Recomendadas
1. **GIMP** + plugin Normal Map
2. **Photoshop** (Filter > 3D > Generate Normal Map)
3. **CrazyBager** (standalone)
4. **Online**: https://cpetry.github.io/NormalMap-Online/

### Configurações de Exportação
- **Formato**: OpenGL (não DirectX!)
- **Força**: 2.0-4.0 para pedra, 0.5-1.0 para tecido
- **Suavização**: 1-2 pixels
- **Canal Alpha**: Não necessário

### Nomenclatura
- `pedra_parede.png` → `pedra_parede_normal.png`
- `grama.png` → `grama_normal.png`

---

## 5. Organização de Assets

```
assets/
├── art/
│   ├── characters/
│   │   ├── lucifer/
│   │   │   ├── lucifer_sheet.png
│   │   │   ├── lucifer_sheet_normal.png
│   │   │   └── lucifer_roughness.png
│   │   └── enemies/
│   ├── tiles/
│   │   ├── pedra/
│   │   │   ├── pedra_parede.png
│   │   │   └── pedra_parede_normal.png
│   │   └── madeira/
│   ├── backgrounds/
│   │   ├── jardim_adonai/
│   │   │   ├── bg_sky.png
│   │   │   ├── bg_mountains_far.png
│   │   │   ├── bg_mountains_near.png
│   │   │   ├── bg_forest_far.png
│   │   │   ├── bg_forest_near.png
│   │   │   ├── bg_details.png
│   │   │   └── bg_foreground.png
│   │   └── ...
│   └── fx/
│       ├── particles/
│       └── shaders/
├── shaders/
│   ├── wet_floor.gdshader
│   ├── wind_vegetation.gdshader
│   └── god_rays.gdshader
└── textures/
    ├── normal_maps/
    └── luts/
```

---

## 6. Shaders Disponíveis

| Shader | Uso | Performance |
|--------|-----|-------------|
| `wet_floor.gdshader` | Chão reflexivo | Médio |
| `wind_vegetation.gdshader` | Vegetação animada | Baixo |
| `god_rays.gdshader` | Raios volumétricos | Baixo |

---

## 7. Checklist de Entrega

- [ ] Sprites exportados em PNG com alpha
- [ ] Normal maps em formato OpenGL
- [ ] Nomenclatura consistente
- [ ] Atlas dentro do limite de 2048x2048
- [ ] Animações com FPS correto
- [ ] Paleta de cores aprovada
- [ ] Testado no Godot 4.7+