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
- Alpha 1.3: em andamento (tres edificios estaticos aplicados e confirmados pelo
  utilizador - edificio 01 hipermercado de res-do-chao, edificio 02 residencial
  pequeno e edificio 03 moradia geminada; ver ROADMAP.md).

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

## Marco: Alpha 1.3 "Edificios estaticos e colisoes simplificadas" (em andamento - tres edificios confirmados)

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
- Correcao de flicker das bases: as bases dos dois edificios receberam um offset
  geometrico minimo de 0.004 unidades para eliminar o flicker, sem alterar a escala
  horizontal nem a altura alvo de cada edificio.
- Camara ajustada: spring_length passou de 0.35 para 0.20.
- Jogador posicionado perto do edificio para facilitar os testes; a configuracao
  normal de arranque/GIS permaneceu leve.
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
- Correcao de flicker das bases confirmada pelo utilizador como perfeita.
- Camara ajustada para spring_length 0.20; o utilizador aprovou o estado atual
  resultante.

Nota de honestidade: as confirmacoes acima cobrem os comportamentos listados naquela
execucao (tres edificios, colisoes, flicker das bases e camara). Nao provam a
funcionalidade global, o desempenho continuo nem a biblioteca completa de tipos
estaticos.

### Nao verificado / desconhecido

- A biblioteca de tipos estaticos ainda nao esta completa; os restantes edificios do
  Setor 1 continuam por converter e Alpha 1.3 permanece em andamento.
- Escala, proporcao e colisao foram confirmados apenas para os tres edificios atuais.
- Colisoes completas dos edificios continuam planeadas (decisao de desempenho em
  aberto).
- Loop principal e gameplay das fases seguintes nao decididos; nao inventar ainda.

### Ficheiros desta fase

- res://static_building_01_apartamento.tscn (novo).
- res://static_building_02_residencial.tscn (novo).
- res://static_building_03_townhouse.tscn (novo).
- res://main.tscn (integracao dos nodos StaticBuilding01_Apartamento,
  StaticBuilding02_Residencial e StaticBuilding03_Townhouse).
- res://.summerrules (alteracoes registadas durante a fase).
- res://ROADMAP.md e res://DEVELOPMENT_LOG.md (esta atualizacao documental).

### Commit de marco

- O commit de marco anterior (3ac6f85) registou as alteracoes dos dois primeiros
  edificios (.summerrules, ROADMAP.md, DEVELOPMENT_LOG.md, main.tscn e as duas
  cenas de edificios). As alteracoes atuais (main.tscn com
  StaticBuilding03_Townhouse, a nova cena static_building_03_townhouse.tscn e esta
  atualizacao documental) estao prontas para o proximo commit; este documento e o
  ROADMAP.md acompanham esse commit, executado pelo coordenador/utilizador. Nao
  foi executada nenhuma operacao Git nesta tarefa.

### Nota sobre a tentativa de atualizacao automatica anterior

- A tentativa de atualizacao automatica anterior foi bloqueada apenas porque estes
  ficheiros de jogo estavam protegidos para o builder. Esta entrada documenta o
  estado aplicado sem alterar ficheiros de jogo.

### Proxima acao

- Criar um tipo de comercio local ou outro tipo representativo ja previsto, e
  converter os restantes edificios do Setor 1.
- Nao criar esse edificio nesta tarefa nem iniciar Alpha 1.4.
- Nao iniciar ainda o loop principal: gameplay das fases seguintes nao esta
  decidido.

## Repositorio Git (estado conhecido)

- Ramo: main. O remoto foi sincronizado com origin/main no commit 3ac6f85 (que
  registou as alteracoes dos dois primeiros edificios da sub-fase 1.3). O estado
  local contem agora alteracoes nao commitadas (main.tscn com
  StaticBuilding03_Townhouse e a nova cena static_building_03_townhouse.tscn, mais
  esta atualizacao documental), prontas para o proximo commit de marco a executar
  pelo coordenador/utilizador. Nao foi executada nenhuma operacao Git nesta tarefa.
- Remoto: https://github.com/inigolandia/combix.git
- Commits existentes:
  - e9c1b98: backup inicial do projeto.
  - 73fa72a: preferencias persistentes do roadmap e avisos de backup Git.
  - dbd351a: ultimo commit remoto conhecido antes das alteracoes da sub-fase 1.3.
  - 3ac6f85: commit de marco dos dois primeiros edificios estaticos da sub-fase
    1.3, sincronizado com origin/main.
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
