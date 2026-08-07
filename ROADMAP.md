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
- Alpha 1.3 "Edificios estaticos e colisoes simplificadas": EM ANDAMENTO. Primeira
  fatia aplicada e confirmada pelo utilizador (edificio estatico 01); ver secao 6.

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

Estado atual (primeira fatia aplicada e confirmada pelo utilizador):
- Nova cena res://static_building_01_apartamento.tscn integrada na cena principal
  sob Main/StaticBuildings/StaticBuilding01_Apartamento, com Mesh (MeshInstance3D)
  e CollisionShape3D simples.
- Primeiro slice (hipermercado de res-do-chao) confirmado pelo utilizador em Play:
  altura 4.5 m reais = 0.10 unidades, jogador 1.7 m reais = 0.03778 unidades,
  proporcao de aproximadamente 37.8% considerada correta, colisao confirmada
  perfeita e jogador colocado perto do edificio para o teste.
- BakedMap, volumes low-rise e footprints GIS continuam presentes como referencia;
  a fatia atual nao substitui nem remove os overlays GIS.
- A tentativa de atualizacao automatica anterior foi bloqueada apenas porque os
  ficheiros de jogo estavam protegidos para o builder; este ROADMAP apenas regista o
  estado aplicado, sem alterar ficheiros de jogo.

Criterios de entrada:
- 1.2 concluida; utilizador avisado e confirma o inicio de 1.3.

Criterios de saida:
- A definir/confirmar; ainda nao cumpridos. Nao marcar 1.3 como concluida: os
  restantes edificios estaticos e as colisoes simplificadas ainda nao foram
  convertidos.

Proxima acao:
- Avancar para o proximo edificio estatico representativo e converter os restantes
  edificios; nao inventar ainda o loop principal (gameplay das fases seguintes nao
  esta decidido).

Nota sobre commit de marco:
- Os ficheiros de jogo da fatia estao prontos para um commit de marco; este
  documento e o DEVELOPMENT_LOG.md serao acompanhados por esse commit, executado
  pelo coordenador/utilizador.

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
- Repositorio Git em main sincronizado com origin/main
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
