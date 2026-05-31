// =====================================================================
// TÓPICO 10  —  DEMO Neo4j
// Consulta: quantos TRIÂNGULOS existem na rede de seguidores?
//           (A segue B, B segue C, C segue A)
//
// Por que isso é barato em grafo:
//   - Pattern matching cíclico é nativo no Cypher.
//   - Index-free adjacency: cada nó conhece seus vizinhos diretamente.
// =====================================================================

// (1) CONTAGEM
PROFILE
MATCH (a:Usuario)-[:SEGUE]->(b:Usuario)-[:SEGUE]->(c:Usuario)-[:SEGUE]->(a)
RETURN count(*) AS triangulos;

// (2) VISUALIZAÇÃO — desenha alguns triângulos no Browser
MATCH p = (a:Usuario)-[:SEGUE]->(b:Usuario)-[:SEGUE]->(c:Usuario)-[:SEGUE]->(a)
RETURN p
LIMIT 10;
