USE conectafor;

INSERT INTO usuario (nome, email, cidade, data_nascimento)
VALUES ('Maria Pitanga', 'maria@conectafor.com', 'Fortaleza', '2000-08-15');

SELECT * FROM usuario WHERE email = 'maria@conectafor.com';

UPDATE usuario SET cidade = 'Sao Paulo'
WHERE email = 'maria@conectafor.com';

DELETE FROM usuario WHERE email = 'maria@conectafor.com';
