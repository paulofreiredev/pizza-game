# Backlog — Pizza Game

Status: versão 1.1.2 (build 4) compilada, instalada e iniciada no emulador Android para avaliação do usuário. Análise estática sem problemas e dezesseis testes aprovados, incluindo preparo completo por gestos, operação do forno, cortes entre bordas e embalagem automática com recompensa. Flutter instalado em `/home/paulo/flutter`; projeto Android/Linux criado. Build desktop será feito após a aprovação do usuário, conforme combinado.

## Implementação atual e próximos ajustes

Já existem menu com arte original gerada, nove pedidos, três receitas, modo livre, potes arrastáveis, utensílios que acompanham o dedo, etapas automáticas, dicas visuais animadas, forno com porta animada e transporte direto da pizza, avaliação, moedas, loja inicial de toalhas e salvamento local. Morangos têm formato, folhas e sementes; queijo é ralado; fatias de calabresa caem com animação. Após o corte, o chef coloca a pizza numa caixa, fecha a tampa e aparecem confetes e toast com a recompensa real. As palmas fornecidas pelo usuário foram copiadas de Downloads e reduzidas a três segundos, preservando o original. Música roda continuamente em loop, inclusive nas pausas e entregas, até ser desativada nas configurações.

As caixas abaixo continuam como critérios de entrega, não apenas de existência do código. Ainda faltam avaliação visual do usuário na versão 1.1, build Linux após sua aprovação, tela cheia desktop e expansão dos cosméticos para pratos/utensílios. Revisão da nova interação foi realizada pelo agente reviewer com acesso ao código; corrigidos tutorial de corte, cálculo da direção dos cortes e dica de espalhar base. Os testes antigos baseados em botões foram substituídos por gestos reais.

## Ajustes aprovados durante a avaliação

- [x] Popup antes de iniciar/repetir/próximo pedido com nome da pizza, imagem própria de cada sabor e botão grande de play. Cancelar preserva a sessão e continuar preparo não repete a apresentação.

- [x] Gestos infantis assistidos: cortes retos automáticos após deslize curto, sempre no restante do ingrediente; sem exigir precisão na fatia pequena.
- [x] Ingredientes derrubados perto da massa se acomodam em posições uniformes dentro da pizza.
- [x] Calabresa e cebola têm formato inteiro natural antes do corte; uma por vez na tábua e recolhimento animado para potes abaixo.
- [x] Molho permanece no centro da massa, sem disco amarelo artificial que o esconda nas etapas seguintes.

- [x] Interface de preparo pictórica, com potes arrastáveis e interação direta nos utensílios; sem botões de próxima etapa ou toque guiado.
- [x] Colher e rolo acompanham o dedo; colher não gira automaticamente.
- [x] Corte com ferramenta em movimento e fatias que se separam, caem e pousam.
- [x] Morangos reconhecíveis e queijo ralado, com espalhamento contínuo de ingredientes.
- [x] Porta do forno, entrada e retirada da pizza animadas.
- [x] Chef coloca pizza na caixa e fecha a tampa após cortar.
- [x] Confetes, toast de moedas reais e palmas de três segundos.
- [x] Música contínua, com opção explícita para desativar.
- [ ] Avaliar esta versão no emulador e incorporar o retorno do usuário.
- [ ] Após aprovação, compilar e validar a versão desktop.

## Direção do produto

Criar o **Pizza Game**, um jogo Flutter para Android e desktop, começando pelo Linux, com pizzas doces e salgadas. Catálogo inicial proposto: chocolate com morango, marguerita e calabresa. Oferecer campanha de nove fases com pedidos de clientes e modo livre sem avaliação. O jogador prepara a pizza com calma, seguindo instruções visuais em português, sem cronômetro punitivo.

Referências em `exemplo/`: tela inicial com pizza em destaque; caderno de seleção de etapas; bancada vista de cima com madeira alaranjada, toalha xadrez azul, tigela central e ingredientes à direita. Produzir identidade e arte próprias inspiradas nessa composição.

