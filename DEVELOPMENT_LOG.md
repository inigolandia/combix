# DEVELOPMENT_LOG - Combix

Diario de desenvolvimento. Cada entrada regista um marco (sub-fase ou grande fase):
o que foi implementado, o que foi confirmado pelo utilizador, o que permanece
desconhecido e as operacoes Git relevantes. Adicionar data a cada entrada quando a
data for conhecida. Sempre distinguir nos registos: implementado, confirmado pelo
utilizador, nao verificado e planeado. Nao transformar uma captura ou um arranque
sem erros em prova de funcionalidade global.

## Estado atual

- Alpha 1.1: concluida.
- Alpha 1.2: concluida e confirmada pelo utilizador em Play.
- Alpha 1.3: concluida e confirmada pelo utilizador (seis edificios estaticos -
  edificio 01 hipermercado de res-do-chao, edificio 02 residencial pequeno,
  edificio 03 moradia geminada, edificio 04 comercio local, edificio 05 edificio
  comunitario e edificio 06 armazem industrial; consolidacao tecnica como
  PackedScene sob Main/StaticBuildings e reparacao do parse de main.tscn
  implementadas e verificadas; playtest manual pos-consolidacao confirmado como
  perfeito; ver ROADMAP.md).
- Alpha 1.4: em andamento (definicao do loop principal); decisao de design
  registada como visao: RPG narrativo de mundo aberto com loop composto de
  exploracao urbana, investigacao, missoes/objetivos e sobrevivencia, papel do
  personagem em aberto; primeiro slice jogavel decidido pelo utilizador,
  implementado e VALIDADO em Play (explorar e descobrir um local; HUD
  persistente com 'Local Descoberto: Apartamento do Setor 1'); fundacao
  narrativa registada e clarificada (Corvax e o nome final do protagonista;
  equipa composta por companheiros recrutaveis; Iblis no Capitolio a guardar o
  Codificador Sagrado; escopo geografico total ainda em aberto entre apenas o
  Setor 1 e toda Washington DC; Corvax encontra a equipa, ganha experiencia e
  fica mais forte no Setor 1 antes de Iblis; hierarquia demoniaca do Setor 1
  apenas planeada; contagens em aberto; ver entradas abaixo); o primeiro slice
  permanece sem combate, demonios, companheiros ou missao neste momento; o
  slice de descoberta foi expandido para seis locais descobriveis (edificios
  01 a 06) e a distancia de ativacao foi normalizada por fachada: implementado
  e verificado tecnicamente (seis BoxShape3D dedicadas pelo footprint real de
  cada edificio mais margem comum de 0.5 unidades em X e Z; altura 0.8;
  collision_mask=2, script, hud_path, polling, idempotencia e HUD acumulativo
  preservados); o playtest manual detalhado dos seis locais e a igualdade
  visual das distancias permanecem nao verificados manualmente (o utilizador
  respondeu apenas 'podemos continuar'); a sub-fase Alpha 1.4 continua em
  andamento (proximo incremento do slice de descoberta ainda nao escolhido);
  ver entradas abaixo.

## Marco: Alpha 1.1 "Base tecnica estavel" (concluida)

### O que foi implementado

- Cena principal res://main.tscn com a base tecnica do Setor 1:
  - Main (Node3D), Setor1_EntradaDaCidade, Setor1_Poligono_Aproximado com 9
    vertices de marcacao (Marker3D).
  - ArenaGround (StaticBody3D com mesh e colisao).
  - Building (StaticBody3D com mesh e colisao).
  - PlacasDePedra: 15 placas de lote (StaticBody3D com mesh e colisao).
  - Player (CharacterBody3D, grupo "player") com CameraController, SpringArm3D e
    Camera3D.
  - Sun (DirectionalLight3D) e WorldEnvironment.
  - GISOverlayRuntime (Node3D) com overlays GIS e colisao da fronteira.
  - BakedMap (Node3D) com overlays baked.
- Controles e utilitarios:
  - res://player_controller.gd (movimento do jogador).
  - res://top_down_camera_controller.gd (camara).
  - res://world_scale.gd (escala canonica: 1 unidade = 45,0 metros reais).
- Runtime GIS (res://gis_overlay_runtime.gd):
  - Overlays baked de fronteira, vias, quadras, margens de corpos de agua,
    footprints de edificios e massas low-rise.
  - Colisao da fronteira do Setor 1 (Sector1BoundaryCollision com
    AggregatedBoundaryMiteredWall).
  - Toggles de visibilidade para linework de footprints, vias, quadras e margens de
    corpos de agua.
- Recursos baked em res://gis/: sector1_boundary_overlay.res,
  sector1_roadway_overlay.res, sector1_square_boundaries_batch.res,
  sector1_waterbody_margins_batch.res, sector1_building_footprints_batch.res,
  sector1_lowrise_masses_multimesh.res.
- Fontes GeoJSON preservadas em res://gis/ (boundary, roadway, footprints, quadras,
  corpos de agua).

### Confirmado pelo utilizador

- Nao ha registo de confirmacao formal separada para 1.1; a base foi considerada
  estavel ao prosseguir para 1.2, e a confirmacao de 1.2 em Play cobre tambem a
  base (jogador, camara, fronteira, arranque).

### Nao verificado / desconhecido

- Desempenho dos toggles e dos overlays em runtime nao registado como confirmado.
- Comportamento em dispositivos diferentes do usado nos testes.

## Marco: Alpha 1.2 "Mapa estatico controlado" (concluida e confirmada)

### O que foi implementado

- BakedMap passou a ser a fonte principal do mapa estatico (overlays baked:
  fronteira, vias, quadras, margens de corpos de agua, footprints, massas low-rise).
- GISOverlayRuntime mantido na arvore como fonte desacoplada; os overlays duplicados
  ficam ocultos no runtime.
