-- =====================================================================
-- REDE SOCIAL "ConectaFor" — MySQL 8.0+
-- Copie e cole bloco a bloco no MySQL Workbench (Ctrl+Shift+Enter).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0) CONFIGURAÇÕES DE SESSÃO  (rode SEMPRE antes de qualquer CTE grande)
-- ---------------------------------------------------------------------
SET SESSION cte_max_recursion_depth = 100000;
SET SESSION max_execution_time      = 0;

-- ---------------------------------------------------------------------
-- 1) CRIAÇÃO DO BANCO
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS conectafor;
CREATE DATABASE conectafor CHARACTER SET utf8mb4;
USE conectafor;

-- ---------------------------------------------------------------------
-- 2) TABELAS
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    nome            VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    cidade          VARCHAR(80),
    data_nascimento DATE
);

CREATE TABLE post (
    id               INT PRIMARY KEY AUTO_INCREMENT,
    conteudo         TEXT NOT NULL,
    data_publicacao  DATETIME DEFAULT CURRENT_TIMESTAMP,
    autor_id         INT NOT NULL,
    FOREIGN KEY (autor_id) REFERENCES usuario(id)
);

CREATE TABLE segue (
    seguidor_id INT NOT NULL,
    seguido_id  INT NOT NULL,
    PRIMARY KEY (seguidor_id, seguido_id),
    FOREIGN KEY (seguidor_id) REFERENCES usuario(id),
    FOREIGN KEY (seguido_id)  REFERENCES usuario(id)
);

CREATE TABLE amigo (
    usuario_a_id INT NOT NULL,
    usuario_b_id INT NOT NULL,
    PRIMARY KEY (usuario_a_id, usuario_b_id),
    FOREIGN KEY (usuario_a_id) REFERENCES usuario(id),
    FOREIGN KEY (usuario_b_id) REFERENCES usuario(id)
);

CREATE TABLE curtida (
    usuario_id   INT NOT NULL,
    post_id      INT NOT NULL,
    data_curtida DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuario_id, post_id),
    FOREIGN KEY (usuario_id) REFERENCES usuario(id),
    FOREIGN KEY (post_id)    REFERENCES post(id)
);

-- índices que ajudam (e ainda assim ficam atrás do grafo em consultas profundas)
CREATE INDEX idx_segue_seguidor ON segue(seguidor_id);
CREATE INDEX idx_segue_seguido  ON segue(seguido_id);

-- ---------------------------------------------------------------------
-- 3) POPULAÇÃO MASSIVA
--    10.000 usuários | ~50.000 SEGUE | 5.000 posts | 30.000 curtidas
-- ---------------------------------------------------------------------

-- 10.000 usuários
INSERT INTO usuario (nome, email, cidade, data_nascimento)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL SELECT n+1 FROM seq WHERE n < 10000
)
SELECT
    CONCAT('Usuario_', n),
    CONCAT('user', n, '@conectafor.com'),
    ELT(1 + (n % 5), 'Fortaleza','Recife','Sao Paulo','Rio','Belo Horizonte'),
    DATE_SUB('2005-01-01', INTERVAL (n % 10000) DAY)
FROM seq;

-- 50.000 relações SEGUE (5 por usuário em média, aleatórias)
INSERT IGNORE INTO segue (seguidor_id, seguido_id)
WITH RECURSIVE seq AS (
    SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 50000
)
SELECT
    1 + FLOOR(RAND(n)   * 10000),
    1 + FLOOR(RAND(n+1) * 10000)
FROM seq
WHERE 1 + FLOOR(RAND(n)*10000) <> 1 + FLOOR(RAND(n+1)*10000);

-- 5.000 posts
INSERT INTO post (conteudo, autor_id)
WITH RECURSIVE seq AS (
    SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 5000
)
SELECT CONCAT('Post numero ', n, ' - conteudo qualquer'),
       1 + FLOOR(RAND(n) * 10000)
FROM seq;

-- 30.000 curtidas
INSERT IGNORE INTO curtida (usuario_id, post_id)
WITH RECURSIVE seq AS (
    SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 30000
)
SELECT 1 + FLOOR(RAND(n)*10000),
       1 + FLOOR(RAND(n+1)*5000)
FROM seq;

-- Conferência rápida do volume carregado
SELECT 'usuario' AS tabela, COUNT(*) AS total FROM usuario
UNION ALL SELECT 'segue',   COUNT(*) FROM segue
UNION ALL SELECT 'post',    COUNT(*) FROM post
UNION ALL SELECT 'curtida', COUNT(*) FROM curtida;

-- ---------------------------------------------------------------------
-- 4) CRUD — exemplos
-- ---------------------------------------------------------------------

-- CREATE
INSERT INTO usuario (nome, email, cidade, data_nascimento)
VALUES ('Maria Pitanga', 'maria@conectafor.com', 'Fortaleza', '2000-08-15');

-- READ
SELECT * FROM usuario WHERE email = 'maria@conectafor.com';

-- UPDATE
UPDATE usuario SET cidade = 'Sao Paulo'
WHERE email = 'maria@conectafor.com';

-- Maria segue o usuário 42
INSERT IGNORE INTO segue (seguidor_id, seguido_id)
SELECT id, 42 FROM usuario WHERE email = 'maria@conectafor.com';

-- DELETE  (Maria deixa de seguir o 42)
DELETE FROM segue
WHERE seguidor_id = (SELECT id FROM usuario WHERE email='maria@conectafor.com')
  AND seguido_id  = 42;

-- ---------------------------------------------------------------------
-- 5) CONSULTAS DE DESEMPENHO  (compare com Neo4j)
-- ---------------------------------------------------------------------
SET profiling = 1;

-- (A) Quem o usuário 1 segue? — 1 nível
SELECT u.id, u.nome
FROM segue s
JOIN usuario u ON u.id = s.seguido_id
WHERE s.seguidor_id = 1;

-- (B) Amigos de amigos do usuário 1 — 2 níveis
SELECT DISTINCT u.id, u.nome
FROM segue s1
JOIN segue s2 ON s1.seguido_id = s2.seguidor_id
JOIN usuario u ON u.id = s2.seguido_id
WHERE s1.seguidor_id = 1
  AND s2.seguido_id <> 1;

-- (C) *** CONSULTA-VEDETE *** — 3 níveis
--     Amigos de amigos de amigos que o usuário 1 ainda NÃO segue.
SELECT DISTINCT u.id, u.nome
FROM segue s1
JOIN segue s2 ON s1.seguido_id = s2.seguidor_id
JOIN segue s3 ON s2.seguido_id = s3.seguidor_id
JOIN usuario u ON u.id = s3.seguido_id
WHERE s1.seguidor_id = 1
  AND s3.seguido_id <> 1
  AND s3.seguido_id NOT IN (
      SELECT seguido_id FROM segue WHERE seguidor_id = 1
  );

-- (D) 4 níveis — aqui o MySQL "engasga" de vez
SELECT DISTINCT u.id, u.nome
FROM segue s1
JOIN segue s2 ON s1.seguido_id = s2.seguidor_id
JOIN segue s3 ON s2.seguido_id = s3.seguidor_id
JOIN segue s4 ON s3.seguido_id = s4.seguidor_id
JOIN usuario u ON u.id = s4.seguido_id
WHERE s1.seguidor_id = 1;

-- Ver tempos das consultas executadas nesta sessão:
SHOW PROFILES;

-- ---------------------------------------------------------------------
-- 6) LIMPEZA (opcional)
-- ---------------------------------------------------------------------
-- DROP DATABASE conectafor;
