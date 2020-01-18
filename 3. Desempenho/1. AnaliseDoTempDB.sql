--Optimizing tempdb Performance
--https://technet.microsoft.com/en-us/library/ms175527(v=sql.105).aspx

--Compilation of SQL Server TempDB IO Best Practices
--http://blogs.msdn.com/b/cindygross/archive/2009/11/20/compilation-of-sql-server-tempdb-io-best-practices.aspx

-------------
-- Tamanho --
-------------
SP_HELPDB TEMPDB

-------------------
-- Limpa o cache --
-------------------
-- ver impacto*
--DBCC FREEPROCCACHE

----------------
-- CHECKPOINT --
----------------
-- https://msdn.microsoft.com/pt-br/library/ms188748.aspx
-- CHECKPOINT

------------
-- TEMPDB --
------------
-- http://msdn.microsoft.com/pt-br/library/ms176029.aspx
/* O banco de dados do sistema tempdb � um recurso global dispon�vel a todos os 
usu�rios conectados a uma inst�ncia do SQL Server. O banco de dados tempdb � 
utilizado para armazenar os seguintes objetos: objetos do usu�rio, objetos 
internos e armazenamentos de vers�o.
Voc� pode utilizar a exibi��o de gerenciamento din�mico sys.dm_db_file_space_usage 
para monitorar o espa�o em disco utilizado pelos objetos de usu�rio, objetos 
internos e armazenamentos de vers�o nos arquivos tempdb. Al�m disso, para monitorar 
a atividade de aloca��o ou desaloca��o de p�gina em tempdb no n�vel da sess�o ou 
tarefa, voc� pode utilizar as exibi��es de gerenciamento 
din�mico sys.dm_db_session_space_usage e sys.dm_db_task_space_usage. 
Essas exibi��es podem ser utilizadas para identificar consultas grandes, 
tabelas tempor�rias ou vari�veis de tabela que est�o utilizando muito espa�o em 
disco de tempdb. */

select * from sys.dm_db_file_space_usage
select * from sys.dm_db_session_space_usage
select * from sys.dm_db_task_space_usage

-- Determinando a quantidade de espa�o livre em tempdb
-------------------------------------------------------
SELECT SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

-- Determinando o volume de espa�o usado pelo armazenamento de vers�o
---------------------------------------------------------------------
SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM sys.dm_db_file_space_usage;

-- Determinando a transa��o mais longa em execu��o
--------------------------------------------------
SELECT transaction_id
FROM sys.dm_tran_active_snapshot_database_transactions 
ORDER BY elapsed_time_seconds DESC;

-- Determinando o volume de espa�o usado por objetos internos
-------------------------------------------------------------
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage;

-- Determinando o volume de espa�o usado por objetos do usu�rio
---------------------------------------------------------------
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage;

------------------------
-- CONEX�ES NO TEMPDB --
------------------------
SELECT	A.session_id
,		B.host_name
,		B.Login_Name
,		(user_objects_alloc_page_count + internal_objects_alloc_page_count)*1.0/128 as TotalalocadoMB
,		D.Text
FROM	sys.dm_db_session_space_usage	A
JOIN	sys.dm_exec_sessions			B ON A.session_id = B.session_id
JOIN	sys.dm_exec_connections			C ON C.session_id = B.session_id
CROSS APPLY sys.dm_exec_sql_text(C.most_recent_sql_handle) As D
WHERE	A.session_id > 50
and		(user_objects_alloc_page_count + internal_objects_alloc_page_count)*1.0/128 > 10 -- Ocupam mais de 100 MB
ORDER BY totalalocadoMB desc
COMPUTE sum((user_objects_alloc_page_count + internal_objects_alloc_page_count)*1.0/128)

---------------------------------------------------------------------------------
-- The next obvious step would be to check for any open transaction on tempdb. --
-- Requisi��es / Processos no TempDB                                           --
---------------------------------------------------------------------------------
SELECT * FROM sys.dm_exec_requests WHERE database_id = 2
SELECT * FROM sys.sysprocesses WHERE dbid = 2

------------------------------------
-- Querys mais custosas na TempDB --
------------------------------------
;WITH tab(session_id, host_name, login_name, totalalocadomb, text)
AS( SELECT a.session_id,
           b.host_name,
           b.login_name,
           ( user_objects_alloc_page_count + internal_objects_alloc_page_count ) * 1.0 / 128 AS totalalocadomb,
           d.TEXT
      FROM        sys.dm_db_session_space_usage a
      JOIN        sys.dm_exec_sessions b ON a.session_id = b.session_id
      JOIN        sys.dm_exec_connections c ON c.session_id = b.session_id
      CROSS APPLY sys.Dm_exec_sql_text(c.most_recent_sql_handle) AS d
     WHERE a.session_id > 50
       AND ( user_objects_alloc_page_count + internal_objects_alloc_page_count ) * 1.0 / 128 > 100 -- Ocupam mais de 100 Mb
)
SELECT * FROM tab
UNION ALL
SELECT null,null,null,sum(totalalocadomb),null FROM tab;

----------------
-- SHRINKFILE --
----------------
--USE TEMPDB
--GO
--DBCC SHRINKFILE (tempDev, 1000)
--DBCC SHRINKFILE (templog, 1000)

----------------------------- 
-- ALTERAR LOCAL DO TEMPDB --
-----------------------------
-- http://msdn.microsoft.com/pt-br/library/ms345408.aspx (Movendo bancos de dados do sistema)

-- Mostra nome l�gico e caminho atual do tempdb
--SELECT name, physical_name AS CurrentLocation
--FROM sys.master_files
--WHERE database_id = DB_ID(N'tempdb');
--GO

---- Procedimento de altera��o
--USE master;
--GO
--ALTER DATABASE tempdb 
--MODIFY FILE (NAME = tempdev, FILENAME = 'D:\Data\tempdb.mdf');
--GO
--ALTER DATABASE tempdb 
--MODIFY FILE (NAME = templog, FILENAME = 'D:\Data\templog.ldf');
--GO

---- REINICIAR A INSTANCIA

---- Mostra nome l�gico e caminho atual do tempdb
--SELECT name, physical_name AS CurrentLocation, state_desc
--FROM sys.master_files
--WHERE database_id = DB_ID(N'tempdb');

------------------------
-- DIVERSOS - ESTUDAR --
------------------------

--No open transactions! Alright, any process holding locks on tempdb?
SELECT * FROM sys.dm_tran_locks WHERE resource_database_id = 2

SELECT * FROM sys.dm_db_session_space_usage WHERE user_objects_alloc_page_count <> 0
-- http://technet.microsoft.com/en-us/library/ms187938%28SQL.90%29.aspx

SELECT * FROM sys.all_objects where is_ms_shipped = 0