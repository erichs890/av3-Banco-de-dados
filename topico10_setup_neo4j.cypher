// =====================================================================
// TÓPICO 10  —  SETUP Neo4j  —  base densa para a comparação
// 20.000 usuários | ~400.000 relações SEGUE (grau médio ~20)
// =====================================================================

// (Opcional) limpa tudo. Se quiser preservar outras bases, pule este bloco.
MATCH (n) DETACH DELETE n;

// Constraint para acelerar os MATCHs por id
CREATE CONSTRAINT t10_usuario_id IF NOT EXISTS
FOR (u:Usuario) REQUIRE u.id IS UNIQUE;

// 20.000 usuários
UNWIND range(1, 20000) AS n
CREATE (:Usuario {id: n, nome: 'User_' + n});

// 400.000 relações SEGUE
UNWIND range(1, 400000) AS n
WITH n, toInteger(rand()*20000)+1 AS a, toInteger(rand()*20000)+1 AS b
WHERE a <> b
MATCH (u1:Usuario {id: a}), (u2:Usuario {id: b})
MERGE (u1)-[:SEGUE]->(u2);

// Conferência
MATCH (u:Usuario) WITH count(u) AS usuarios
MATCH ()-[r:SEGUE]->() RETURN usuarios, count(r) AS relacoes;
