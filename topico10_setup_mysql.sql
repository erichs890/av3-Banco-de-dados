-- =====================================================================
-- TÓPICO 10  —  SETUP MySQL  —  base densa para a comparação
-- 20.000 usuários | ~400.000 relações SEGUE (grau médio ~20)
-- =====================================================================

SET SESSION cte_max_recursion_depth = 1000000;
SET SESSION max_execution_time      = 0;

DROP DATABASE IF EXISTS topico10;
CREATE DATABASE topico10 CHARACTER SET utf8mb4;
USE topico10;

CREATE TABLE usuario (
    id    INT PRIMARY KEY,
    nome  VARCHAR(60)
);

CREATE TABLE segue (
    seguidor_id INT NOT NULL,
    seguido_id  INT NOT NULL,
    PRIMARY KEY (seguidor_id, seguido_id),
    KEY idx_seguidor (seguidor_id),
    KEY idx_seguido  (seguido_id)
);

-- ---------------------------------------------------------------------
-- 20.000 usuários
-- ---------------------------------------------------------------------
INSERT INTO usuario (id, nome)
WITH RECURSIVE seq AS (
    SELECT 1 AS n UNION ALL SELECT n+1 FROM seq WHERE n < 20000
)
SELECT n, CONCAT('User_', n) FROM seq;

-- Verificação de usuários
SELECT COUNT(*) AS total_usuarios FROM usuario;

-- ---------------------------------------------------------------------
-- 400.000 relações SEGUE — método robusto (cross-product de 2 CTEs)
-- Cada usuário recebe ~20 "seguidos" aleatórios.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO segue (seguidor_id, seguido_id)
WITH RECURSIVE
    a AS (SELECT 1 AS i UNION ALL SELECT i+1 FROM a WHERE i < 20000),
    b AS (SELECT 1 AS j UNION ALL SELECT j+1 FROM b WHERE j < 20)
SELECT
    a.i AS seguidor_id,
    1 + FLOOR(RAND(a.i*31 + b.j) * 20000) AS seguido_id
FROM a CROSS JOIN b
WHERE a.i <> 1 + FLOOR(RAND(a.i*31 + b.j) * 20000);

-- Verificação de arestas
SELECT COUNT(*) AS total_arestas FROM segue;

-- Top 5 usuários mais conectados
SELECT seguidor_id, COUNT(*) AS grau
FROM segue
GROUP BY seguidor_id
ORDER BY grau DESC
LIMIT 5;
