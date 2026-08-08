# ROADMAP - Combix

Documento de planeamento do projeto Combix (Godot 4, GDScript).
Estado: ativo. Deve ser atualizado a cada entrada e saida de sub-fase e de grande
fase (ver secao "Processo de atualizacao" no final).

## 1. Grandes fases

O desenvolvimento esta organizado em quatro grandes fases:

| Fase | Nome | Estado |
|---|---|---|
| 1 | Alpha | Em curso (1.1, 1.2 e 1.3 concluidas; 1.4 em andamento) |
| 2 | Beta | Nao iniciada |
| 3 | Final | Nao iniciada |
| 4 | Lancamento | Nao iniciada |

Objetivos detalhados das fases 2, 3 e 4 ainda nao foram decididos. Este documento
nao inventa gameplay nao decidido: missoes, NPCs, veiculos, UI, audio, combate e
outros sistemas so entram no roadmap quando existir uma decisao registada.

## 2. Numeracao das sub-fases

Cada grande fase divide-se em sub-fases numeradas no formato <fase>.<sub-fase>:
1.1, 1.2, 1.3, 2.1, etc. Uma sub-fase termina quando os seus criterios de saida
estao cumpridos e o estado e confirmado. Ao iniciar uma sub-fase nova ou uma grande
fase nova, o utilizador deve ser avisado (regra de comunicacao do roadmap em
res://.summerrules).

## 3. Estado atual

- Alpha 1.1 "Base tecnica estavel": CONCLUIDA.
- Alpha 1.2 "Mapa estatico controlado": CONCLUIDA e confirmada pelo utilizador em Play.
- Alpha 1.3 "Edificios estaticos e colisoes simplificadas": CONCLUIDA e
  confirmada pelo utilizador. Seis edificios estaticos aplicados e confirmados
  (edificio 01 - hipermercado de res-do-chao, edificio 02 - residencial pequeno,
  edificio 03 - moradia geminada, edificio 04 - comercio local, edificio 05 -
  edificio comunitario e edificio 06 - armazem industrial); consolidacao das
  seis cenas como PackedScene sob Main/StaticBuildings, reparacao do parse de
  main.tscn e playtest manual pos-consolidacao confirmado como perfeito pelo
  utilizador; ver secao 6.
- Alpha 1.4 "Definicao do loop principal": EM ANDAMENTO; a decisao de design foi
  registada (RPG narrativo de mundo aberto com loop composto de exploracao
  urbana, investigacao, missoes/objetivos e sobrevivencia; ver secao 6.1) e o
  primeiro slice jogavel foi decidido pelo utilizador: exploracao urbana e
  descoberta de um unico local, com feedback claro e progresso minimo de
  descoberta (ver secao 6.1). O primeiro slice foi implementado e VALIDADO pelo
  utilizador em Play (ao entrar na Area3D do hipermercado, o HUD apareceu com
  'Local Descoberto: Apartamento do Setor 1' e permaneceu visivel; ver
  secao 6.1). A fundacao narrativa foi registada e clarificada (Corvax e o
  nome final do protagonista; equipa composta por companheiros recrutaveis;
  Iblis no Capitolio a guardar o Codificador Sagrado; escopo geografico total
  ainda em aberto entre apenas o Setor 1 e toda Washington DC; Corvax encontra
  a equipa, ganha experiencia e fica mais forte no Setor 1 antes de Iblis;
  hierarquia demoniaca do Setor 1 apenas planeada; contagens em aberto; ver
  secao 6.1); o primeiro slice permanece sem combate, demonios, companheiros ou
  missao neste momento. O slice de descoberta foi expandido para seis locais
  descobriveis (edificios 01 a 06) e a distancia de ativacao foi normalizada
  por fachada: implementado e verificado tecnicamente (seis BoxShape3D
  dedicadas pelo footprint real de cada edificio mais margem comum de 0.5
  unidades em X e Z; altura 0.8; ver secao 6.1); o playtest manual detalhado
  dos seis locais e a igualdade visual das distancias permanecem nao
  verificados manualmente (o utilizador respondeu apenas 'podemos continuar').
  A sub-fase Alpha 1.4 continua EM ANDAMENTO: falta escolher o proximo
  incremento do slice de descoberta.

## 4. Alpha 1.1 - Base tecnica estavel (concluida)

Escopo (o que foi implementado): cena principal estavel, jogador e camara, arranque
leve, GIS desacoplado do gameplay, BakedMap, linhas e juncoes da rede viaria,
fronteira do Setor 1 com colisao e toggles de visibilidade dos overlays.

Dependencias:
- Projeto Godot 4 base a funcionar.
- Decisao de escala registada: 1 unidade Godot = 45,0 metros reais
  (res://world_scale.gd e res://.summerrules).
- Dados GIS de origem disponiveis em res://gis/ (GeoJSON) e recursos baked (*.res).

Criterios de entrada (reconstruidos a partir do estado alcancado, porque a
documentacao foi criada depois de 1.1):
- Projeto abre e arranca na base tecnica sem erros observados.

Criterios de saida:
- Cena principal com jogador e camara funcionais.
- Arranque leve.
- GIS desacoplado do gameplay.
- BakedMap presente na cena.
- Linhas e juncoes (rede viaria) representadas.
- Fronteira do Setor 1 com colisao.
- Toggles de visibilidade dos overlays presentes.

Estado: concluida. Nao existe confirmacao formal separada registada para 1.1; a
base foi considerada estavel ao prosseguir para 1.2 (ver DEVELOPMENT_LOG).

## 5. Alpha 1.2 - Mapa estatico controlado (concluida e confirmada)

Escopo (o que foi implementado): BakedMap como fonte principal do mapa estatico,
linhas baked visiveis, arranque rapido, jogador e fronteira funcionais, overlays
GIS duplicados ocultos no runtime e fontes GIS preservadas.

Dependencias:
- Alpha 1.1 concluida.
- Recursos baked em res://gis/ (sector1_*.res).
- Decisao de usar BakedMap como fonte principal do mapa estatico.

Criterios de entrada:
- Criterios de saida de 1.1 cumpridos.

Criterios de saida:
- BakedMap e a fonte principal do mapa estatico.
- Linhas baked visiveis.
- Arranque rapido.
- Jogador funcional.
- Fronteira funcional (colisao ativa).
- Overlays GIS duplicados ocultos no runtime.
- Fontes GIS preservadas em res://gis/.

Estado: concluida e confirmada pelo utilizador em Play. Nota de honestidade: essa
confirmacao cobre os comportamentos listados acima naquela execucao; nao prova a
funcionalidade global (ver DEVELOPMENT_LOG).

## 6. Alpha 1.3 - Edificios estaticos e colisoes simplificadas (concluida e confirmada)

Escopo planeado (provisorio): edificios estaticos a partir dos footprints do Setor 1
e colisoes simplificadas. Os detalhes e criterios de saida devem ser definidos e
confirmados no inicio da sub-fase.

Dependencias:
- Alpha 1.2 concluida e confirmada.
- Dados de footprints disponiveis: res://gis/04_building_footprints_sector1.geojson
  e res://gis/sector1_building_footprints_batch.res.
- Decisoes de desempenho (colisao simplificada vs sem colisao) a confirmar.

Estado final (seis edificios estaticos aplicados e confirmados pelo utilizador; a
confirmacao cobre esta sub-fase, nao o jogo completo):
- Edificio 01 - hipermercado de res-do-chao:
  - Nova cena res://static_building_01_apartamento.tscn integrada na cena principal
    sob Main/StaticBuildings/StaticBuilding01_Apartamento, com MeshInstance3D e
    CollisionShape3D simples.
  - Confirmado pelo utilizador em Play: altura 4.5 m reais = 0.10 unidades, footprint
    1.19 x 1.43 unidades, jogador 1.7 m reais = 0.03778 unidades, proporcao de
    aproximadamente 37.8% considerada correta e colisao simples perfeita.
- Edificio 02 - residencial pequeno:
  - Nova cena res://static_building_02_residencial.tscn integrada na cena principal
    sob Main/StaticBuildings/StaticBuilding02_Residencial, com MeshInstance3D e
    CollisionShape3D simples.
  - Confirmado pelo utilizador: footprint herdado do marcador Placa_01, altura
    5.4 m reais = 0.12 unidades e colisao simples integrada.
- Edificio 03 - moradia geminada (townhouse):
  - Nova cena res://static_building_03_townhouse.tscn integrada na cena principal
    sob Main/StaticBuildings/StaticBuilding03_Townhouse, derivada do marcador
    Placa_06_Townhouse_Habitacao_Geminada_01, com MeshInstance3D e
    CollisionShape3D simples alinhados.
  - Confirmado pelo utilizador: footprint 0.29 x 0.71 unidades (12 x 30 m reais),
    altura 0.18 unidades = 8.1 m, colisao e resultado visual perfeitos.
  - Jogador colocado temporariamente perto do edificio em (-10, 0.021393, -2)
    para o teste.
- Edificio 04 - comercio local:
  - Nova cena res://static_building_04_comercio.tscn integrada na cena principal
    sob Main/StaticBuildings/StaticBuilding04_Comercio, derivada do marcador
    Placa_11_Comercio_Local_01, com MeshInstance3D e CollisionShape3D simples
    alinhados.
  - Confirmado pelo utilizador: footprint 0.59 x 0.71 unidades (25 x 30 m reais),
    altura 0.14 unidades = 6.3 m, colisao e resultado visual confirmados.
  - Jogador colocado temporariamente perto do edificio em (-10, 0.021393, 10)
    para o teste.
- Edificio 05 - edificio comunitario:
  - Nova cena res://static_building_05_comunitaria.tscn integrada na cena
    principal sob Main/StaticBuildings/StaticBuilding05_Comunitaria, derivada do
    marcador Placa_13_Comunitaria_01 em (0, 0, 12), com MeshInstance3D e
    CollisionShape3D simples alinhados.
  - Confirmado pelo utilizador: footprint 0.83 x 1.07 unidades, altura 0.16
    unidades, colisao e resultado visual confirmados.
  - Jogador colocado temporariamente perto do edificio em (3, 0.021393, 12) para
    o teste.
- Edificio 06 - armazem industrial:
  - Nova cena res://static_building_06_industrial.tscn integrada na cena
    principal sob Main/StaticBuildings/StaticBuilding06_Industrial, derivada do
    marcador Placa_15_Industrial_Armazem_Periferico em (10, 0, 12), com
    MeshInstance3D e CollisionShape3D simples alinhados.
  - Confirmado pelo utilizador: footprint 1.66 x 2.38 unidades (74.7 x 107.1 m
    reais), altura 0.22 unidades = 9.9 m, colisao e resultado visual confirmados
    como perfeitos, incluindo a base sem flicker.
  - Jogador corrigido para (8, 0.021393, 12.5), dentro do Setor 1 e perto do
    armazem, antes do teste.
- Correcao de flicker das bases (aplicada e confirmada pelo utilizador como
  perfeita): as bases dos dois edificios receberam um offset geometrico minimo de
  0.004 unidades para eliminar o flicker, sem alterar a escala horizontal nem a
  altura alvo de cada edificio.
- Correcao anti-flicker da base do armazem industrial: offset Y corrigido de
  0.111 para 0.114, seguindo a margem anti-flicker de 0.004 unidades; o utilizador
  confirmou a base sem flicker e a colisao como perfeitas.
- Camara ajustada: spring_length passou de 0.35 para 0.20; o utilizador aprovou o
  estado atual resultante.
- Jogador corrigido para (8, 0.021393, 12.5), dentro do Setor 1 e perto do
  armazem industrial, antes do teste; a configuracao normal de arranque/GIS
  permaneceu leve.
- BakedMap, volumes low-rise e footprints GIS continuam presentes como referencia;
  as fatias atuais nao substituem nem removem os overlays GIS.
- A tentativa de atualizacao automatica anterior foi bloqueada apenas porque os
  ficheiros de jogo estavam protegidos para o builder; este ROADMAP apenas regista o
  estado aplicado, sem alterar ficheiros de jogo.

Auditoria/consolidacao tecnica e reparacao do parse (implementado, verificado
tecnicamente e confirmado pelo utilizador no playtest pos-consolidacao):
- As seis cenas proprias foram consolidadas como PackedScene sob
  Main/StaticBuildings (StaticBuilding01_Apartamento a
  StaticBuilding06_Industrial); os edificios 01-03, antes com subresources
  inline, foram convertidos para PackedScene, alinhando-os com 04-06.
- O edificio 06 recebeu header com load_steps=4 e
  collision_layer=1/collision_mask=1, consistentes com os restantes edificios.
- As posicoes dos seis edificios foram preservadas na consolidacao (nenhum
  edificio foi reposicionado).
- A primeira gravacao da consolidacao deixou res://main.tscn invalido em disco
  com "Parse Error: Invalid parameter" na linha 774; a falha foi reparada
  adicionando load_steps=72 ao header e removendo unique_id das seis linhas de
  nodes com instance=ExtResource(...).
- Verificado tecnicamente: OpenScene recarregou a cena do disco, a arvore
  confirmou seis instancias com Mesh e Collision, os diagnostics especificos
  ficaram limpos e uma verificacao tecnica arrancou sem erros observados.
- Confirmado apos a consolidacao: playtest manual pos-consolidacao realizado
  pelo utilizador; o utilizador confirmou "tudo esta bem, vamos continuar" e o
  playtest foi considerado perfeito para o fecho. Essa confirmacao cobre o
  estado consolidado final das seis cenas PackedScene sob Main/StaticBuildings,
  a reparacao do parse e o arranque preservado; nao prova o jogo completo.

Decisao registada sobre os blockouts GIS (no fecho de Alpha 1.3):
- O GIS permanece como fonte de referencia/edicao e o runtime normal usa BakedMap
  (decisao herdada de Alpha 1.2); os blockouts GIS continuam disponiveis como
  referencia visual ate decisao visual posterior. Os overlays de
  GISOverlayRuntime nao foram alterados por esta sub-fase.

Limitacoes fora de Alpha 1.3 (registadas no fecho; nao bloqueiam a conclusao):
- Blockouts GIS continuam presentes na arvore como referencia visual; nao sao
  substituidos por esta sub-fase.
- Footprints GIS continuam sem colisoes de runtime por razoes de desempenho.
- O loop principal ainda nao esta decidido (ver secao 6.1).
- Arte final e conteudo do jogo ainda pendentes.
- Os restantes edificios estaticos do Setor 1 continuam por converter (planeado,
  fora desta sub-fase).

Criterios de entrada:
- 1.2 concluida; utilizador avisado e confirma o inicio de 1.3.

Criterios de saida (cumpridos e confirmados):
- Seis tipos estaticos confirmados pelo utilizador: edificio 01 - hipermercado
  de res-do-chao, edificio 02 - residencial pequeno, edificio 03 - moradia
  geminada, edificio 04 - comercio local, edificio 05 - edificio comunitario e
  edificio 06 - armazem industrial; cada um como cena PackedScene propria sob
  Main/StaticBuildings, com MeshInstance3D e CollisionShape3D simples alinhados.
- Colisoes simples dos seis edificios confirmadas; offsets anti-flicker das bases
  corrigidos e confirmados (margem de 0.004 unidades; offset Y do armazem em
  0.114).
- Consolidacao PackedScene implementada e verificada tecnicamente (cena
  recarregada do disco, seis instancias com Mesh e Collision, diagnostics limpos
  e arranque sem erros observados).
- Reparacao do parse de res://main.tscn aplicada (load_steps=72 no header e
  remocao de unique_id das instancias); a cena recarrega do disco.
- Jogador posicionado dentro do Setor 1 em (8, 0.021393, 12.5), perto do armazem
  industrial, para testes.
- Arranque leve preservado; BakedMap, linhas, fronteira e colisao da fronteira
  preservados.
- Playtest manual pos-consolidacao realizado pelo utilizador e confirmado como
  perfeito ("tudo esta bem, vamos continuar"); Alpha 1.3 e fechada com base
  nessa confirmacao, sem declarar o jogo completo.
- Decisao registada sobre os blockouts GIS (ver acima).

Proxima acao:
- Fecho documental de Alpha 1.3 concluido (esta atualizacao); commit de marco de
  fecho preparado na secao "Nota sobre commit de marco", a executar pelo
  coordenador/utilizador.
- Entrar em Alpha 1.4 "Definicao do loop principal" (ver secao 6.1): decidir e
  documentar o loop principal antes de qualquer gameplay; o loop ainda nao esta
  decidido e nao deve ser inventado.
- Converter os restantes edificios estaticos do Setor 1 (fora de Alpha 1.3;
  planeado, nao iniciado nesta tarefa).

Nota sobre commit de marco:
- A consolidacao PackedScene e a reparacao do parse foram consolidadas no commit
  local a98e604 ("Consolidate Alpha 1.3 building library"); o push automatico
  desse commit falhou anteriormente e o coordenador/utilizador deve verificar o
  estado do remoto apos esta atualizacao.
- Esta atualizacao documental (ROADMAP.md e DEVELOPMENT_LOG.md) fecha Alpha 1.3
  e prepara o commit de marco de fecho (ex.: "Marco: Alpha 1.3 concluida"), a
  executar pelo coordenador/utilizador.

Riscos:
- Muitos shapes de colisao podem degradar o desempenho; a decisao atual e que os
  footprints nao tem colisao por razoes de desempenho.
- Footprints reais podem conter geometrias complexas ou sobrepostas.

## 6.1. Alpha 1.4 - Definicao do loop principal (em andamento)

Escopo da sub-fase: registar a decisao de design e o loop principal do jogo,
definir o primeiro slice jogavel e validar esse primeiro slice. O primeiro
slice foi implementado numa tarefa de gameplay posterior a decisao documental e
esta validado pelo utilizador (ver 'Primeiro slice validado' abaixo); a
sub-fase continua em andamento ate o proximo incremento narrativo/jogavel ser
definido.

Decisao de design registada (visao, aprovada pelo utilizador no questionario da
sub-fase):
- Direcao: RPG narrativo de mundo aberto, inspirado numa Washington ficcional,
  combinando exploracao urbana, investigacao, missoes/objetivos e sobrevivencia.
- Loop composto (visao): explorar o mundo urbano -> investigar locais e pistas ->
  cumprir missoes/objetivos -> gerir a sobrevivencia; em liberdade de mundo
  aberto, com novas descobertas a abrir novos objetivos.
- Progressao composta (visao): descobertas e locais, objetivos concluidos,
  reputacao e relacoes, e mundo aberto livre.
- Papel profissional do personagem: deliberadamente EM ABERTO. O questionario
  recolheu opcoes (residente/cidadao, investigador, estafeta/entregador, agente
  de autoridade), mas o utilizador, quando clarificado, escolheu manter a
  estrutura de papeis em aberto; nenhuma profissao e escolhida nesta fase.

Fundacao narrativa registada e clarificada (decisoes confirmadas do utilizador;
nao implementada):
- Decidido: Corvax e o nome final do protagonista, soldado de elite da E.R.A.
  (Exercito da Resistencia Antidemonios); esta em Washington DC para reunir a
  sua equipa de soldados de elite, composta por companheiros recrutaveis; o
  objetivo final e derrotar Iblis no Capitolio (o local mais importante de
  Washington DC) e recuperar o Codificador Sagrado, guardado por Iblis; o Setor
  1 sera o inicio da jornada, onde Corvax tera de encontrar os elementos da sua
  equipa, ganhar experiencia e ficar mais forte antes de chegar a Iblis; a
  hierarquia demoniaca do Setor 1 fica apenas planeada por agora: um Demonio
  Boss do setor que serve Iblis, Demonios Mini-Boss subordinados a esse Boss,
  Demonios Elite subordinados a cada Mini-Boss e Demonios Soldado subordinados
  a cada Elite.
- Em aberto: o escopo geografico total do jogo ainda nao esta decidido (apenas
  o Setor 1 ou toda Washington DC); numero de Mini-Bosses, Elites e Soldados
  ainda nao decidido; nome da equipa de Corvax, numero e nomes dos companheiros
  recrutaveis, sistema de recrutamento, localizacao concreta do Boss do Setor,
  missoes, sistemas de combate e detalhes de experiencia/progressao nao
  inventados.
- Nao implementado: nenhum demonio (Boss, Mini-Boss, Elite ou Soldado), boss,
  combate, equipa, companheiro, recrutamento, experiencia, progressao, missao
  ou sistema de gameplay criado por estas decisoes; o primeiro slice continua
  sem combate, demonios, companheiros ou missao neste momento.

Decidido (primeiro slice jogavel, escolha do utilizador):
- Primeiro slice jogavel da Alpha 1.4: exploracao urbana e descoberta de um
  unico local. O nucleo a provar e: o jogador explora uma zona do Setor 1,
  chega a um local e recebe feedback claro de descoberta, com progresso minimo
  de descoberta.
- Fora do primeiro slice (nao inventado, nao incluido): profissao, investigacao,
  missoes/objetivos, sobrevivencia e qualquer outro sistema de gameplay,
  UI/HUD, sinais, inputs, assets ou cenas fora dos criados para o slice.
- Implementacao do primeiro slice: concluida e validada pelo utilizador em Play
  (ver 'Primeiro slice validado' abaixo).

Primeiro slice validado (explorar e descobrir um local):
- Implementado (aplicado): res://discovery_trigger.gd (trigger de descoberta),
  res://discovery_hud.gd (HUD de descoberta) e os nodos Main/DiscoveryTrigger
  (Area3D) e Main/DiscoveryHUD em res://main.tscn.
- Correcao tecnica aplicada: collision_mask=2 na Area3D do trigger para
  corresponder a camada do Player, e polling de get_overlapping_bodies()
  adicionado como fallback porque o sinal body_entered nao foi fiavel neste
  build.
- Confirmado pelo utilizador em Play: ao entrar na Area3D do hipermercado, o
  HUD apareceu com 'Local Descoberto: Apartamento do Setor 1' e a mensagem
  permaneceu visivel. Esta confirmacao cobre esse comportamento naquela
  execucao; nao prova o jogo completo.
- Nao verificado: investigacao, missoes, sobrevivencia, profissao, progressao
  ampla e save/load nao existem ainda; sao planeados e ficam fora deste slice.
- Estado do slice: CONCLUIDO e VALIDADO pelo utilizador dentro da sub-fase
  Alpha 1.4; a sub-fase Alpha 1.4 continua EM ANDAMENTO e nao e fechada por
  este slice.

Expansao dos locais descobriveis e normalizacao da distancia de ativacao
(implementado e verificado tecnicamente; playtest manual detalhado pendente):
- Contexto: o primeiro slice foi validado com um unico local descobrivel
  (Area3D do hipermercado); foram adicionados cinco locais descobriveis
  adicionais, totalizando seis (edificio 01 - hipermercado de res-do-chao,
  edificio 02 - residencial pequeno, edificio 03 - moradia geminada, edificio
  04 - comercio local, edificio 05 - edificio comunitario e edificio 06 -
  armazem industrial). O utilizador reportou que as distancias de ativacao
  variavam; a inspecao confirmou que todos partilhavam uma shape; o utilizador
  escolheu 'Igual a partir da fachada'.
- Aplicado (Main/DiscoveryTrigger em res://main.tscn): seis BoxShape3D
  dedicadas, dimensionadas pelo footprint real de cada edificio mais uma
  margem comum de 0.5 unidades em X e Z; altura 0.8; collision_mask=2, script,
  hud_path, polling, idempotencia e HUD acumulativo preservados.
- Jogador colocado perto do residencial e dentro do Setor 1 para o teste.
- Verificado tecnicamente: a verificacao tecnica arrancou sem erros observados
  e confirmou a descoberta do residencial.
- Nao verificado manualmente: o utilizador respondeu apenas 'podemos
  continuar', sem descrever o resultado dos seis testes; a igualdade visual
  das distancias de ativacao por fachada e o playtest detalhado dos seis
  locais permanecem por confirmar manualmente. Esta normalizacao NAO e
  marcada como confirmada visualmente pelo utilizador.
- Estado: implementado e verificado tecnicamente; confirmacao manual detalhada
  pendente. O slice de descoberta permanece dentro da sub-fase Alpha 1.4, que
  continua EM ANDAMENTO.

Nao decidido (permanece em aberto nesta sub-fase):
- Papel profissional concreto do personagem (nenhuma profissao escolhida).
- Proximo incremento do slice de descoberta da Alpha 1.4 (a escolher com o
  utilizador na proxima tarefa; nao inventado nesta tarefa). A expansao dos
  seis locais descobriveis e a normalizacao da distancia de ativacao foram
  implementadas e verificadas tecnicamente; o playtest manual detalhado dos
  seis locais ainda nao foi verificado.
- Escopo geografico total do jogo: ainda em aberto entre apenas o Setor 1 e
  toda Washington DC; o Capitolio e a localizacao narrativa de Iblis, mas o
  mapa total nao esta decidido.
- Contagens da hierarquia demoniaca do Setor 1: numero de Mini-Bosses, Elites e
  Soldados nao decidido (ver 'Fundacao narrativa registada e clarificada').
- Nome da equipa de Corvax, numero e nomes dos companheiros recrutaveis,
  sistema de recrutamento, localizacao concreta do Boss do Setor, missoes,
  sistemas de combate e detalhes de experiencia/progressao (nao inventados).
- Regras detalhadas de sobrevivencia (fome, saude, abrigo, clima, etc.).
- Faccoes e conteudo detalhado.

Nao implementado (fora desta tarefa de validacao documental):
- Nenhum sistema de gameplay alem do primeiro slice ja implementado e criado ou
  alterado por esta tarefa; apenas documentacao em res://ROADMAP.md,
  res://DEVELOPMENT_LOG.md e res://.summerrules.
- Investigacao, missoes, sobrevivencia, profissao, progressao ampla e save/load
  continuam fora deste slice e nao sao iniciados nesta tarefa.
- Demonios (Boss, Mini-Boss, Elite, Soldado), combate, equipa de Corvax,
  companheiros recrutaveis, recrutamento, experiencia, progressao e o objetivo
  final contra Iblis nao sao implementados; a fundacao narrativa registada e
  clarificada orienta fases futuras, sem gameplay nesta fase.

Posicao herdada do fecho de Alpha 1.3:
- O GIS permanece como fonte de referencia/edicao e o runtime normal usa
  BakedMap; os blockouts GIS ficam disponiveis como referencia visual ate
  decisao visual posterior.

Criterios de entrada (cumpridos):
- Alpha 1.3 concluida e confirmada pelo utilizador (fecho documental).
- Utilizador avisado da entrada na nova sub-fase (regra de comunicacao do
  roadmap em res://.summerrules) e respondeu ao questionario de direcao da
  Alpha 1.4.

Criterios de saida (para definir o primeiro slice jogavel; a sub-fase fecha
quando estes criterios estiverem cumpridos):
- Decisao de design registada no ROADMAP.md, no DEVELOPMENT_LOG.md e em
  res://.summerrules (esta atualizacao).
- Loop composto documentado (exploracao, investigacao, missoes/objetivos,
  sobrevivencia) como visao, sem gameplay implementado.
- Progressao composta documentada (descobertas/locais, objetivos, reputacao/
  relacoes, mundo aberto) como visao.
- Papel profissional do personagem mantido em aberto, sem escolha de profissao.
- Primeiro slice jogavel definido, documentado, aprovado e VALIDADO pelo
  utilizador: exploracao urbana e descoberta de um unico local, com feedback
  claro ao jogador e progresso minimo de descoberta; sem profissao,
  investigacao, missao ou sobrevivencia neste slice; a sub-fase Alpha 1.4
  continua em andamento (proximo incremento narrativo/jogavel nao definido).
- Confirmacao do utilizador do estado documental; commit de marco documental
  executado pelo coordenador/utilizador.

Proxima acao (apos esta atualizacao):
- Coordenador/utilizador executa o commit/push documental desta atualizacao
  (Git nao executado nesta tarefa); o estado Git local/remoto conhecido esta
  registado no DEVELOPMENT_LOG.
- Proxima tarefa da Alpha 1.4: escolher com o utilizador o proximo incremento
  do slice de descoberta (novo local, comportamento ou conteudo a provar), sem
  iniciar investigacao, missoes, sobrevivencia, profissao, progressao ampla,
  combate, demonios, companheiros, recrutamento nem save/load nesta tarefa;
  nenhum novo incremento e inventado nesta tarefa.
- Confirmar manualmente, quando o utilizador puder, o playtest detalhado dos
  seis locais descobriveis e a igualdade visual das distancias de ativacao por
  fachada (normalizacao implementada e verificada tecnicamente, nao confirmada
  visualmente).
- Manter profissao, investigacao, missoes, sobrevivencia, combate e demonios em
  aberto; nao entram neste incremento sem decisao do utilizador.
- Nao iniciar Alpha 1.5 nem qualquer nova sub-fase nesta tarefa.

## 7. Dependencias globais

- Dados GIS (res://gis/): GeoJSON de origem (boundary, roadway, footprints, quadras,
  corpos de agua) e recursos baked (*.res) gerados a partir deles.
- Regra de escala: 1 unidade Godot = 45,0 metros reais; fator de preservacao legado
  42,07 / 45,0 = 0,9348888889 para valores metricos antigos derivados de metros
  reais (res://world_scale.gd, res://.summerrules).
- Mundo: Washington ficcional inspirada na real; dados oficiais quando disponiveis,
  estimativas claramente identificadas quando nao existirem.
- Repositorio Git em main; o ultimo commit local conhecido e d44a024
  ("Define Alpha 1.4 open world RPG loop"), com o push falhado e o ramo ahead
  1 do remoto; existem alteracoes locais atuais em res://main.tscn (expansao
  dos seis locais descobriveis e normalizacao da distancia de ativacao) e
  res://discovery_hud.gd, alem desta atualizacao documental; o coordenador
  fara o commit depois desta atualizacao; estado detalhado no DEVELOPMENT_LOG
  (https://github.com/inigomaio/combix.git).

## 8. Riscos conhecidos

- Desempenho: footprints de edificios sem colisao por razoes de desempenho; volumes
  translucidos continuam blockout; datasets GeoJSON grandes (ex.:
  roadway_blockface.geojson ~29 MB) podem pesar na importacao/arranque.
- Geometria GIS: dados reais podem conter falhas, sobreposicoes ou simplificacoes
  que exigem tratamento manual.
- Escala: a conversao de 45,0 m/unidade tem de ser consistente; o fator legado
  aplica-se apenas a valores metricos antigos derivados de metros reais, nao a
  constantes arbitrarias de gameplay.
- Verificacao: confirmacoes em Play cobrem comportamentos especificos; nao provam
  desempenho continuo nem funcionalidade global. A consolidacao PackedScene foi
  verificada tecnicamente (cena recarregada do disco, diagnostics limpos e
  arranque sem erros observados) e o playtest manual pos-consolidacao foi
  realizado e confirmado pelo utilizador como perfeito; essa confirmacao cobre
  Alpha 1.3, nao o jogo completo.
- Verificacao (primeiro slice Alpha 1.4): a confirmacao do HUD persistente ao
  entrar na Area3D do hipermercado ('Local Descoberto: Apartamento do Setor 1')
  cobre esse comportamento naquela execucao; nao prova o jogo completo nem os
  sistemas planeados (investigacao, missoes, sobrevivencia, profissao, save/load).
- Planeamento: o gameplay das fases seguintes nao esta decidido; evitar detalhar
  antes da decisao para nao criar compromissos falsos.

## 9. Processo de atualizacao

- Entrada em sub-fase ou grande fase nova:
  1. Avisar o utilizador (regra de comunicacao do roadmap em res://.summerrules).
  2. Atualizar este ROADMAP: estado, proxima sub-fase e criterios de entrada/saida.
  3. Adicionar entrada ao DEVELOPMENT_LOG.
- Conclusao de sub-fase ou grande fase:
  1. Confirmar o estado com o utilizador.
  2. Atualizar este ROADMAP.
  3. Adicionar entrada ao DEVELOPMENT_LOG.
  4. Criar commit de marco nomeado (ex.: "Marco: Alpha 1.3 concluida").
  5. Fazer push para origin/main.
- Avisos de backup Git: avisar o utilizador antes ou depois de marcos importantes,
  correcoes confirmadas, alteracoes estruturais arriscadas, entrada em nova
  sub-fase/grande fase e antes de operacoes que alterem muitos ficheiros; pedir
  confirmacao quando uma operacao Git for destrutiva ou exigir decisao do utilizador
  (res://.summerrules).
- As operacoes Git sao executadas pelo coordenador/utilizador, nao automaticamente.