Fluxo inicial: menu → seleção de pizza → caderno da receita → ingredientes da massa → misturar e sovar → abrir massa → cortar ingredientes → espalhar base → distribuir coberturas → colocar no forno → assar → retirar → cortar pizza → servir. O caderno apresenta as etapas aplicáveis a cada receita, incluindo o preparo dos ingredientes. Base e ingredientes variam conforme a receita: chocolate e frutas nas doces; molho, queijo e demais ingredientes nas salgadas.

A experiência cozy de cozinhar é requisito central: o jogador corta a cebola e a calabresa na tábua, trabalha a massa, espalha molho ou chocolate, coloca as coberturas e conduz a pizza até o forno. Cada ação deve alterar visualmente o alimento e responder ao gesto com animação e som. Os ingredientes entram inteiros no preparo e suas porções cortadas são usadas na montagem. Oferecer gestos por toque e mouse, além de alternativa acessível por toques/cliques guiados, mantendo o ritmo tranquilo.

## Fluxo de trabalho dos agentes

- **Desenvolvedor:** implementar uma tarefa por vez, registrar arquivos afetados e validação realizada.
- **Refinador:** avaliar legibilidade, composição, animações, instruções e interação em toque e mouse; devolver ajustes concretos ao desenvolvedor.
- **Code reviewer:** revisar regras de progressão, estado, recursos, persistência e compatibilidade; apontar problemas com prioridade e reprodução.
- Concluir cada marco após corrigir problemas impeditivos encontrados no refinamento e na revisão. Não marcar builds ou testes como aprovados sem executá-los.

## Marco 1 — ambiente e fundação

- [ ] **T01 — Preparar Flutter e destinos.** Finalizar instalação, verificar `flutter doctor -v`, localizar SDK Android/emulador e dependências de build Linux. Registrar pendências reais. Aceite: Flutter executa e os destinos disponíveis são identificados.
- [ ] **T02 — Criar projeto Flutter.** Gerar plataformas Android e Linux; organizar apresentação, estado da receita e desenho da bancada sem acoplar regras aos widgets. Aceite: aplicativo básico abre no Linux e no Android quando o emulador estiver disponível.
- [ ] **T03 — Definir sistema visual e layout.** Paleta quente, xadrez azul, botões arredondados, tipografia legível e bancada central. Priorizar paisagem; adaptar janelas menores e orientação retrato sem cortes nem controles inacessíveis. Aceite: áreas de toque confortáveis, textos legíveis e desenho alinhado à área interativa após redimensionar.

## Marco 2 — primeira sessão jogável

