# Caso de Uso — Rede Social "ConectaFor"

## Cenário
Uma rede social onde:
- **Usuários** se **SEGUEM** entre si (relação direcionada).
- **Usuários** publicam **Posts**.
- **Usuários** **CURTEM** posts de outros usuários.
- **Usuários** podem ser **AMIGOS** (relação bidirecional/mútua).

## Por que grafo?
Em redes sociais, as perguntas mais frequentes são sobre **relacionamentos profundos**:
- "Quem são os amigos dos amigos dos meus amigos?" (3 níveis)
- "Qual o caminho mais curto entre o usuário A e o usuário B?"
- "Recomendar pessoas que meus amigos seguem, mas eu ainda não sigo."

No modelo **relacional**, cada nível de profundidade exige um `JOIN` adicional na tabela `seguidores`,
o que explode em custo (`O(n^k)` onde k = profundidade). No **Neo4j**, a travessia é nativa: o custo
cresce apenas com a quantidade real de vizinhos visitados, não com o tamanho da tabela.

## Modelagem

### Entidades (MySQL → tabelas / Neo4j → nodes)
| Entidade | Atributos |
|----------|-----------|
| Usuario  | id, nome, email, cidade, data_nascimento |
| Post     | id, conteudo, data_publicacao, autor_id |

### Relacionamentos (MySQL → tabelas associativas / Neo4j → relationships)
| Relação | Origem → Destino | Significado |
|---------|------------------|-------------|
| SEGUE   | Usuario → Usuario | A segue B |
| AMIGO_DE | Usuario ↔ Usuario | amizade mútua |
| CURTIU  | Usuario → Post | curtida |
| PUBLICOU | Usuario → Post | autoria |

## Volume de teste
- 10.000 usuários
- ~50.000 relações de "SEGUE" (média 5 por usuário)
- ~5.000 posts
- ~30.000 curtidas

## Consulta-vedete (Tópico 10)
**"Encontrar amigos de amigos de amigos do usuário X que ele ainda não segue."**

- MySQL: 3 JOINs aninhados na tabela `segue` + subquery `NOT IN` → tende a varrer milhões de combinações.
- Neo4j: `MATCH (u)-[:SEGUE*3]->(amigo)` → segue apenas as arestas reais.

Resultado esperado: Neo4j responde em ms; MySQL leva segundos (ou minutos) conforme a profundidade aumenta.
