# Pizza Game

Jogo cozy em Flutter para Android e Linux. Prepare pizzas doces e salgadas com gestos de mouse/toque, seguindo pedidos no seu ritmo.

## Primeira versão

- Menu com ilustração original, configurações de áudio e créditos.
- Apresentação de cada receita com nome e imagem antes de começar; retomadas entram direto no preparo.
- Nove pedidos, três sabores (marguerita, calabresa e chocolate com morango) e modo livre.
- Ingredientes, mistura, sova, rolo, corte de calabresa/cebola, base, montagem, forno e corte da pizza.
- Bancada visual: potes arrastáveis, colher e rolo acompanhando o dedo, dicas animadas e avanço automático.
- Até três estrelas por entrega, moedas e loja de toalhas cosméticas.
- Salvamento local de sessão, progresso, compras e volume.
- Música e efeitos fornecidos pelo usuário. Consulte `ASSETS.md`.

## Executar

O Flutter está em `/home/paulo/flutter`. O PATH foi acrescentado a `~/.bashrc`; em terminais já abertos, use o caminho absoluto ou abra outro terminal.

```bash
flutter pub get
flutter devices
flutter run -d emulator-5554
flutter run -d linux
```

No Android Studio, abra esta pasta como projeto Flutter. O emulador configurado é `Medium_Phone`.

Para compilar no Linux são necessários os pacotes:

```bash
sudo apt-get install -y ninja-build libgtk-3-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

## Controles

Arraste os potes para a tigela. Pegue a colher ou o rolo e deslize o utensílio sobre o alimento; sove diretamente com o dedo. A mão animada demonstra cada gesto. Um deslize curto inicia um corte assistido e reto na parte que sobra. Apenas um ingrediente inteiro ocupa a tábua; suas fatias caem e são recolhidas para um pote antes de entrar o próximo. Espalhe a base com a colher e arraste os potes sobre a pizza para distribuir coberturas; o jogo organiza as porções uniformemente mesmo com gestos imprecisos, e queijo aparece ralado em fios. Quando terminar, arraste a pizza ao pequeno forno ilustrado. No forno grande, arraste a pizza para dentro, toque no puxador para fechar, aguarde o preparo, abra e arraste até o prato. Faça cortes entre bordas opostas com o cortador. O chef coloca a pizza na caixa, a tampa fecha e aparecem confetes e o toast de moedas. As palmas duram três segundos. Música continua em loop nas telas, pausas e entregas, até o jogador desativar.

Uma entrega rende 20 moedas mais 10 por estrela. Cada nova repetição de pedido rende moedas, mas reabrir o mesmo resultado não credita novamente. Melhor avaliação fica salva; qualquer entrega libera o pedido seguinte. Modo livre não dá notas, moedas ou desbloqueios. Ingredientes são sempre gratuitos.

## Validar e compilar

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build linux
```

O APK debug fica em `build/app/outputs/flutter-apk/app-debug.apk`. Para instalar no celular, use `flutter build apk --release` e copie `build/app/outputs/flutter-apk/app-release.apk`. O bundle Linux fica em `build/linux/x64/release/bundle/`.

Validação realizada: `flutter analyze` sem problemas, dezesseis testes aprovados e APK debug gerado, instalado e aberto no emulador Android. O APK debug usado no emulador contém arquitetura x86_64; o comando release acima gera o pacote para as arquiteturas Android suportadas pelo projeto. A versão Linux ainda não foi compilada por ausência das bibliotecas listadas acima.

## Organização

- `lib/game/game_state.dart`: regras, pedidos, progresso, avaliações e cosméticos.
- `lib/main.dart`: navegação, sessão, gestos e integração de persistência.
- `lib/ui/kitchen_painter.dart`: desenho da bancada.
- `lib/services/game_audio.dart`: trilha contínua e efeitos.
- `TASKS.md`: backlog e critérios de aceite.

Esta é a primeira implementação. As interações e a arte estão em refinamento; a loja inicial oferece toalhas. A opção de tela cheia desktop e a expansão para pratos/utensílios permanecem no backlog. A validação de um destino exige executar o build nesse ambiente.
