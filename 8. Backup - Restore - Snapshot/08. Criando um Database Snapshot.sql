/*********************
 * DATABASE SNAPSHOT *
 *********************/
 -- Um instant�neo do banco de dados � uma exibi��o somente leitura, est�tica de um banco de dados.
 --Criando um Database Snapshot
CREATE DATABASE DB_TK432_Snapshot
ON
(	NAME = 'TK432_Data' -- Logical Name
,	FILENAME = 'D:\x_TempSQL\DB_TK432_Snapshot.ds'),
(	NAME = 'TK432_Data2' -- Logical Name
,	FILENAME = 'D:\x_TempSQL\DB_TK432_2_Snapshot.ds')
AS SNAPSHOT OF DB_TK432; -- Banco de Dados Origem

-- Usando o Database Snapshot
Use DB_TK432;

-- Deletando um Database Snapshot
DROP DATABASE DB_TK432_Snapshot