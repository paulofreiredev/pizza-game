# Arquitetura

O jogo usa Flutter, com regras independentes da interface e desenhos de cozinha feitos em Canvas.

## Organização

- `lib/game/game_state.dart`: etapas, receitas, pedidos, avaliações, saldo, compras e equipamentos. Valores monetários são inteiros em centavos; a apresentação usa vírgula decimal.
- `lib/game/assisted_actions.dart`: posições de cobertura com distribuição irregular e espaçamento; linhas de corte assistidas.
- `lib/main.dart`: navegação, catálogo, loja, integração de áudio, carregamento e fila de salvamento.
- `lib/ui/natural_kitchen.dart`: gestos, animações, dicas e coordenação do preparo.
- `lib/ui/kitchen_painter.dart`: bancada, ingredientes, forno, cortes e personalização do cenário.
- `lib/ui/prepared_ingredient_bowl.dart`: potes com porções soltas e sobrepostas, compartilhados entre montagem e transferência após o corte.
- `lib/ui/shop_product_preview.dart`: miniaturas e prévias ampliadas que reutilizam os desenhos da cozinha, com confirmação da compra.
- `lib/ui/recipe_intro_dialog.dart`: apresentação da receita, com fotografia própria para cada receita.
- `lib/ui/ready_pizza_photo.dart`: recorte das imagens prontas compartilhado pelo forno, corte e entrega. As imagens são carregadas para a receita atual e liberadas quando a cozinha é fechada.
- `lib/ui/pizza_box_scene.dart` e `celebration_overlay.dart`: entrega e recompensa.
- `lib/services/game_storage.dart`: banco SQLite e transações de salvamento.
- `lib/services/game_audio.dart`: música e efeitos.

## Persistência

O banco `pizza_game.db` fica no diretório de suporte da aplicação. Usa `sqflite` no Android/iOS/macOS e `sqflite_common_ffi` no Linux/Windows, conforme o suporte descrito na [documentação Flutter](https://docs.flutter.dev/app-architecture/design-patterns/sql).

Uma transação grava as tabelas `saved_game` (estado completo), `wallet` (saldo em centavos) e `purchased_recipes` (receitas pagas adquiridas). O estado completo inclui cosméticos comprados, seleção por categoria, avaliações, preparo e áudio. A fila evita gravações concorrentes da interface; uma compra só é confirmada após persistir a dedução e a propriedade. Falhas restauram o estado anterior da compra.

O carregamento prioriza SQLite. Se o banco ainda não tiver estado, importa o salvamento anterior de SharedPreferences e converte valores monetários inteiros antigos para centavos. SharedPreferences fica apenas como fonte de migração. Falhas de carregamento impedem compras para preservar o saldo existente.

## Regras de progressão

Três receitas são gratuitas. Receitas simples adicionais custam 199,00 moedas e especiais custam 399,00. Pedidos pagam 29,29 ou 49,90, conforme a receita; estrelas avaliam o preparo separadamente. O modo livre não altera saldo ou avaliação. Jogar sorteia uma receita disponível e abre sua apresentação, sem lista de fases. O próximo pedido evita repetir o sabor anterior.

Cosméticos têm categorias independentes: toalha, saleiro, forno e planta. Comprar um item não remove os equipamentos das outras categorias. Coberturas têm quantidades máximas por ingrediente e por pedido; posições assistidas mantêm espaço, com queijo como base e camadas de cobertura. A mistura responde ao movimento da colher; despejos de ingredientes têm animações próprias. A antiga etapa de sova é ignorada inclusive ao restaurar sessões.

## Testes

`test/game_state_test.dart` cobre regras e economia; `test/game_storage_test.dart` usa um arquivo SQLite temporário; `test/assisted_actions_test.dart` verifica geometria e espaçamento. Os testes de widgets usam armazenamento em memória injetado, mantendo o teste de persistência separado dos gestos e da navegação.