- Colisao da fronteira do Setor 1 ativa.
- Velocidade do jogador: 18,0 m/s reais, convertida para unidades do jogo via
  WorldScale.meters_to_units (1 unidade = 45,0 metros reais).

### Confirmado pelo utilizador em Play

- BakedMap e a fonte principal do mapa estatico.
- Linhas baked visiveis.
- Arranque rapido.
- Jogador funcional.
- Fronteira funcional.
- Overlays GIS duplicados ocultos no runtime.
- Fontes GIS preservadas.
- Velocidade de 18,0 m/s reais adequada.

Nota de honestidade: a confirmacao em Play valida os comportamentos listados naquela
execucao. Nao prova a funcionalidade global (desempenho continuo, interacoes
futuras, outros dispositivos).

### Limitacoes GIS conhecidas

- Footprints de edificios continuam sem colisao por razoes de desempenho.
- Volumes translucidos (massas low-rise) continuam em blockout.
- Existem overlays duplicados na arvore (GISOverlayRuntime e BakedMap); manter as
  duas fontes exige disciplina para nao editar a fonte errada.
- Datasets GeoJSON grandes (ex.: roadway_blockface.geojson ~29 MB,
  square_boundaries.geojson ~16 MB) aumentam o peso de importacao/processamento.
- O nodo Sector1BuildingCollision existe na arvore dentro de GISOverlayRuntime; o
  estado efetivo em runtime nao foi verificado para este documento, e os footprints
  seguem sem colisao ativa por decisao de desempenho.

### Nao verificado / desconhecido

- Desempenho a longo prazo com a cena completa e futuras adicoes (1.3 e seguintes).
- Sistemas de gameplay das fases seguintes (nao decididos; ver ROADMAP.md).

## Marco: Alpha 1.3 "Edificios estaticos e colisoes simplificadas" (concluida e confirmada)

### O que foi implementado (aplicado)

- Edificio 01 - hipermercado de res-do-chao:
  - Nova cena res://static_building_01_apartamento.tscn.
  - Integrada na cena principal res://main.tscn sob
    Main/StaticBuildings/StaticBuilding01_Apartamento.
  - O nodo contem MeshInstance3D (Mesh) e CollisionShape3D (Collision) simples.
- Edificio 02 - residencial pequeno:
  - Nova cena res://static_building_02_residencial.tscn.
  - Integrada na cena principal res://main.tscn sob
    Main/StaticBuildings/StaticBuilding02_Residencial.
  - O nodo contem MeshInstance3D (Mesh) e CollisionShape3D (Collision) simples.
- Edificio 03 - moradia geminada (townhouse):
  - Nova cena res://static_building_03_townhouse.tscn.
  - Integrada na cena principal res://main.tscn sob
    Main/StaticBuildings/StaticBuilding03_Townhouse.
  - Derivada do marcador Placa_06_Townhouse_Habitacao_Geminada_01.
  - O nodo contem MeshInstance3D (Mesh) e CollisionShape3D (Collision) simples
    alinhados (mesh e shape com size Vector3(0.29, 0.18, 0.71)).
- Edificio 04 - comercio local:
  - Nova cena res://static_building_04_comercio.tscn.
  - Integrada na cena principal res://main.tscn sob
    Main/StaticBuildings/StaticBuilding04_Comercio.
  - Derivada do marcador Placa_11_Comercio_Local_01.
  - O nodo contem MeshInstance3D (Mesh) e CollisionShape3D (Collision) simples
    alinhados (mesh e shape com size Vector3(0.59, 0.14, 0.71)).
  - Jogador posicionado perto do edificio em (-10, 0.021393, 10) para o teste.
- Edificio 05 - edificio comunitario:
  - Nova cena res://static_building_05_comunitaria.tscn.
  - Integrada na cena principal res://main.tscn sob
    Main/StaticBuildings/StaticBuilding05_Comunitaria.
  - Derivada do marcador Placa_13_Comunitaria_01 em (0, 0, 12).
  - O nodo contem MeshInstance3D (Mesh) e CollisionShape3D (Collision) simples
    alinhados (mesh e shape com size Vector3(0.83, 0.16, 1.07)).
  - Jogador posicionado perto do edificio em (3, 0.021393, 12) para o teste.
- Edificio 06 - armazem industrial:
  - Nova cena res://static_building_06_industrial.tscn.
  - Integrada na cena principal res://main.tscn sob
    Main/StaticBuildings/StaticBuilding06_Industrial.
  - Derivada do marcador Placa_15_Industrial_Armazem_Periferico em (10, 0, 12).
  - O nodo contem MeshInstance3D (Mesh) e CollisionShape3D (Collision) simples
    alinhados (mesh e shape com size Vector3(1.66, 0.22, 2.38)).
  - Correcao anti-flicker da base: offset Y corrigido de 0.111 para 0.114,
    seguindo a margem anti-flicker de 0.004 unidades, sem alterar a escala
    horizontal nem a altura alvo.
  - Jogador corrigido para (8, 0.021393, 12.5), dentro do Setor 1 e perto do
    armazem, antes do teste.
- Correcao de flicker das bases: as bases dos dois edificios receberam um offset
  geometrico minimo de 0.004 unidades para eliminar o flicker, sem alterar a escala
  horizontal nem a altura alvo de cada edificio.
- Camara ajustada: spring_length passou de 0.35 para 0.20.
- Jogador corrigido para (8, 0.021393, 12.5), dentro do Setor 1 e perto do
  armazem industrial, antes do teste; a configuracao normal de arranque/GIS
  permaneceu leve.
- BakedMap, volumes low-rise e footprints GIS continuam presentes como referencia;
  os overlays de GISOverlayRuntime nao foram alterados por estas fatias
  (Sector1BoundaryCollision mantem a colisao da fronteira e
  Sector1BuildingCollision permanece vazio).

