-- =====================================================================
-- TÓPICO 10  —  DEMO MySQL  (caso 2)
-- Consulta: TOP 10 usuários mais "influentes" — ranqueados pelo
--           número de pessoas distintas alcançáveis em 2 hops
--           (amigos de amigos).
--
-- Por que isso é caro em SQL:
--   - JOIN de segue × segue gera intermediário potencialmente enorme.
--   - GROUP BY + COUNT(DISTINCT) só pode rodar DEPOIS de materializar
--     todas as combinações.
-- =====================================================================

USE topico10;
SET profiling = 1;

SELECT s1.seguidor_id           AS usuario,
       COUNT(DISTINCT s2.seguido_id) AS amigos_de_amigos
FROM segue s1
JOIN segue s2 ON s1.seguido_id = s2.seguidor_id
WHERE s2.seguido_id <> s1.seguidor_id
GROUP BY s1.seguidor_id
ORDER BY amigos_de_amigos DESC
LIMIT 10;

SHOW PROFILES;
