// =====================================================================
// REDE SOCIAL "ConectaFor" — Neo4j (Cypher)
// Cole bloco a bloco no Neo4j Browser (http://localhost:7474).
// =====================================================================

// ---------------------------------------------------------------------
// 1) LIMPEZA (use só se quiser reiniciar do zero)
// ---------------------------------------------------------------------
MATCH (n) DETACH DELETE n;

// ---------------------------------------------------------------------
// 2) CONSTRAINTS / INDEX
// ---------------------------------------------------------------------
CREATE CONSTRAINT usuario_id IF NOT EXISTS
FOR (u:Usuario) REQUIRE u.id IS UNIQUE;

CREATE CONSTRAINT post_id IF NOT EXISTS
FOR (p:Post) REQUIRE p.id IS UNIQUE;

CREATE INDEX usuario_email IF NOT EXISTS
FOR (u:Usuario) ON (u.email);

// ---------------------------------------------------------------------
// 3) POPULAÇÃO MASSIVA (10.000 usuários, ~50.000 SEGUE, 5.000 posts, 30.000 curtidas)
// ---------------------------------------------------------------------

// 10.000 usuários
UNWIND range(1, 10000) AS n
CREATE (:Usuario {
    id: n,
    nome: 'Usuario_' + n,
    email: 'user' + n + '@conectafor.com',
    cidade: ['Fortaleza','Recife','Sao Paulo','Rio','Belo Horizonte'][n % 5],
    data_nascimento: date('2005-01-01') - duration({days: n % 10000})
});

// 50.000 relações SEGUE
UNWIND range(1, 50000) AS n
WITH n, toInteger(rand()*10000)+1 AS a, toInteger(rand()*10000)+1 AS b
WHERE a <> b
MATCH (u1:Usuario {id: a}), (u2:Usuario {id: b})
MERGE (u1)-[:SEGUE]->(u2);

// 5.000 posts (com relação PUBLICOU)
UNWIND range(1, 5000) AS n
MATCH (autor:Usuario {id: toInteger(rand()*10000)+1})
CREATE (p:Post {
    id: n,
    conteudo: 'Post numero ' + n + ' - conteudo qualquer',
    data_publicacao: datetime()
})
CREATE (autor)-[:PUBLICOU]->(p);

// 30.000 curtidas
UNWIND range(1, 30000) AS n
WITH toInteger(rand()*10000)+1 AS u, toInteger(rand()*5000)+1 AS p
MATCH (us:Usuario {id: u}), (po:Post {id: p})
MERGE (us)-[:CURTIU]->(po);

// ---------------------------------------------------------------------
// 4) CRUD — exemplos
// ---------------------------------------------------------------------

// CREATE
CREATE (:Usuario {
    id: 99999,
    nome: 'Maria Pitanga',
    email: 'maria@conectafor.com',
    cidade: 'Fortaleza',
    data_nascimento: date('2000-08-15')
});

// READ
MATCH (u:Usuario {email: 'maria@conectafor.com'}) RETURN u;

// UPDATE
MATCH (u:Usuario {email: 'maria@conectafor.com'})
SET u.cidade = 'Sao Paulo'
RETURN u;

// DELETE de uma curtida (relação)
MATCH (:Usuario {id: 1})-[c:CURTIU]->(:Post {id: 1})
DELETE c;

// Maria passa a seguir o usuario 42
MATCH (m:Usuario {email: 'maria@conectafor.com'}), (alvo:Usuario {id: 42})
MERGE (m)-[:SEGUE]->(alvo);

// ---------------------------------------------------------------------
// 5) CONSULTAS DE DESEMPENHO  (compare com MySQL)
// ---------------------------------------------------------------------
// Dica: use o prefixo PROFILE  para ver tempo e db-hits no Browser.

// (A) Quem o usuario 1 segue? (1 nivel)
PROFILE
MATCH (:Usuario {id: 1})-[:SEGUE]->(u)
RETURN u.id, u.nome;

// (B) Amigos de amigos (2 niveis)
PROFILE
MATCH (me:Usuario {id: 1})-[:SEGUE*2]->(u)
WHERE u <> me
RETURN DISTINCT u.id, u.nome;

// (C) *** CONSULTA-VEDETE ***
//     Amigos de amigos de amigos (3 niveis) que o usuario 1 AINDA NAO segue.
PROFILE
MATCH (me:Usuario {id: 1})-[:SEGUE*3]->(u)
WHERE u <> me
  AND NOT (me)-[:SEGUE]->(u)
RETURN DISTINCT u.id, u.nome;

// (D) 4 niveis — mostra a vantagem ainda maior
PROFILE
MATCH (me:Usuario {id: 1})-[:SEGUE*4]->(u)
WHERE u <> me
RETURN DISTINCT u.id, u.nome
LIMIT 100;

// (E) BONUS: caminho mais curto entre dois usuários (impossivel/horrivel no MySQL)
MATCH p = shortestPath(
    (a:Usuario {id: 1})-[:SEGUE*..6]-(b:Usuario {id: 9999})
)
RETURN p;

// (F) BONUS: recomendação — pessoas que meus amigos seguem mas eu nao
PROFILE
MATCH (me:Usuario {id: 1})-[:SEGUE]->(:Usuario)-[:SEGUE]->(rec)
WHERE rec <> me AND NOT (me)-[:SEGUE]->(rec)
RETURN rec.id, rec.nome, count(*) AS forca
ORDER BY forca DESC
LIMIT 10;
