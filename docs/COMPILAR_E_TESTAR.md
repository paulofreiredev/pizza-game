# Compilar e testar

Instale o Flutter na versão compatível com o SDK indicado em `pubspec.yaml`, o Android SDK e um JDK compatível com o Gradle do projeto. Confira o ambiente com `flutter doctor`.

## Preparar e executar

```bash
flutter pub get
flutter devices
flutter run -d emulator-5554
# Ou no desktop:
flutter run -d linux
```

Para abrir um emulador configurado:

```bash
flutter emulators
flutter emulators --launch Medium_Phone
```

No Linux, instale as ferramentas de compilação e bibliotecas nativas:

```bash
sudo apt-get install ninja-build libgtk-3-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

## Verificar

```bash
flutter analyze
flutter test
```

Os testes cobrem regras de preparo, recompensas com centavos, compras e bloqueio de receitas, equipamentos independentes, limites e espaçamento das coberturas, controles, renderização do molho e persistência real em SQLite, incluindo reabertura e rollback de transação.

## Gerar e instalar

```bash
flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release
flutter build linux
```

APKs: `build/app/outputs/flutter-apk/`. Executável Linux e bibliotecas: `build/linux/x64/release/bundle/`.

## Conferência manual

1. Em uma instalação nova, confirme três receitas disponíveis e saldo zero.
2. Entregue pedidos simples: cada um rende 29,29 moedas, creditadas uma única vez por preparo.
3. Acumule moedas repetindo pedidos; compre frango ou mista por 199,00, ou uma receita especial por 399,00. Pedidos especiais rendem 49,90.
4. Compre e equipe saleiro, forno, toalha e planta; confirme que aparecem juntos no cenário.
5. Feche e reabra o jogo: saldo, compras, equipamentos e preparo devem continuar salvos.
6. Segure e mova a ferramenta durante um corte; confira os potes cheios após a transferência e o limite das coberturas.

O modo livre não concede moedas ou estrelas. Para verificar a migração, atualize uma instalação com o salvamento antigo: moedas inteiras são convertidas para centavos uma única vez, e o progresso é copiado para SQLite.