- [ ] **T04 — Menu, seleção de pizza e configurações.** Exibir Pizza Game, pizza em destaque, Jogar (campanha ou modo livre), Continuar quando houver sessão salva, Configurações, Créditos e Sair no desktop. Configurações incluem volumes separados de música/efeitos e tela cheia no desktop. Aceite: navegar por toque e mouse, identificar sabores e retomar o modo/pedido correto. Integrar acesso à decoração em T24.
- [ ] **T05 — Catálogo, estado da receita e caderno.** Modelar receitas por dados: identificador, nome, base, ingredientes, ações de preparo e instruções. Gerar etapas aplicáveis à receita, incluindo corte de ingredientes e operações do forno, sem fixar quantidade de cartões ou chocolate na lógica. Liberar a próxima apenas ao concluir a anterior; permitir retomar a etapa atual e iniciar nova receita. Aceite: bloqueios consistentes, sem avanço por cliques repetidos; trocar de receita não carrega ingredientes da anterior.
- [ ] **T06 — Ingredientes, mistura e sova.** Adicionar ingredientes à tigela com clique/toque e arrasto opcional; misturar com gesto circular e sovar com movimentos guiados. Mostrar ingredientes se incorporando e massa mudando de textura. Definir quantidades e sequência de uma receita lúdica. Aceite: cada ingrediente é contabilizado uma vez, largar fora da tigela não progride, gestos produzem mudanças graduais e há indicação clara do próximo passo.
- [ ] **T07 — Abrir a massa.** Interagir com rolo para transformar a massa em disco, com progresso visível e alternativa simples por cliques/toques. Aceite: gestos equivalentes com mouse e toque; conclusão determinística.
- [ ] **T07A — Cortar cebola e calabresa.** Apresentar ingredientes inteiros na tábua e faca com cortes guiados por arrasto, com alternativa por clique/toque. Animar fatias de calabresa e porções de cebola se separando a cada corte válido; armazenar as porções para montar a pizza. Aceite: corte fora do ingrediente não conta, a mesma linha não conta duas vezes, som acompanha cada corte válido e conclusão exige preparar os ingredientes previstos pela receita. Não repetir corte em receitas que não usam esses ingredientes.
- [ ] **T08 — Espalhar a base da receita.** Pintar chocolate ou molho sobre a massa com movimento do utensílio. Aceite: base corresponde à receita, fica dentro do disco, progresso considera área realmente coberta e uma região repetida não permite concluir sozinha.
- [ ] **T09 — Adicionar coberturas doces e salgadas.** Oferecer os ingredientes da receita escolhida, como morango e chocolate, queijo e manjericão ou as porções de calabresa e cebola preparadas em T07A. Distribuir manualmente sobre a massa com arrasto ou seleção seguida de toque/clique. Aceite: peças ficam na pizza, há limite de objetos, cada colocação tem feedback e é possível desfazer ou limpar antes de continuar; cada sabor tem aparência própria e a receita de calabresa utiliza o resultado do corte.
- [ ] **T10 — Colocar no forno, assar e retirar.** Permitir abrir o forno, conduzir a pizza com a pá até a área interna, fechar, acompanhar uma animação curta de cozimento e retirar a pizza pronta. Oferecer alternativa guiada por clique/toque para o transporte. Aceite: só assa com a pizza dentro e porta fechada, largar fora não inicia preparo, não duplica pizza nem temporizador, a pausa suspende o cozimento e a retirada libera o corte. Mostrar mudança gradual de aparência sem punição por demora.
- [ ] **T11 — Cortar e servir.** Guiar cortes e apresentar a pizza pronta com feedback acolhedor. Aceite: cortes já feitos não contam novamente; é possível voltar ao menu ou reiniciar com estado limpo.

## Marco 3 — atmosfera e continuidade

- [ ] **T12 — Música de fundo fornecida pelo usuário.** Usar `assets/sound/608624__bloodpixelhero__marvelous-gift.wav` como trilha do Pizza Game desde o menu e durante o preparo; verificar duração/tamanho e escolher reprodução compatível com Android e Linux. Aceite: loop sem sobreposição ou reinício ao trocar de tela, volume ajustável, opção de silenciar e pausa ao aplicativo perder atividade. Preservar arquivo original se for necessário gerar versão comprimida.
- [ ] **T13 — Efeitos e animações.** Adicionar feedback de ingredientes, mistura, cobertura, forno e conclusão; priorizar arte desenhada no Flutter para a primeira versão. Aceite: resposta imediata às ações e distinção entre controles de música e efeitos. Buscar sons/imagens externos apenas quando necessários, registrando origem, autor e licença em `ASSETS.md`; conferir a licença da música fornecida antes de distribuir.
- [ ] **T13A — Integrar os dois efeitos fornecidos pelo usuário.** Usar `assets/sound/490114__manuelaurreaf__cutting-fabric.wav` para cortar cebola e calabresa e `assets/sound/840679__snap2__sand-in-a-bag.m4a` para preparar/trabalhar a massa e espalhar molho ou chocolate. Verificar reprodução do M4A no Android e Linux; se necessário gerar uma versão compatível preservando o original. Aceite: corte toca por ação válida; som de fricção acompanha somente o gesto ativo, para ao soltar/pausar/trocar de etapa e não cria reprodução ilimitada por evento de movimento. Efeitos respeitam volume próprio e convivem com a música de fundo.
- [ ] **T14 — Salvar progresso e preferências.** Persistir modo, fase/pedido, identificador da receita, etapa concluída, porções cortadas, coberturas e estado válido do forno quando necessário, além das configurações de áudio. Incluir fases liberadas, melhores avaliações, saldo, entregas já recompensadas, itens comprados e decoração equipada ao integrar T20–T24. Aceite: reabrir restaura a pizza correta sem duplicar porções, moedas ou compras; dados ausentes/inválidos usam defaults e nova receita limpa somente a sessão de preparo.
- [ ] **T15 — Tutorial contextual e pausa.** Dicas curtas em português, indicação do gesto esperado e botão para repetir instruções. Pausa oferece Retomar, Recomeçar receita, Configurações e Voltar ao menu. Aceite: cada etapa é compreensível sem conhecer o jogo de referência; voltar ao menu preserva sessão e reiniciar limpa o preparo sem alterar moedas, compras ou melhores avaliações.

