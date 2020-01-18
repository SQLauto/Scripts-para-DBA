-- http://msdn.microsoft.com/pt-br/library/ms345408.aspx (Movendo bancos de dados do sistema)

-- Mostra nome l�gico e caminho atual do tempdb
SELECT name, physical_name AS CurrentLocation
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');
GO

-- Procedimento de altera��o
USE master;
GO
ALTER DATABASE tempdb 
MODIFY FILE (NAME = tempdev, FILENAME = 'D:\Data\tempdb.mdf');
GO
ALTER DATABASE tempdb 
MODIFY FILE (NAME = templog, FILENAME = 'D:\Data\templog.ldf');
GO

-- REINICIAR A INSTANCIA

-- Mostra nome l�gico e caminho atual do tempdb
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');


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
SELECT SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

-- Determinando o volume de espa�o usado pelo armazenamento de vers�o
SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM sys.dm_db_file_space_usage;

-- Determinando a transa��o mais longa em execu��o
SELECT transaction_id
FROM sys.dm_tran_active_snapshot_database_transactions 
ORDER BY elapsed_time_seconds DESC;

-- Determinando o volume de espa�o usado por objetos internos
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage;

-- Determinando o volume de espa�o usado por objetos do usu�rio
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage;