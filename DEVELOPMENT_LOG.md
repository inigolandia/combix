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
- Alpha 1.3: em andamento (seis edificios estaticos aplicados e confirmados pelo
  utilizador - edificio 01 hipermercado de res-do-chao, edificio 02 residencial
  pequeno, edificio 03 moradia geminada, edificio 04 comercio local, edificio 05
  edificio comunitario e edificio 06 armazem industrial; consolidacao tecnica
  como PackedScene e reparacao do parse implementadas e verificadas
  tecnicamente; playtest manual pos-consolidacao e decisao sobre blockouts GIS
  pendentes; ver ROADMAP.md).

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

## Marco: Alpha 1.3 "Edificios estaticos e colisoes simplificadas" (em andamento - seis edificios confirmados; consolidacao PackedScene e reparacao do parse verificadas tecnicamente; playtest manual pendente)

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

Nota de honestidade: as confirmacoes acima cobrem os comportamentos listados naquela
execucao (seis edificios, colisoes, flicker das bases e camara). Nao provam a
funcionalidade global, o desempenho continuo nem a biblioteca completa de tipos
estaticos.

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

Nao verificado:
- Playtest manual pos-consolidacao pelo utilizador ainda nao foi feito; as
  confirmacoes em Play registadas acima referem-se ao estado anterior a
  consolidacao. O comportamento visual e de colisao apos a consolidacao
  PackedScene e a reparacao do parse precisa de ser confirmado pelo utilizador
  antes do fecho de Alpha 1.3.

### Nao verificado / desconhecido

- Playtest manual pos-consolidacao pelo utilizador ainda nao foi feito; as
  confirmacoes em Play dos seis edificios referem-se ao estado anterior a
  consolidacao PackedScene. O fecho de Alpha 1.3 depende desse playtest e da
  decisao documentada sobre o papel dos blockouts GIS; Alpha 1.3 permanece em
  andamento.
- A consolidacao tecnica foi verificada por recarregamento da cena do disco,
  diagnostics limpos e arranque tecnico sem erros observados; essa verificacao
  nao prova o comportamento visual/colisao em Play.
- Os restantes edificios estaticos do Setor 1 continuam por converter (planeado,
  nao iniciado nesta tarefa).
- Escala, proporcao e colisao foram confirmados apenas para os seis edificios
  atuais; nao cobrem a biblioteca completa nem outros dispositivos.
- Colisoes completas dos edificios continuam planeadas (decisao de desempenho em
  aberto).
- Loop principal e gameplay das fases seguintes nao decididos; nao inventar ainda.

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

- O remoto esta sincronizado com origin/main no commit b0ef068. O Git esta dirty
  apenas em res://main.tscn e res://static_building_06_industrial.tscn (as
  alteracoes da consolidacao PackedScene e da reparacao do parse); este documento
  e o ROADMAP.md passam a acompanhar esse proximo commit, executado pelo
  coordenador/utilizador. Nao foi executada nenhuma operacao Git nesta tarefa.

### Nota sobre a tentativa de atualizacao automatica anterior

- A tentativa de atualizacao automatica anterior foi bloqueada apenas porque estes
  ficheiros de jogo estavam protegidos para o builder. Esta entrada documenta o
  estado aplicado sem alterar ficheiros de jogo.

### Proxima acao

- Playtest manual pos-consolidacao pelo utilizador (confirmar visual e colisao
  dos seis edificios apos a consolidacao PackedScene e a reparacao do parse) e,
  se aprovado, fecho de Alpha 1.3.
- Decisao documentada sobre o papel dos blockouts GIS (manter como referencia,
  substituir por edificios proprios ou outra politica) antes de iniciar Alpha 1.4.
- Converter os restantes edificios estaticos do Setor 1 (planeado, nao iniciado
  nesta tarefa).
- Nao iniciar Alpha 1.4 nesta tarefa nem criar outro edificio.
- Nao iniciar ainda o loop principal: gameplay das fases seguintes nao esta
  decidido.

## Repositorio Git (estado conhecido)

- Ramo: main. O remoto esta sincronizado com origin/main no commit b0ef068. O
  estado local contem alteracoes nao commitadas: res://main.tscn e
  res://static_building_06_industrial.tscn (a consolidacao PackedScene e a
  reparacao do parse), prontas para o proximo commit de marco a executar pelo
  coordenador/utilizador, acompanhadas por esta atualizacao documental. Nao foi
  executada nenhuma operacao Git nesta tarefa.
- Remoto: https://github.com/inigolandia/combix.git
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
  - b0ef068: commit remoto atual (sincronizado com origin/main), registado antes
    da consolidacao tecnica dos seis edificios em PackedScene.
- Nota: este documento e o ROADMAP.md fazem parte do proximo commit de marco; as
  operacoes Git de marco sao executadas pelo coordenador/utilizador, nao
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
