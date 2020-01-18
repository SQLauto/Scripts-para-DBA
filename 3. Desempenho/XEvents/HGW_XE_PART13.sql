--Cria��o da sess�o de monitora��o
CREATE EVENT SESSION [XE_MEM_MONITOR] ON SERVER 
ADD EVENT sqlserver.server_memory_change(
    ACTION(sqlserver.database_name,sqlserver.sql_text)),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.database_name,sqlserver.sql_text)
    WHERE ([sqlserver].[database_id]=(5))) 
ADD TARGET package0.ring_buffer
GO

--Cria��o da massa de dados
USE AdventureWorks2012
GO
CREATE TABLE PESSOA
(Codigo INT, Nome VARCHAR(100), Sobrenome VARCHAR(100),
Email VARCHAR(100))
GO
INSERT PESSOA
SELECT 
	BusinessEntityID,
	FirstName,
	LastName,
	LastName+'@email.com.br'
FROM
	Person.Person
GO 1000


--Limpar buffer de mem�ria
DBCC DROPCLEANBUFFERS
GO

--Comando T-SQL que exigir� mais aloca��o de mem�ria
UPDATE PESSOA SET Nome = 'Ze'
WHERE Nome = 'KIM' OR Nome = 'Edward'

--Leitura do XML
SELECT 
Name,
CAST(target_data AS XML) AS XMLData
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets AS t 
    ON t.event_session_address = s.address