### Confirmado pelo utilizador

- Edificio 01 (hipermercado de res-do-chao) confirmado em Play:
  - Altura do edificio: 4.5 m reais = 0.10 unidades Godot (regra 1 unidade =
    45.0 m reais).
  - Footprint 1.19 x 1.43 unidades.
  - Jogador: 1.7 m reais = 0.03778 unidades Godot.
  - Proporcao de aproximadamente 37.8% (edificio/jogador) considerada correta.
  - Colisao simples confirmada perfeita.
  - Jogador colocado temporariamente perto do edificio para o teste.
- Edificio 02 (residencial pequeno) confirmado em Play:
  - Footprint herdado do marcador Placa_01.
  - Altura do edificio: 5.4 m reais = 0.12 unidades Godot.
  - Colisao simples integrada.
- Edificio 03 (moradia geminada) confirmado em Play:
  - Footprint 0.29 x 0.71 unidades Godot (12 x 30 m reais).
  - Altura do edificio: 0.18 unidades Godot = 8.1 m reais.
  - MeshInstance3D e CollisionShape3D simples alinhados.
  - Colisao e resultado visual confirmados como perfeitos.
  - Escala, local, colisao e funcionamento considerados perfeitos pelo utilizador.
  - Jogador colocado temporariamente perto do edificio em (-10, 0.021393, -2)
    para o teste.
- Edificio 04 (comercio local) confirmado em Play:
  - Footprint 0.59 x 0.71 unidades Godot (25 x 30 m reais).
  - Altura do edificio: 0.14 unidades Godot = 6.3 m reais.
  - MeshInstance3D e CollisionShape3D simples alinhados.
  - Colisao e resultado visual confirmados.
  - Escala, local, colisao, posicao e arranque considerados corretos pelo
    utilizador.
  - Jogador colocado temporariamente perto do edificio em (-10, 0.021393, 10)
    para o teste.
- Edificio 05 (edificio comunitario) confirmado em Play:
  - Footprint 0.83 x 1.07 unidades Godot.
  - Altura do edificio: 0.16 unidades Godot.
  - MeshInstance3D e CollisionShape3D simples alinhados.
  - Colisao e resultado visual confirmados.
  - Escala, local, colisao, posicao e arranque considerados corretos pelo
    utilizador.
  - Jogador colocado temporariamente perto do edificio em (3, 0.021393, 12) para
    o teste.
- Edificio 06 (armazem industrial) confirmado em Play:
  - Footprint 1.66 x 2.38 unidades Godot (74.7 x 107.1 m reais).
  - Altura do edificio: 0.22 unidades Godot = 9.9 m reais.
  - MeshInstance3D e CollisionShape3D simples alinhados.
  - Colisao e resultado visual confirmados como perfeitos; base sem flicker apos
    a correcao do offset Y para 0.114.
  - Jogador colocado dentro do Setor 1 em (8, 0.021393, 12.5), perto do armazem,
    antes do teste.
- Correcao anti-flicker da base do armazem industrial (offset Y 0.114) confirmada
  pelo utilizador como perfeita.
- Correcao de flicker das bases confirmada pelo utilizador como perfeita.
- Camara ajustada para spring_length 0.20; o utilizador aprovou o estado atual
  resultante.
- Playtest manual pos-consolidacao (apos a consolidacao PackedScene e a
  reparacao do parse): realizado pelo utilizador e confirmado como perfeito
  ("tudo esta bem, vamos continuar"); fecho de Alpha 1.3 confirmado.

Nota de honestidade: as confirmacoes acima cobrem os comportamentos listados naquela
execucao (seis edificios, colisoes, flicker das bases, camara e playtest
pos-consolidacao). Nao provam a funcionalidade global, o desempenho continuo, a
biblioteca completa de tipos estaticos, a arte final nem o conteudo do jogo.

### Auditoria/consolidacao tecnica (PackedScene) e reparacao do parse

Implementado (consolidacao):
- As seis cenas proprias foram consolidadas como PackedScene sob
  Main/StaticBuildings (StaticBuilding01_Apartamento a
  StaticBuilding06_Industrial).
- Os edificios 01-03, antes com subresources inline, foram convertidos para
  PackedScene, alinhando-os com 04-06.
- O edificio 06 recebeu header com load_steps=4 e
  collision_layer=1/collision_mask=1, consistentes com os restantes edificios.
- As posicoes dos seis edificios foram preservadas na consolidacao (nenhum
  edificio foi reposicionado).

Implementado (reparacao do parse):
- A primeira gravacao da consolidacao deixou res://main.tscn invalido em disco
  com "Parse Error: Invalid parameter" na linha 774.
- A falha foi reparada adicionando load_steps=72 ao header de res://main.tscn e
  removendo unique_id das seis linhas de nodes com instance=ExtResource(...).

Verificado tecnicamente (nao substitui playtest manual):
- OpenScene recarregou a cena a partir do disco (nao do buffer do editor).
- A arvore confirmou as seis instancias com MeshInstance3D e CollisionShape3D.
- Os diagnostics especificos ficaram limpos e uma verificacao tecnica arrancou
  sem erros observados.

Confirmado apos a consolidacao:
- Playtest manual pos-consolidacao realizado pelo utilizador apos a consolidacao
  PackedScene e a reparacao do parse; o utilizador confirmou "tudo esta bem,
  vamos continuar" e o playtest foi considerado perfeito para o fecho de
  Alpha 1.3. Essa confirmacao cobre o estado consolidado final dos seis
  edificios e o arranque preservado; nao prova o jogo completo.

### Limitacoes fora de Alpha 1.3 (registadas no fecho)

- Blockouts GIS continuam presentes na arvore como referencia visual; nao sao
  substituidos por esta sub-fase.
