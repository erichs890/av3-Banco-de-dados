# Comparação de Performance — MySQL vs Neo4j

## Consulta
"Qual o **caminho mais curto** entre o usuário 1 e o usuário 9999 na rede de seguidores?"

Esse é o tipo de pergunta que **redes sociais fazem o tempo todo** (grau de separação,
"você conhece fulano através de X"). É um problema **nativo de grafo**: o Neo4j tem
`shortestPath()` como função embutida; o MySQL precisa fazer **busca em largura
manual com CTE recursiva**, expandindo tabelas inteiras a cada nível.

---

## MySQL

```sql
USE conectafor;
SET SESSION cte_max_recursion_depth = 1000000;
SET profiling = 1;

WITH RECURSIVE caminho (origem, destino, profundidade, rota) AS (
    SELECT seguidor_id, seguido_id, 1,
           CAST(CONCAT(seguidor_id, '->', seguido_id) AS CHAR(4000))
    FROM segue
    WHERE seguidor_id = 1

    UNION ALL

    SELECT c.origem, s.seguido_id, c.profundidade + 1,
           CAST(CONCAT(c.rota, '->', s.seguido_id) AS CHAR(4000))
    FROM caminho c
    JOIN segue s ON s.seguidor_id = c.destino
    WHERE c.profundidade < 6
      AND FIND_IN_SET(s.seguido_id, REPLACE(c.rota, '->', ',')) = 0
)
SELECT profundidade, rota
FROM caminho
WHERE destino = 9999
ORDER BY profundidade
LIMIT 1;

SHOW PROFILES;
```

> Observação: o `FIND_IN_SET` evita ciclos, mas o motor ainda assim materializa
> **todas as expansões parciais** até achar o destino. Em poucos níveis isso já
> explode: cada nível pode multiplicar as linhas por 5 (grau médio da rede),
> chegando a milhões de combinações.

---

## Neo4j

```cypher
PROFILE
MATCH p = shortestPath(
    (a:Usuario {id: 1})-[:SEGUE*..6]-(b:Usuario {id: 9999})
)
RETURN length(p) AS distancia, [n IN nodes(p) | n.id] AS rota;
```

Uma linha. O algoritmo é nativo (BFS bidirecional otimizado) e percorre
apenas as arestas necessárias.

---

## Por que o Neo4j vence

| Aspecto | MySQL | Neo4j |
|---|---|---|
| Algoritmo | CTE recursiva (BFS "na mão") | `shortestPath` (BFS nativa) |
| Estrutura | Tabela materializada a cada nível | Travessia direta de ponteiros |
| Complexidade típica | O(d^k) onde d = grau médio, k = profundidade | O(arestas visitadas) |
| Linhas de código | ~15 + controle de ciclo manual | 3 |
| Suporte a ciclos | Manual (`FIND_IN_SET`) | Automático |

O Neo4j armazena cada relação como um **ponteiro físico** entre os nós — chamado
*index-free adjacency*. Para percorrer uma aresta, ele não consulta índice nenhum,
só segue o ponteiro. Em SQL toda travessia é um JOIN, que é uma busca em índice +
hash/merge. A diferença salta aos olhos justamente em **problemas onde a estrutura
do grafo importa mais do que o conteúdo das linhas**: caminhos, ciclos, componentes
conectados, centralidade.
