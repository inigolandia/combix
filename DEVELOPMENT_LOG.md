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
- Alpha 1.3: planeada, nao iniciada (ver ROADMAP.md).

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

## Repositorio Git (estado conhecido)

- Ramo: main, limpo e sincronizado com origin/main.
- Remoto: https://github.com/inigolandia/combix.git
- Commits existentes:
  - e9c1b98: backup inicial do projeto.
  - 73fa72a: preferencias persistentes do roadmap e avisos de backup Git.
- Nota: este documento e o ROADMAP.md sao novos e ainda nao commitados; as
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
