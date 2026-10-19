# Assets do Pizza Game

## Sons fornecidos pelo usuário

| Uso | Arquivo original | Autor / origem | Licença |
| --- | --- | --- | --- |
| Música de fundo | `assets/sound/608624__bloodpixelhero__marvelous-gift.wav` | BloodPixelHero, Marvelous Gift; [Freesound](https://freesound.org/people/BloodPixelHero/sounds/608624/) | A confirmar na página original |
| Cortar cebola e calabresa | `assets/sound/490114__manuelaurreaf__cutting-fabric.wav` | manuelaurreaf, cutting fabric; [Freesound](https://freesound.org/people/manuelaurreaf/sounds/490114/) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), verificada na página do som |
| Comemoração (3 s) | `assets/sound/397434__foolboymedia__crowd-cheer.wav` | FoolBoy Media, Crowd Cheer; [Freesound](https://freesound.org/people/FoolBoyMedia/sounds/397434/) | A confirmar na página original |
| Trabalhar massa e espalhar base | `assets/sound/840679__snap2__sand-in-a-bag.m4a` | Snap2, Sand in a Bag; [Freesound](https://freesound.org/people/Snap2/sounds/840679/) | A confirmar na página original |

| Porta do forno fechando | `assets/sound/400686__supersnd__microwave-door-close.wav` | supersnd; fornecido pelo usuário | A confirmar na página original |
| Pizza pronta ao terminar o forno | `assets/sound/815147__annabax01q__tiiin-sfx.m4a` | annabax01q; fornecido pelo usuário | A confirmar na página original |

Os arquivos originais foram preservados. `background.wav` é uma versão PCM estéreo a 22050 Hz da música original; `sand.wav` é a conversão PCM mono a 44100 Hz do M4A. `celebration.wav` contém somente os primeiros três segundos das palmas, com fade out nos últimos 0,3 s. As conversões foram geradas com FFmpeg para reprodução nos destinos do aplicativo. Os efeitos foram associados a ações lúdicas de cozinha.

## Arte

- `assets/images/kitchen-scene-v2.png`: cenário sem plantas ou enfeites embutidos, para que as decorações apareçam exclusivamente nas prateleiras. Prompt em `docs/kitchen-scene-clean-art-prompt.txt`.
- `assets/images/pizza-bases.png`: massa crua e molhos de tomate e chocolate com textura fotográfica, usados durante o preparo e no forno. Prompt em `docs/pizza-bases-art-prompt.txt`.
- `assets/images/ovens.png`: fornos com materiais realistas nas versões padrão, rosada e cobre, usados na loja e no jogo. Prompt em `docs/oven-art-prompt.txt`. As três artes foram geradas com a ferramenta integrada image_gen.

- `assets/images/pizza-materials.png`: atlas transparente com porções realistas dos ingredientes, massa e recipientes do preparo, gerado com image_gen. Usado nos potes, na montagem e no transporte da pizza. Prompt em `docs/pizza-materials-art-prompt.txt`.

- `assets/images/seasonings.png`: atlas transparente de saleiros e potes de temperos em cerâmica, vidro, madeira e aço, com materiais realistas, gerado pela ferramenta integrada image_gen. Prompt em `docs/seasoning-art-prompt.txt`.

- `assets/images/kitchen-scene.png`: versão inicial do cenário, preservada como referência para `kitchen-scene-v2.png`, que é usada pela home e pelo preparo. Gerada com a ferramenta integrada image_gen.
- `assets/images/plants.png`: atlas transparente de samambaia e flores, com folhagem e vasos mais realistas, gerado com a ferramenta integrada image_gen. Usado na loja, na prateleira e na cozinha. Prompts completos das duas artes em `docs/kitchen-scene-art-prompts.txt`.

- `assets/images/recipes/frango.png`, `mista.png`, `carne_de_sol.png`, `quatro_queijos.png`, `camarao.png` e `frango_catupiri.png`: fotografias sintéticas originais geradas com a ferramenta integrada image_gen. Prompts completos em `docs/recipe-art-prompts-expanded.txt`.

- `assets/images/recipes/margherita.png`, `calabresa.png` e `chocolate.png`: fotografias sintéticas originais geradas pela ferramenta integrada image_gen para o popup de apresentação de receitas. Prompts completos em `docs/recipe-art-prompts.txt`.

- `assets/images/kitchen-menu.png`: ilustração original gerada com a ferramenta integrada de geração de imagens, usada como fundo do menu. Prompt registrado em `docs/menu-art-prompt.txt`.
- `lib/ui/kitchen_painter.dart`: arte original desenhada por código Flutter para bancada, utensílios, ingredientes, pizza e forno.
- `exemplo/`: prints fornecidos pelo usuário como referência visual; não são empacotados como arte do jogo.
- Ícones Material fornecidos pelo Flutter.

As licenças ainda não confirmadas devem ser verificadas antes de distribuir publicamente o jogo.

- `assets/images/branding/calabresa-mark.png`: pizza isolada com transparência pela ferramenta integrada image_gen, baseada em `assets/images/recipes/calabresa.png`. Usada no carregamento Flutter e, em versões redimensionadas, no ícone Android e na splash nativa. Prompt em `docs/branding-art-prompt.txt`; variantes geradas por `tools/resize_android_branding.py`.
