-- =====================================================================
-- TÓPICO 10  —  DEMO MySQL
-- Consulta: quantos TRIÂNGULOS existem na rede de seguidores?
--           (A segue B, B segue C, C segue A)
--
-- Por que isso é caro em SQL:
--   - 3 self-JOINs da tabela `segue` (400k linhas).
--   - Padrão cíclico: o motor precisa materializar todas as combinações
--     parciais (A→B→C) e só depois fechar o ciclo (C→A).
-- =====================================================================

USE topico10;
SET profiling = 1;

SELECT COUNT(*) AS triangulos
FROM segue s1
JOIN segue s2 ON s1.seguido_id = s2.seguidor_id
JOIN segue s3 ON s2.seguido_id = s3.seguidor_id
             AND s3.seguido_id = s1.seguidor_id;

SHOW PROFILES;
