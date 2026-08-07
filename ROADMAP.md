# ROADMAP - Combix

Documento de planeamento do projeto Combix (Godot 4, GDScript).
Estado: ativo. Deve ser atualizado a cada entrada e saida de sub-fase e de grande
fase (ver secao "Processo de atualizacao" no final).

## 1. Grandes fases

O desenvolvimento esta organizado em quatro grandes fases:

| Fase | Nome | Estado |
|---|---|---|
| 1 | Alpha | Em curso (1.1, 1.2 e 1.3 concluidas; 1.4 nao iniciada) |
| 2 | Beta | Nao iniciada |
| 3 | Final | Nao iniciada |
| 4 | Lancamento | Nao iniciada |

Objetivos detalhados das fases 2, 3 e 4 ainda nao foram decididos. Este documento
nao inventa gameplay nao decidido: missoes, NPCs, veiculos, UI, audio e outros
sistemas so entram no roadmap quando existir uma decisao registada.

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
- Alpha 1.4 "Definicao do loop principal": PROXIMA SUB-FASE, nao iniciada; o
  loop principal ainda nao esta decidido (ver secao 6.1).

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

## 6.1. Alpha 1.4 - Definicao do loop principal (proxima sub-fase, nao iniciada)

Escopo da sub-fase: decidir e documentar o loop principal do jogo. Ainda nao
existe uma decisao de gameplay suficientemente especifica (genero, missao ou
atividade principal nao foram decididos); esta sub-fase comeca por produzir essa
decisao antes de qualquer implementacao de gameplay.

Criterios de entrada:
- Alpha 1.3 concluida e confirmada pelo utilizador (fecho documental nesta
  atualizacao).
- Esta atualizacao avisa o utilizador da entrada na nova sub-fase (regra de
  comunicacao do roadmap em res://.summerrules); o utilizador ja confirmou a
  continuacao ("vamos continuar").

Estado da decisao:
- O loop principal NAO esta decidido. Este documento nao inventa genero, missao,
  atividade principal, NPCs, UI nem conteudo; esses itens so entram no roadmap
  quando existir uma decisao registada.
- Posicao herdada do fecho de Alpha 1.3: o GIS permanece como fonte de
  referencia/edicao e o runtime normal usa BakedMap; os blockouts GIS ficam
  disponiveis como referencia visual ate decisao visual posterior.

Criterios de saida (provisorios, a confirmar no inicio da sub-fase):
- Decisao documentada do loop principal (o que o jogador faz, objetivo basico e
  condicao de fim de ciclo) aprovada pelo utilizador e registada no ROADMAP.md e
  no DEVELOPMENT_LOG.md antes de implementar gameplay.

Proxima acao:
- Coordenador/utilizador verifica o estado Git (commit local a98e604 e remoto) e
  executa o commit de marco de fecho de Alpha 1.3.
- Iniciar Alpha 1.4 com a decisao do loop principal. Alpha 1.4 nao e iniciada
  nesta tarefa.

## 7. Dependencias globais

- Dados GIS (res://gis/): GeoJSON de origem (boundary, roadway, footprints, quadras,
  corpos de agua) e recursos baked (*.res) gerados a partir deles.
- Regra de escala: 1 unidade Godot = 45,0 metros reais; fator de preservacao legado
  42,07 / 45,0 = 0,9348888889 para valores metricos antigos derivados de metros
  reais (res://world_scale.gd, res://.summerrules).
- Mundo: Washington ficcional inspirada na real; dados oficiais quando disponiveis,
  estimativas claramente identificadas quando nao existirem.
- Repositorio Git em main; a consolidacao PackedScene e a reparacao do parse
  estao no commit local a98e604 ("Consolidate Alpha 1.3 building library"), cujo
  push automatico falhou anteriormente; o coordenador/utilizador deve verificar
  o estado do remoto e executar o commit de marco de fecho de Alpha 1.3 junto
  com esta atualizacao documental
  (https://github.com/inigolandia/combix.git).

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
