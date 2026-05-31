MATCH (m:Usuario {id: 99999}) DETACH DELETE m;

CREATE (:Usuario {
    id: 99999,
    nome: 'Maria Fagurdes',
    email: 'maria@conectafor.com',
    cidade: 'Fortaleza',
    data_nascimento: date('2000-08-15')
});

MATCH (u:Usuario {email: 'maria@conectafor.com'}) RETURN u; 

MATCH (u:Usuario {email: 'maria@conectafor.com'})
SET u.cidade = 'Sao Paulo'
RETURN u;

MATCH (u:Usuario {email: 'maria@conectafor.com'}) DETACH DELETE u;
