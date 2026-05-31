// =====================================================================
// TÓPICO 10  —  DEMO Neo4j  (caso 2)
// Consulta: TOP 10 usuários mais "influentes" — ranqueados pelo
//           número de pessoas distintas alcançáveis em 2 hops
//           (amigos de amigos).
// =====================================================================

// (1) RANKING
PROFILE
MATCH (u:Usuario)-[:SEGUE]->(:Usuario)-[:SEGUE]->(fof:Usuario)
WHERE fof <> u
RETURN u.id AS usuario,
       count(DISTINCT fof) AS amigos_de_amigos
ORDER BY amigos_de_amigos DESC
LIMIT 10;

// (2) VISUALIZAÇÃO — desenha a rede de 2 hops do mais influente
MATCH (u:Usuario)-[:SEGUE]->(:Usuario)-[:SEGUE]->(fof:Usuario)
WHERE fof <> u
WITH u, count(DISTINCT fof) AS fof_count
ORDER BY fof_count DESC
LIMIT 1
MATCH p = (u)-[:SEGUE]->(:Usuario)-[:SEGUE]->(:Usuario)
RETURN p
LIMIT 50;
