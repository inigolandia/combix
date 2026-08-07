# ROADMAP - Combix

Documento de planeamento do projeto Combix (Godot 4, GDScript).
Estado: ativo. Deve ser atualizado a cada entrada e saida de sub-fase e de grande
fase (ver secao "Processo de atualizacao" no final).

## 1. Grandes fases

O desenvolvimento esta organizado em quatro grandes fases:

| Fase | Nome | Estado |
|---|---|---|
| 1 | Alpha | Em curso (1.1 e 1.2 concluidas; 1.3 em andamento) |
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
- Alpha 1.3 "Edificios estaticos e colisoes simplificadas": EM ANDAMENTO. Tres
  edificios estaticos aplicados e confirmados pelo utilizador (edificio 01 -
  hipermercado de res-do-chao, edificio 02 - residencial pequeno e edificio 03 -
  moradia geminada); ver secao 6.

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

## 6. Alpha 1.3 - Edificios estaticos e colisoes simplificadas (em andamento)

Escopo planeado (provisorio): edificios estaticos a partir dos footprints do Setor 1
e colisoes simplificadas. Os detalhes e criterios de saida devem ser definidos e
confirmados no inicio da sub-fase.

Dependencias:
- Alpha 1.2 concluida e confirmada.
- Dados de footprints disponiveis: res://gis/04_building_footprints_sector1.geojson
  e res://gis/sector1_building_footprints_batch.res.
- Decisoes de desempenho (colisao simplificada vs sem colisao) a confirmar.

Estado atual (tres edificios estaticos aplicados e confirmados pelo utilizador):
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
- Correcao de flicker das bases (aplicada e confirmada pelo utilizador como
  perfeita): as bases dos dois edificios receberam um offset geometrico minimo de
  0.004 unidades para eliminar o flicker, sem alterar a escala horizontal nem a
  altura alvo de cada edificio.
- Camara ajustada: spring_length passou de 0.35 para 0.20; o utilizador aprovou o
  estado atual resultante.
- Jogador posicionado perto do edificio para facilitar os testes; a configuracao
  normal de arranque/GIS permaneceu leve.
- BakedMap, volumes low-rise e footprints GIS continuam presentes como referencia;
  as fatias atuais nao substituem nem removem os overlays GIS.
- A tentativa de atualizacao automatica anterior foi bloqueada apenas porque os
  ficheiros de jogo estavam protegidos para o builder; este ROADMAP apenas regista o
  estado aplicado, sem alterar ficheiros de jogo.

Criterios de entrada:
- 1.2 concluida; utilizador avisado e confirma o inicio de 1.3.

Criterios de saida:
- A definir/confirmar; ainda nao cumpridos. Nao marcar 1.3 como concluida: a
  biblioteca de tipos estaticos ainda nao esta completa e os restantes edificios
  estaticos do Setor 1 continuam por converter.

Proxima acao:
- Criar um tipo de comercio local ou outro tipo representativo ja previsto e
  converter os restantes edificios; nao criar esse edificio nesta tarefa e nao
  inventar ainda o loop principal (gameplay das fases seguintes nao esta
  decidido).

Nota sobre commit de marco:
- O commit de marco anterior (3ac6f85) registou os dois primeiros edificios. As
  alteracoes atuais (main.tscn com StaticBuilding03_Townhouse, a nova cena
  static_building_03_townhouse.tscn e esta atualizacao documental) estao prontas
  para o proximo commit; este documento e o DEVELOPMENT_LOG.md acompanham esse
  commit, executado pelo coordenador/utilizador.

Riscos:
- Muitos shapes de colisao podem degradar o desempenho; a decisao atual e que os
  footprints nao tem colisao por razoes de desempenho.
- Footprints reais podem conter geometrias complexas ou sobrepostas.

## 7. Dependencias globais

- Dados GIS (res://gis/): GeoJSON de origem (boundary, roadway, footprints, quadras,
  corpos de agua) e recursos baked (*.res) gerados a partir deles.
- Regra de escala: 1 unidade Godot = 45,0 metros reais; fator de preservacao legado
  42,07 / 45,0 = 0,9348888889 para valores metricos antigos derivados de metros
  reais (res://world_scale.gd, res://.summerrules).
- Mundo: Washington ficcional inspirada na real; dados oficiais quando disponiveis,
  estimativas claramente identificadas quando nao existirem.
- Repositorio Git em main; ultima sincronizacao com origin/main no commit 3ac6f85
  (que registou os dois primeiros edificios da sub-fase 1.3); as alteracoes atuais
  (main.tscn com StaticBuilding03_Townhouse, a nova cena
  static_building_03_townhouse.tscn e esta atualizacao documental) seguem locais e
  prontas para o proximo commit (https://github.com/inigolandia/combix.git).

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
  desempenho continuo nem funcionalidade global.
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