- Footprints GIS continuam sem colisoes de runtime por razoes de desempenho.
- O loop principal ainda nao esta decidido; Alpha 1.4 e a sub-fase para o
  definir, sem inventar genero, missao ou atividade principal.
- Arte final e conteudo do jogo ainda pendentes.
- Os restantes edificios estaticos do Setor 1 continuam por converter (planeado,
  fora desta sub-fase).
- Decisao registada: o GIS permanece como fonte de referencia/edicao e o runtime
  normal usa BakedMap; os blockouts GIS ficam disponiveis ate decisao visual
  posterior.

### Nao verificado / desconhecido

- O playtest manual pos-consolidacao foi realizado e confirmado pelo utilizador
  como perfeito; a verificacao tecnica (recarregamento da cena do disco,
  diagnostics limpos e arranque sem erros observados) continua registada como
  complemento, nao como prova de comportamento em Play.
- Os restantes edificios estaticos do Setor 1 continuam por converter (fora de
  Alpha 1.3; planeado, nao iniciado nesta tarefa).
- Escala, proporcao e colisao foram confirmados apenas para os seis edificios
  atuais; nao cobrem a biblioteca completa nem outros dispositivos.
- Colisoes completas dos edificios continuam planeadas (decisao de desempenho em
  aberto).
- Loop principal e gameplay das fases seguintes nao decididos; nao inventar ainda.
- Arte final e conteudo do jogo ainda pendentes (fora de Alpha 1.3).

### Ficheiros desta fase

- res://static_building_01_apartamento.tscn (novo; consolidado como PackedScene).
- res://static_building_02_residencial.tscn (novo; consolidado como PackedScene).
- res://static_building_03_townhouse.tscn (novo; consolidado como PackedScene).
- res://static_building_04_comercio.tscn (novo; ja PackedScene, mantido).
- res://static_building_05_comunitaria.tscn (novo; ja PackedScene, mantido).
- res://static_building_06_industrial.tscn (novo; na consolidacao recebeu header
  com load_steps=4 e collision_layer=1/collision_mask=1).
- res://main.tscn (integracao dos seis nodos StaticBuilding01_Apartamento a
  StaticBuilding06_Industrial; correcao da posicao do jogador para
  (8, 0.021393, 12.5); consolidacao das seis cenas como PackedScene; reparacao
  do parse com load_steps=72 no header e remocao de unique_id das instancias
  PackedScene).
- res://.summerrules (alteracoes registadas durante a fase).
- res://ROADMAP.md e res://DEVELOPMENT_LOG.md (esta atualizacao documental).

### Commit de marco

- A consolidacao PackedScene e a reparacao do parse foram consolidadas no commit
  local a98e604 ("Consolidate Alpha 1.3 building library"); o push automatico
  desse commit falhou anteriormente e o coordenador/utilizador deve verificar o
  estado do remoto apos esta atualizacao.
- Esta atualizacao documental (ROADMAP.md e DEVELOPMENT_LOG.md) fecha Alpha 1.3
  e prepara o commit de marco de fecho (ex.: "Marco: Alpha 1.3 concluida"), a
  executar pelo coordenador/utilizador. Nao foi executada nenhuma operacao Git
  nesta tarefa.

### Nota sobre a tentativa de atualizacao automatica anterior

- A tentativa de atualizacao automatica anterior foi bloqueada apenas porque estes
  ficheiros de jogo estavam protegidos para o builder. Esta entrada documenta o
  estado aplicado sem alterar ficheiros de jogo.

### Proxima acao

- Fecho documental de Alpha 1.3 concluido (esta atualizacao); commit de marco de
  fecho preparado na secao "Commit de marco", a executar pelo coordenador/
  utilizador.