## Marco 3B — clientes, fases e recompensas

- [ ] **T20 — Campanha de nove fases.** Criar mapa/caderno de fases com pedido, progresso e melhor resultado. Cada fase contém uma receita completa, e não apenas um gesto. Fases 1–3 ensinam os três sabores; 4–6 introduzem preferências de quantidade; 7–9 combinam preferências e apresentação usando os mesmos ingredientes. Aceite: concluir uma entrega libera a fase seguinte com qualquer avaliação, fases anteriores podem ser repetidas e todas as nove são concluíveis sem compras.
- [ ] **T21 — Clientes e pedidos.** Atender um cliente por vez com nome, retrato, fala curta e ficha do pedido consultável durante o preparo. Modelar receita e preferências quantitativas por dados, com alvos/tolerâncias explícitos. Aceite: instruções como bastante cebola ou poucos morangos correspondem aos critérios da avaliação; não há fila, abandono nem penalidade por demora.
- [ ] **T22 — Avaliação acolhedora.** Entregar de 1 a 3 estrelas, reação do cliente e explicação dos critérios: atendimento ao pedido, distribuição da cobertura e cozimento. Definir fórmula e tolerâncias antes de implementar, sem usar velocidade de gestos ou tempo total. Aceite: mesma pizza gera mesma nota, dicas explicam como melhorar, melhor resultado por fase nunca diminui e entrega imperfeita não exige repetir para avançar. O forno continua sem queimar por demora; avaliar se o cozimento guiado foi concluído.
- [ ] **T23 — Moedas por entrega.** Definir tabela simples de recompensa base mais bônus por estrelas. Repetir fases rende moedas; cada nova sessão concluída é uma nova entrega. Aceite: crédito ocorre exatamente uma vez por entrega, inclusive ao reabrir a tela de resultado ou restaurar sessão; nunca descontar moedas por erros ou cobrar ingredientes básicos. Exibir saldo e valor recebido.
- [ ] **T24 — Loja de decoração.** Criar catálogo inicial de decorações da cozinha, pratos e aparências de utensílios, com preço, prévia e equipar itens adquiridos. Aceite: compra exige saldo suficiente, débito e aquisição são salvos juntos, item comprado não é cobrado novamente e cosméticos não afetam avaliação nem bloqueiam receitas. Sem dinheiro real.
- [ ] **T25 — Modo livre.** Permitir escolher qualquer um dos três sabores e usar o mesmo preparo interativo sem pedido nem avaliação. Aceite: disponíveis desde o começo, receitas não dependem da campanha ou loja; modo livre não altera melhores notas, desbloqueios ou saldo e apresenta a pizza pronta sem estrelas.

### Roteiro inicial das nove fases

| Fase | Pedido | Introdução |
| --- | --- | --- |
| 1 | Marguerita tradicional | Tutorial de massa, molho, montagem e forno |
| 2 | Calabresa com cebola | Tutorial de corte e uso das porções |
| 3 | Chocolate com morango | Tutorial da base doce e decoração |
| 4 | Marguerita com bastante manjericão | Preferência de quantidade |
| 5 | Calabresa com bastante cebola | Aplicar preferência após cortar |
| 6 | Chocolate com poucos morangos | Montagem com quantidade reduzida |
| 7 | Marguerita com cobertura bem distribuída | Apresentação e distribuição |
| 8 | Calabresa com pouca cebola e fatias bem distribuídas | Combinar quantidade e distribuição |
| 9 | Chocolate com morangos bem distribuídos e confeitos | Final especial com apresentação |

