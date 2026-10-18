# Assets do Pizza Game

## Sons fornecidos pelo usuário

| Uso | Arquivo original | Autor / origem | Licença |
| --- | --- | --- | --- |
| Música de fundo | `assets/sound/608624__bloodpixelhero__marvelous-gift.wav` | BloodPixelHero, Marvelous Gift; [Freesound](https://freesound.org/people/BloodPixelHero/sounds/608624/) | A confirmar na página original |
| Cortar cebola e calabresa | `assets/sound/490114__manuelaurreaf__cutting-fabric.wav` | manuelaurreaf, cutting fabric; [Freesound](https://freesound.org/people/manuelaurreaf/sounds/490114/) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), verificada na página do som |
| Comemoração (3 s) | `assets/sound/397434__foolboymedia__crowd-cheer.wav` | FoolBoy Media, Crowd Cheer; [Freesound](https://freesound.org/people/FoolBoyMedia/sounds/397434/) | A confirmar na página original |
| Trabalhar massa e espalhar base | `assets/sound/840679__snap2__sand-in-a-bag.m4a` | Snap2, Sand in a Bag; [Freesound](https://freesound.org/people/Snap2/sounds/840679/) | A confirmar na página original |

Os arquivos originais foram preservados. `background.wav` é uma versão PCM estéreo a 22050 Hz da música original; `sand.wav` é a conversão PCM mono a 44100 Hz do M4A. `celebration.wav` contém somente os primeiros três segundos das palmas, com fade out nos últimos 0,3 s. As conversões foram geradas com FFmpeg para reprodução nos destinos do aplicativo. Os efeitos foram associados a ações lúdicas de cozinha.

## Arte

- `assets/images/recipes/margherita.png`, `calabresa.png` e `chocolate.png`: fotografias sintéticas originais geradas pela ferramenta integrada image_gen para o popup de apresentação de receitas. Prompts completos em `docs/recipe-art-prompts.txt`.

- `assets/images/kitchen-menu.png`: ilustração original gerada com a ferramenta integrada de geração de imagens, usada como fundo do menu. Prompt registrado em `docs/menu-art-prompt.txt`.
- `lib/ui/kitchen_painter.dart`: arte original desenhada por código Flutter para bancada, utensílios, ingredientes, pizza e forno.
- `exemplo/`: prints fornecidos pelo usuário como referência visual; não são empacotados como arte do jogo.
- Ícones Material fornecidos pelo Flutter.

As licenças ainda não confirmadas devem ser verificadas antes de distribuir publicamente o jogo.