- Entrar em Alpha 1.4 "Definicao do loop principal" (proxima sub-fase, nao
  iniciada): decidir e documentar o loop principal antes de qualquer gameplay;
  o loop ainda nao esta decidido e nao deve ser inventado. Esta atualizacao
  avisa o utilizador da entrada na nova sub-fase (regra de comunicacao do
  roadmap em res://.summerrules).
- Converter os restantes edificios estaticos do Setor 1 (planeado, nao iniciado
  nesta tarefa).
- Nao criar loop de gameplay, missoes, NPCs, UI nem assets nesta tarefa.

## Marco: Alpha 1.4 - Decisao de design do loop principal (em andamento)

Entrada documental da decisao de direcao da Alpha 1.4, apos o questionario da
sub-fase respondido pelo utilizador. Nenhum gameplay foi implementado nesta
tarefa; apenas decisoes e documentacao.

### Decidido (visao de design)

- Direcao do jogo: RPG narrativo de mundo aberto, inspirado numa Washington
  ficcional, combinando exploracao urbana, investigacao, missoes/objetivos e
  sobrevivencia (atividades A, B, C e E do questionario).
- Loop composto (visao): explorar o mundo urbano -> investigar locais e pistas ->
  cumprir missoes/objetivos -> gerir a sobrevivencia; em liberdade de mundo
  aberto, com novas descobertas a abrir novos objetivos.
- Progressao composta (visao): descobertas e locais, objetivos concluidos,
  reputacao e relacoes, e mundo aberto livre.
- Papel profissional do personagem mantido deliberadamente EM ABERTO: o
  questionario recolheu residente/cidadao, investigador, estafeta/entregador e
  agente de autoridade, mas o utilizador, quando clarificado, escolheu manter a
  estrutura de papeis em aberto; nenhuma profissao e escolhida nesta fase.
- Escala e mundo herdados permanecem: Washington ficcional, 1 unidade Godot =
  45,0 metros reais (res://.summerrules).

### Nao decidido (em aberto)

- Papel profissional concreto do personagem (em aberto de proposito).
- Primeiro objetivo/missao concreta do primeiro slice jogavel (a definir dentro
  da sub-fase; nao inventado aqui).
- Regras detalhadas de sobrevivencia (fome, saude, abrigo, clima, etc.).
- Faccoes, sistemas de combate, narrativa concreta e conteudo detalhado.

### Nao implementado

- Nenhum sistema de gameplay, missao, NPC, veiculo, UI, audio, asset, cena ou
  configuracao de gameplay foi criado ou alterado por esta decisao. Apenas
  res://.summerrules, res://ROADMAP.md e res://DEVELOPMENT_LOG.md foram
  atualizados.

### Confirmado pelo utilizador

- Direcao de Alpha 1.4 escolhida no questionario (atividade principal, papel em
  aberto e progressao), registada como visao de design; nao e implementacao.

### Nao verificado / desconhecido

- Nenhuma validacao em Play e aplicavel: esta tarefa nao implementa gameplay.
- O comportamento do jogo continua o estado de Alpha 1.3 ate decisao e
  implementacao posteriores.

### Proxima acao

- Coordenador/utilizador executa o commit/push documental desta decisao (Git nao
  executado nesta tarefa).
- Primeiro slice jogavel definido e documentado na entrada seguinte (exploracao
  urbana e descoberta de um unico local); implementar na proxima tarefa, sem
  escolher profissao.
- Manter o papel do personagem e as regras de sobrevivencia em aberto ate
  decisoes explicitas do utilizador.
- Nao iniciar Alpha 1.5 nem implementar gameplay nesta fase.

## Marco: Alpha 1.4 - Primeiro slice jogavel decidido (decisao documental)

Entrada documental da escolha do primeiro slice jogavel da Alpha 1.4, feita
pelo utilizador: explorar e descobrir um local. Nenhum gameplay foi
implementado nesta tarefa; apenas documentacao em res://.summerrules,
res://ROADMAP.md e res://DEVELOPMENT_LOG.md.

### Decidido (pelo utilizador)

- O utilizador escolheu explicitamente 'Explorar e descobrir um local' como o
  primeiro nucleo a provar na Alpha 1.4.
- Primeiro slice jogavel da Alpha 1.4: exploracao urbana e descoberta de um
  unico local. O nucleo a provar e: o jogador explora uma zona do Setor 1,
  chega a um local e recebe feedback claro de descoberta, com progresso minimo
  de descoberta.

### O que fica fora do primeiro slice (nao incluido, nao inventado)

- Profissao do personagem (papel profissional permanece em aberto).
- Investigacao (pistas, casos).
- Missoes/objetivos concretos.
- Sobrevivencia (fome, saude, abrigo, clima, etc.).
- Nome do local descobrivel (nao inventado; a escolher com o utilizador na
  implementacao).
- Qualquer sistema de gameplay, UI/HUD, sinais, inputs, assets, cenas ou
  configuracao de gameplay.

### Nao implementado

- Nenhum gameplay do primeiro slice foi implementado nesta tarefa; a
  implementacao fica para a proxima tarefa de gameplay.

### Nao verificado / desconhecido

- Nenhuma validacao em Play e aplicavel: esta tarefa nao implementa gameplay.
- O comportamento do jogo continua o estado de Alpha 1.3 ate a implementacao
  do primeiro slice.

### Planeado (proxima tarefa de gameplay)

- Implementar o primeiro slice: exploracao urbana e descoberta de um unico
  local, com feedback claro ao jogador e progresso minimo de descoberta.
- Escolher com o utilizador qual local do Setor 1 (nome nao inventado nesta
  tarefa).

### Estado Git conhecido

- Antes desta atualizacao: ultimo commit local d44a024
  ("Define Alpha 1.4 open world RPG loop"); working tree limpo; ramo main
  ahead 1 do remoto; o push desse commit falhou.
- Remoto: https://github.com/inigomaio/combix.git
- Esta atualizacao documental altera res://.summerrules, res://ROADMAP.md e
  res://DEVELOPMENT_LOG.md (alteracoes nao commitadas apos esta tarefa).
- Nenhuma operacao Git foi executada nesta tarefa; o commit/push documental fica
  para o coordenador/utilizador.

### Proxima acao

- Coordenador/utilizador executa o commit/push documental desta decisao (Git nao
  executado nesta tarefa).
- Proxima tarefa: implementar o primeiro slice jogavel de Alpha 1.4 (ver
  'Planeado' acima).
- Nao iniciar Alpha 1.5 nem construir gameplay nesta decisao documental.

## Marco: Alpha 1.4 - Primeiro slice jogavel implementado e validado (explorar e descobrir um local)

Entrada da validacao do primeiro slice jogavel da Alpha 1.4, confirmada pelo
utilizador em Play. O slice 'explorar e descobrir um local' esta CONCLUIDO e
VALIDADO; a sub-fase Alpha 1.4 continua EM ANDAMENTO e nao e fechada por esta
entrada.

### O que foi implementado (aplicado)

- res://discovery_trigger.gd (trigger de descoberta) e res://discovery_hud.gd
  (HUD de descoberta) criados.
- Main/DiscoveryTrigger (Area3D) e Main/DiscoveryHUD adicionados em
  res://main.tscn.
- Correcao tecnica aplicada: collision_mask=2 na Area3D do trigger para
  corresponder a camada do Player.
- Polling de get_overlapping_bodies() adicionado como fallback para detetar o
  jogador, porque o sinal body_entered nao foi fiavel neste build.

### Confirmado pelo utilizador

- Em Play, ao entrar na Area3D do hipermercado, o HUD apareceu com
  'Local Descoberto: Apartamento do Setor 1' e a mensagem permaneceu visivel
  (nao desapareceu).
- Esta confirmacao e evidencia de comportamento desse slice naquela execucao;
  nao prova o jogo completo.

### Nao verificado / desconhecido

- Nao ha investigacao, missoes, sobrevivencia, profissao, progressao ampla nem
  save/load; sao planeados e nao foram iniciados nesta tarefa.
- Apenas o local do hipermercado (Area3D) foi validado; nenhum outro local
  descobrivel foi testado.
- A confirmacao e limitada a execucao relatada pelo utilizador; nao ha prova de
  desempenho continuo nem de funcionalidade global.

### Planeado (proxima acao da Alpha 1.4)

- Definir com o utilizador o proximo incremento narrativo/jogavel da Alpha 1.4
  (proximo slice ou conteudo a provar).
- Nao iniciar investigacao, missoes, sobrevivencia, profissao, progressao ampla
  nem save/load nesta tarefa.
- Nao iniciar Alpha 1.5 nem criar outro local descobrivel nesta tarefa.

### Estado Git conhecido

- O Git local tem provavelmente alteracoes nao commitadas nos documentos e nos
  ficheiros do slice (res://discovery_trigger.gd, res://discovery_hud.gd e
  res://main.tscn: DiscoveryTrigger/DiscoveryHUD).
- Nenhuma operacao Git foi executada nesta tarefa; o commit/push fica para o
  coordenador/utilizador apos esta atualizacao.
- Ultimo commit local conhecido nos documentos: d44a024 ("Define Alpha 1.4
  open world RPG loop"), com push falhado e ramo ahead 1 do remoto; ver secao
  'Repositorio Git' abaixo.

## Marco: Alpha 1.4 - Fundacao narrativa registada (decisao documental)

Entrada documental da fundacao narrativa fornecida pelo utilizador, registada
para orientar fases futuras sem implementar gameplay. Nenhum gameplay foi
implementado nesta tarefa; apenas documentacao em res://.summerrules,
res://ROADMAP.md e res://DEVELOPMENT_LOG.md.

### Decidido (confirmado pelo utilizador)

- Corvax e o soldado de elite protagonista da E.R.A. (Exercito da Resistencia
  Antidemonios).
- Corvax esta em Washington DC para reunir a sua equipa de soldados de elite.
- O objetivo final e derrotar Iblis no local mais importante de Washington DC e
  recuperar o Codificador Sagrado.
- O Setor 1 sera o inicio da jornada e tera uma hierarquia demoniaca: um Demonio
  Boss do setor que serve Iblis, Demonios Mini-Boss subordinados a esse Boss,
  Demonios Elite subordinados a cada Mini-Boss e Demonios Soldado subordinados a
  cada Elite.
- O primeiro slice jogavel da Alpha 1.4 permanece inalterado: exploracao urbana
  e descoberta de um unico local, sem combate, demonios ou missao neste momento.

### Em aberto (nao decidido)

- Numero de Mini-Bosses, Elites e Soldados do Setor 1 (nao decidido; nao
  inventado nesta tarefa).
- Local final concreto do confronto com Iblis (apenas registado que sera o local
  mais importante de Washington DC; nao nomeado).
- Nome da equipa de Corvax, companheiros e missoes concretas (nao inventados).
- Sistemas de combate e detalhes de implementacao da hierarquia demoniaca.

### Nao implementado

- Nenhum demonio (Boss, Mini-Boss, Elite ou Soldado), boss, combate, equipa,
  companheiro, missao ou sistema de gameplay foi criado ou alterado por esta
  decisao. Apenas res://.summerrules, res://ROADMAP.md e res://DEVELOPMENT_LOG.md
  foram atualizados.

### Confirmado pelo utilizador

- A fundacao narrativa foi fornecida como decisao do utilizador antes de
  continuar o desenvolvimento; registada sem implementar gameplay.

### Nao verificado / desconhecido

- Nenhuma validacao em Play e aplicavel: esta tarefa nao implementa gameplay.
- O comportamento do jogo continua o estado de Alpha 1.4 (primeiro slice
  validado), sem demonios nem combate.

### Estado Git conhecido

- Esta atualizacao documental (fundacao narrativa da Alpha 1.4) altera
  res://.summerrules, res://ROADMAP.md e res://DEVELOPMENT_LOG.md (alteracoes
  nao commitadas apos esta tarefa).
- Nenhuma operacao Git foi executada nesta tarefa; o commit/push documental fica
  para o coordenador/utilizador.

### Proxima acao

- Coordenador/utilizador executa o commit/push documental desta decisao (Git nao
  executado nesta tarefa).
- Proxima tarefa da Alpha 1.4: definir com o utilizador o proximo incremento
  narrativo/jogavel, sem iniciar investigacao, missoes, sobrevivencia, profissao,
  combate, demonios nem save/load nesta tarefa.
- Nao iniciar Alpha 1.5 nem implementar demonios, bosses, combate, companheiros,
  missoes ou objetivo final nesta decisao documental.

## Marco: Alpha 1.4 - Fundacao narrativa clarificada (decisao documental)

Entrada documental das clarificacoes da fundacao narrativa da Alpha 1.4,
confirmadas pelo utilizador, registadas para orientar fases futuras sem
implementar gameplay. Nenhum gameplay foi implementado nesta tarefa; apenas
documentacao em res://.summerrules, res://ROADMAP.md e res://DEVELOPMENT_LOG.md.

### Decidido (clarificacoes confirmadas pelo utilizador)

- Corvax e o nome final do protagonista, soldado de elite da E.R.A. (Exercito
  da Resistencia Antidemonios).
- A equipa de soldados de elite que Corvax reune sera composta por companheiros
  recrutaveis.
- Iblis esta no Capitolio (o local mais importante de Washington DC) e guarda o
  Codificador Sagrado; o objetivo final e derrotar Iblis e recuperar o
  Codificador Sagrado.
- O Setor 1 sera o inicio da jornada: Corvax tera de encontrar os elementos da
  sua equipa no Setor 1, ganhar experiencia e ficar mais forte antes de chegar
  a Iblis.
- A hierarquia demoniaca do Setor 1 fica apenas planeada por agora: um Demonio
  Boss do setor que serve Iblis, Demonios Mini-Boss subordinados a esse Boss,
  Demonios Elite subordinados a cada Mini-Boss e Demonios Soldado subordinados
  a cada Elite.
- O primeiro slice jogavel da Alpha 1.4 permanece inalterado e validado:
  exploracao urbana e descoberta de um unico local, sem combate, demonios,
  companheiros ou missao neste momento.

### Em aberto (nao decidido)

- Escopo geografico total do jogo: ainda em aberto entre apenas o Setor 1 e
  toda Washington DC; o Capitolio e a localizacao narrativa de Iblis, mas o
  mapa total nao esta decidido.
- Numero de Mini-Bosses, Elites e Soldados do Setor 1 (nao decidido; nao
  inventado nesta tarefa).
- Localizacao concreta do Boss do Setor (nao decidida).
- Nome da equipa de Corvax, numero e nomes dos companheiros recrutaveis e
  sistema de recrutamento (nao inventados).
- Missoes concretas, sistemas de combate e detalhes de experiencia/progressao
  (nao inventados).

### Nao implementado

- Nenhum demonio (Boss, Mini-Boss, Elite ou Soldado), boss, combate, equipa,
  companheiro, recrutamento, experiencia, progressao, missao ou sistema de
  gameplay foi criado ou alterado por estas clarificacoes. Apenas
  res://.summerrules, res://ROADMAP.md e res://DEVELOPMENT_LOG.md foram
  atualizados.
- O primeiro slice jogavel validado (exploracao urbana e descoberta de um
  unico local) nao foi alterado.

### Confirmado pelo utilizador

- As clarificacoes foram confirmadas pelo utilizador como respostas as
  perguntas de clarificacao da fundacao narrativa; registadas sem implementar
  gameplay.

### Nao verificado / desconhecido

- Nenhuma validacao em Play e aplicavel: esta tarefa nao implementa gameplay.
- O comportamento do jogo continua o estado de Alpha 1.4 (primeiro slice
  validado), sem demonios, companheiros nem combate.

### Estado Git conhecido

- Esta atualizacao documental (clarificacoes da fundacao narrativa da Alpha 1.4)
  altera res://.summerrules, res://ROADMAP.md e res://DEVELOPMENT_LOG.md
  (alteracoes nao commitadas apos esta tarefa).
- Nenhuma operacao Git foi executada nesta tarefa; o commit/push documental fica
  para o coordenador/utilizador.

### Proxima acao

- Coordenador/utilizador executa o commit/push documental destas clarificacoes
  (Git nao executado nesta tarefa).
- Proxima tarefa da Alpha 1.4: definir com o utilizador o proximo incremento
  narrativo/jogavel, sem iniciar investigacao, missoes, sobrevivencia, profissao,
  combate, demonios, companheiros, recrutamento, experiencia nem save/load nesta
  tarefa.
- Nao iniciar Alpha 1.5 nem implementar demonios, bosses, combate, companheiros,
  recrutamento, experiencia, progressao, missoes ou o objetivo final nesta
  decisao documental.

## Marco: Alpha 1.4 - Seis locais descobriveis e normalizacao da distancia de ativacao (implementado e verificado tecnicamente)

Entrada da expansao do slice de descoberta da Alpha 1.4 para seis locais
descobriveis e da normalizacao da distancia de ativacao por fachada, escolhida
pelo utilizador. O slice foi implementado e verificado tecnicamente; o playtest
manual detalhado dos seis locais ainda nao foi verificado. A sub-fase Alpha 1.4
continua EM ANDAMENTO e nao e fechada por esta entrada.

### Contexto

- O primeiro slice foi validado com um unico local descobrivel (Area3D do
  hipermercado); foram adicionados cinco locais descobriveis adicionais,
  totalizando seis (edificio 01 - hipermercado de res-do-chao, edificio 02 -
  residencial pequeno, edificio 03 - moradia geminada, edificio 04 - comercio
  local, edificio 05 - edificio comunitario e edificio 06 - armazem
  industrial).
- O utilizador reportou que as distancias de ativacao variavam; a inspecao
  confirmou que todos partilhavam uma shape; o utilizador escolheu 'Igual a
  partir da fachada'.

### O que foi implementado (aplicado)

- Seis BoxShape3D dedicadas em Main/DiscoveryTrigger (res://main.tscn),
  dimensionadas pelo footprint real de cada edificio mais uma margem comum de
  0.5 unidades em X e Z; altura 0.8.
- Preservados: collision_mask=2, script, hud_path, polling, idempotencia e HUD
  acumulativo.
- Jogador colocado perto do residencial e dentro do Setor 1 para o teste.

### Verificado tecnicamente (nao substitui playtest manual)

- A verificacao tecnica arrancou sem erros observados e confirmou a descoberta
  do residencial.

### Confirmado pelo utilizador

- O utilizador respondeu apenas 'podemos continuar', sem descrever o resultado
  dos seis testes. Esta resposta autoriza a continuacao, mas NAO confirma
  visualmente a normalizacao nem o playtest detalhado dos seis locais.

### Nao verificado / desconhecido

- Playtest manual detalhado dos seis locais descobriveis (nao descrito pelo
  utilizador).
- Igualdade visual das distancias de ativacao por fachada (nao confirmada;
  registada como implementada e verificada tecnicamente, nao como confirmada
  visualmente).
- Desempenho continuo e funcionalidade global continuam fora do alcance desta
  confirmacao.

### Estado

- Slice de descoberta expandido para seis locais descobriveis; normalizacao da
  distancia de ativacao por fachada implementada e verificada tecnicamente.
- Alpha 1.4 permanece EM ANDAMENTO; o proximo incremento do slice de
  descoberta ainda nao foi escolhido.

### Proxima acao

- Coordenador/utilizador executa o commit/push documental desta atualizacao
  (Git nao executado nesta tarefa).
- Proxima tarefa da Alpha 1.4: escolher com o utilizador o proximo incremento
  do slice de descoberta (nenhum novo incremento e inventado nesta tarefa); nao
  iniciar investigacao, missoes, sobrevivencia, profissao, progressao ampla,
  combate, demonios, companheiros, recrutamento nem save/load nesta tarefa.
- Confirmar manualmente, quando o utilizador puder, o playtest detalhado dos
  seis locais e a igualdade visual das distancias de ativacao.
- Nao iniciar Alpha 1.5 nem implementar demonios, bosses, combate, companheiros,
  missoes ou objetivo final nesta atualizacao.

### Estado Git conhecido

- Existem alteracoes locais atuais em res://main.tscn (expansao dos seis locais
  descobriveis e normalizacao da distancia de ativacao) e res://discovery_hud.gd,
  alem desta atualizacao documental (res://ROADMAP.md e res://DEVELOPMENT_LOG.md).
- Nenhuma operacao Git foi executada nesta tarefa; o coordenador fara o commit
  depois desta atualizacao.

## Repositorio Git (estado conhecido)

- Ramo: main. Ultimo commit local conhecido: d44a024 ("Define Alpha 1.4 open
  world RPG loop"); o push desse commit falhou e o ramo esta ahead 1 do
  remoto. Existem alteracoes locais atuais em res://main.tscn (expansao dos
  seis locais descobriveis e normalizacao da distancia de ativacao) e
  res://discovery_hud.gd, alem desta atualizacao documental (res://ROADMAP.md
  e res://DEVELOPMENT_LOG.md); o coordenador fara o commit depois desta
  atualizacao.
- Esta atualizacao documental (validacao do primeiro slice de Alpha 1.4 em
  res://ROADMAP.md e res://DEVELOPMENT_LOG.md) fica preparada para commit/push
  pelo coordenador/utilizador. Nao foi executada nenhuma operacao Git nesta
  tarefa.
- Esta atualizacao documental (fundacao narrativa da Alpha 1.4 em
  res://.summerrules, res://ROADMAP.md e res://DEVELOPMENT_LOG.md) fica
  preparada para commit/push pelo coordenador/utilizador. Nao foi executada
  nenhuma operacao Git nesta tarefa.
- Esta atualizacao documental (clarificacoes da fundacao narrativa da Alpha 1.4
  em res://.summerrules, res://ROADMAP.md e res://DEVELOPMENT_LOG.md) fica
  preparada para commit/push pelo coordenador/utilizador. Nao foi executada
  nenhuma operacao Git nesta tarefa.
- Remoto: https://github.com/inigomaio/combix.git
- Commits existentes:
  - e9c1b98: backup inicial do projeto.
  - 73fa72a: preferencias persistentes do roadmap e avisos de backup Git.
  - dbd351a: ultimo commit remoto conhecido antes das alteracoes da sub-fase 1.3.
  - 3ac6f85: commit de marco dos dois primeiros edificios estaticos da sub-fase
    1.3.
  - 3de6798: commit remoto registado antes das alteracoes do quarto edificio
    (comercio local).
  - cde5a0c: commit remoto registado antes das alteracoes do quinto edificio
    (edificio comunitario).
  - 6352334: ultimo commit remoto conhecido antes das alteracoes do sexto
    edificio (armazem industrial).
  - b0ef068: commit remoto registado antes da consolidacao tecnica dos seis
    edificios em PackedScene.
  - a98e604: "Consolidate Alpha 1.3 building library" (commit local da
    consolidacao PackedScene e da reparacao do parse; push automatico falhou,
    estado do remoto a verificar pelo coordenador/utilizador).
  - d44a024: "Define Alpha 1.4 open world RPG loop" (ultimo commit local
    conhecido; push falhou; ramo ahead 1 do remoto).
- Esta atualizacao documental (validacao do primeiro slice de Alpha 1.4 em
  res://ROADMAP.md e res://DEVELOPMENT_LOG.md) fica preparada para commit/push
  pelo coordenador/utilizador; nenhuma operacao Git foi executada nesta tarefa.
- Esta atualizacao documental (expansao dos seis locais descobriveis e
  normalizacao da distancia de ativacao em res://ROADMAP.md e
  res://DEVELOPMENT_LOG.md) fica preparada para commit/push pelo
  coordenador/utilizador; os ficheiros de jogo alterados (res://main.tscn e
  res://discovery_hud.gd) serao commitados pelo coordenador. Nao foi executada
  nenhuma operacao Git nesta tarefa.
- Nota: as operacoes Git de marco sao executadas pelo coordenador/utilizador, nao
  automaticamente.

## Processo futuro

- Entrada em sub-fase ou grande fase nova:
  1. Avisar o utilizador (regra de comunicacao do roadmap em res://.summerrules).
  2. Atualizar o ROADMAP.md (estado, proxima sub-fase, criterios de entrada/saida).
  3. Abrir uma nova entrada neste DEVELOPMENT_LOG com o plano e os criterios de
     saida.
- Conclusao de sub-fase ou grande fase:
  1. Confirmar o estado com o utilizador.
  2. Atualizar o ROADMAP.md.
  3. Fechar a entrada neste DEVELOPMENT_LOG com o que foi implementado, o que foi
     confirmado pelo utilizador e o que permanece desconhecido.
  4. Criar commit de marco nomeado (ex.: "Marco: Alpha 1.3 concluida") e fazer push
     para origin/main.
- Avisos de backup Git: avisar o utilizador antes ou depois de marcos importantes,
  correcoes confirmadas, alteracoes estruturais arriscadas, entrada em nova
  sub-fase/grande fase e antes de operacoes que alterem muitos ficheiros; pedir
  confirmacao quando uma operacao Git for destrutiva ou exigir decisao do utilizador
  (res://.summerrules).