Definir números e tolerâncias por pedido em T21; pedidos especiais reutilizam ingredientes e mecânicas já ensinados. A dificuldade aumenta pela variedade do preparo, sem pressão de tempo.

## Marco 4 — refinamento, revisão e entrega

- [ ] **T16 — Refinar visual e usabilidade.** Agente refinador compara o resultado às referências e verifica hierarquia, contraste, escala, transições e áreas de interação. Aceite: corrigir sobreposições, instruções ambíguas e desalinhamentos entre desenho e toque.
- [ ] **T17 — Revisar implementação.** Code reviewer avalia transições, cliques duplicados, ciclo de vida, descarte de áudio/animações, persistência, avaliação determinística, crédito único por entrega, compras e dependências de plataforma. Aceite: problemas impeditivos corrigidos e limitações restantes documentadas.
- [ ] **T18 — Validar regras e fluxo.** Executar análise estática e testes úteis para progressão, reinício, cobertura, cortes de ingredientes e pizza, transporte/estado do forno e restauração. Verificar manualmente fluxo completo com mouse e toque, redimensionamento, pausa/retomada e áudio. Aceite: concluir uma receita salgada cortando cebola e calabresa, espalhando molho, colocando coberturas e operando o forno; concluir também uma doce. Registrar resultados sem afirmar cobertura de dispositivos indisponíveis.
- [ ] **T19 — Gerar builds e instruções.** Produzir APK de teste e build Linux no ambiente disponível; documentar execução, requisitos e localização dos artefatos em `README.md`. Aceite: abrir os builds e concluir uma receita em cada plataforma disponível; registrar impedimentos das demais.
- [ ] **T26 — Validar progressão e economia.** Testar desbloqueio das nove fases, limites da avaliação, manutenção da melhor nota, repetição remunerada, retomada sem crédito duplicado e compra/equipamento com saldo insuficiente ou item já adquirido. Aceite: campanha completa acessível sem compras; modo livre não altera economia; salvar/reabrir mantém resultados, saldo e decoração consistentes.

## Ordem e escopo

Executar T01–T05 primeiro; entregar um trecho jogável com T06 antes de expandir as demais etapas. Integrar T12 cedo para validar áudio nas duas plataformas. Após o preparo completo, implementar T20–T25 e integrar sua persistência em T14. Executar T26 antes dos builds finais de T19. Fazer refinamento e revisão a cada marco, além da passagem final T16–T17.

A primeira versão inclui três sabores, nove fases com clientes e pedidos, avaliações de até três estrelas, moedas, loja cosmética e modo livre. Implementar primeiro uma receita de ponta a ponta, depois ampliar para as demais e integrar a progressão. Multiplayer e publicação em lojas ficam fora deste marco inicial. Windows/macOS podem ser preparados depois; seus builds exigem ambientes próprios.

## Decisões e pendências

- Stack definida: Flutter; Linux como primeiro desktop, Android como destino móvel.
- Android Studio e emulador estão sendo configurados pelo usuário.
- Confirmar a licença/origem da música fornecida antes da distribuição; isso não impede desenvolver o jogo.
- Nome definido pelo usuário: **Pizza Game**.
- Música de fundo definida pelo usuário: arquivo WAV já presente em `assets/sound/`.
- Efeitos de corte e areia recebidos em `assets/sound/`: `490114__manuelaurreaf__cutting-fabric.wav` e `840679__snap2__sand-in-a-bag.m4a`. Arquivos localizados; reprodução ainda não validada.
- Preparo manual cozy obrigatório: cortar cebola/calabresa, trabalhar massa, espalhar base, distribuir ingredientes e colocar/retirar pizza do forno.
- Os sabores chocolate com morango, marguerita e calabresa são uma proposta inicial; o catálogo deve permitir acrescentar receitas sem duplicar o fluxo.
