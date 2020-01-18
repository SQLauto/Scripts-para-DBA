-- #*#*#*#*#*#*#*#*#*#*#*#*#*
-- # DIVERSOS ADMINISTRA��O #
-- #*#*#*#*#*#*#*#*#*#*#*#*#*

/***************************
 * Informa��es do Servidor *
 ***************************/

--   Processador
--   A matem�tica � bem simples: quanto mais %recouce waits e menos %signal (cpu) waits melhor, quer dizer que, nesse momento 
-- n�o est� havendo problemas de press�o com processador, n�o quer dizer que daqui a 1 segundo n�o comece a ter, mas no momento 
-- da execu��o dessa query n�o havia problema.

Select	signal_wait_time_ms = sum(signal_wait_time_ms)
,		'%signal (cpu) waits' = cast(100.0 * sum(signal_wait_time_ms) / sum (wait_time_ms) as numeric(20,2))
,		resource_wait_time_ms=sum(wait_time_ms - signal_wait_time_ms)
,		'%resource waits'= cast(100.0 * sum(wait_time_ms - signal_wait_time_ms) / sum (wait_time_ms) as numeric(20,2))
From	sys.dm_os_wait_stats 


-- Data da instala��o da Instancia do SQl Server
select	createdate as 'Sql Server Installation Date'
from	sys.syslogins
where	sid = 0x010100000000000512000000

xp_msver 
sp_server_info 

SELECT 	SERVERPROPERTY	('productversion')	as Vers�o
,		SERVERPROPERTY	('productlevel')	as [Service Pack]
,		SERVERPROPERTY	('edition')			as Edi��o
,		@@VERSION							as Completo
,		SERVERPROPERTY	('COLLATION')		as Collation

-- Server Default Collation
sp_helpsort 

-- Configura��es
sp_configure

sp_configure 'Show Advanced Options', 1 -- Para aparecer as op��es avan�adas
reconfigure
go
sp_configure

select * from sys.configurations

-- Tipos de Dados
select * from sys.types
sp_datatype_info 
sp_datatype_info_90 -- N�vel 90

-- Linguagens
sp_helplanguage
select * from syslanguages

--Espa�o em Disco
xp_fixeddrives

-- Servidores / Linked Servers
select * from sys.servers
sp_helplinkedsrvlogin
sp_linkedservers
sp_linkedservers_rowset2
sp_testlinkedserver
sp_helpserver
SP_TABLES_EX 'NomedoLinkedServer' -- Tabelas do LinkedServer

-- Mensagens Padrao do Sistema
select * from sys.messages 

-- Log de Erro
xp_enumerrorlogs
sp_readerrorlog 
xp_readerrorlog

-- Usuarios Conectados / Processos
sp_who 
sp_who2
select * from sysperfinfo -- Informa��es de Performance
select * from sys.sysprocesses
dbcc inputbuffer (<spid>) --Serve para verificar o comando que est� sendo executado.

-- Diversas
xp_enum_oledb_providers
sp_helpdevice
DBCC HELP ('?');

/******************
 * Banco de Dados *
 ******************/
-- Mudando estado do Banco de Dados para Single_User 
Alter Database BaseAlex
 Set Single_User With Rollback Immediate

-- Algumas outras op��es: READ_ONLY, READ_WRITE, RESTRICTED_USER, ONLINE, OFFLINE, EMERGENCY
 
-- Mudando estado do Banco de Dados BaseAlex que esta como Single_User para Multi_User
Alter Database BaseAlex
 Set Multi_User With Rollback Immediate 
  
-- Usando Banco de Dados EstudoSQL
-- http://msdn2.microsoft.com/en-us/library/ms186823.aspx
SELECT DATABASEPROPERTYEX('EstudoSQL','COLLATION') as Collation
SELECT DATABASEPROPERTYEX('EstudoSQL','Status') as Status
SELECT DATABASEPROPERTYEX('EstudoSQL','UserAccess') as Acesso
SELECT DATABASEPROPERTYEX('EstudoSQL','Version') as Vers�o

-- Op��es do Banco de Dados (Settable database options)
sp_dboption 

--N�veis
sp_dbcmptlevel  

-- ***** ESPA�O UTILIZADO *****
-- Espa�o usado pelo log de todas as bases
DBCC SQLPERF(LOGSPACE); 
-- Espa�o utilizado pelo(s) arquivo(s) de dados (Ele d� o resultado em Extends = 64)
DBCC SHOWFILESTATS
-- Espa�o utilizado pela base corrente 
sp_spaceused

/**************
 * SHRINKFILE *
 **************/
-- Diminui arquivos e log
BACKUP LOG tempdb
WITH TRUNCATE_ONLY
-- No Shrink deve usar o Logical Name, no exemplo abaixo � Exemplo_Log, vejo em:
-- Clicando no banco > propriety > files
DBCC SHRINKFILE (N'templog' , 0, TRUNCATEONLY)
--Shrink direto na Base
DBCC SHRINKFILE (N'Exemplo' , 0, TRUNCATEONLY)

-- Informa��es diversas das bases 
sp_databases
sp_helpdb
sp_helpfile -- Informa��es da Base Corrente (Nome, FileID, FileName, Filegroup, size, maxzive, growth, usage)
select * from sys.databases 
select * from sys.database_files  -- Mais completo que a sp_helpfile
select * from sys.master_files -- Informa��es de todas as Bases (Arquivos e Log's)
select * from master.dbo.sysdatabases -- Mostra as Bases + Caminho

-- Encontrar um Banco de Dados informando o nome de uma tabela.
exec master.dbo.sp_msforeachdb
"
	USE [?]
	Select 
			Db_Name()
	From	SysObjects
	Where	Name = 'TbAlex'
" 

/**********************************
 * Estatisticas de Banco de Dados *
 **********************************/
SET STATISTICS TIME ON
Select * from EstudoSQL..TbVenda
SET STATISTICS TIME OFF

sp_autostats TbTeste
sp_createstats
sp_statistics EstudoSQL
sp_statistics_rowset TbTeste
sp_updatestats
sp_monitor -- Leituas / Percentuais (http://msdn.microsoft.com/pt-br/library/ms188912.aspx)
sp_helpstats TbTeste

/*********************************
 * SHOW PLAN - Plano de Execu��o *
 *********************************/
 -- Salvando um Plano de Execu��o (via TSQL) para analise a qualquer momento.
USE DBTeste;
GO
SET SHOWPLAN_XML ON;
GO
 
-- Execute a Query que deseja analisar
SELECT	*
FROM	TbCidades
GO
SET SHOWPLAN_XML OFF;

/* Salve o Resultado como por exemplo:
   > PlanoExecucao_TbCidades.sqlplan 
*/

/****************************
 * Consist�ncia X Estrutura *
 ****************************/
dbcc checkcatalog (EstudoSQL) --verifica a consist�ncia nas tabelas de sistemas de um dado banco de dados.
dbcc checkdb (EstudoSQL) --Verifica estrutura do Banco (http://msdn2.microsoft.com/en-us/library/ms176064.aspx)
dbcc checkalloc -- Verifica a consist�ncia de espa�o em disco atribuindo a estruturas de um determinado banco de dados.
-- Em caso de erro: http://msdn2.microsoft.com/en-us/library/ms186720.aspx
dbcc checkconstraints with all_constraints -- Checa a consistencia de uma determinada constraint ou de todos como � o caso do exemplo.

/********************
 * BACKUP e RESTORE *
 ********************/
--Setando o banco a ser utilizado
USE master;
--Criando um backup. Por padr�o, o backup criado � do tipo FULL
BACKUP DATABASE ControleCD TO DISK='D:\SQL2005\Backup\ControleCD_backup_200804172138.bak';

--Criando um backup do tipo DIFFERENTIAL
USE ControleCD;
BACKUP DATABASE ControleCD TO DISK='D:\SQL2005\Backup\ControleCD_backup_200804172138.bak'
WITH DIFFERENTIAL;

--Criando um backup do LOG
USE ControleCD;
BACKUP LOG ControleCD TO DISK='D:\SQL2005\Backup\ControleCD_backupLog_200804172140.bak';

--Criando Backup de um arquivo somente
USE ControleCD;
BACKUP DATABASE ControleCD FILE='ControleCD' 
	TO DISK=N'D:\SQL2005\Backup\ControleCD_backup_por arquivo_200804172146.bak';

--Criando Backup de um FileGroup
USE ControleCD;
BACKUP DATABASE ControleCD FILEGROUP='PRIMARY' 
	TO DISK='D:\SQL2005\Backup\ControleCD_backup_FG_200804172146.bak';

-- ### Tempo restante para a conclus�o do backup ###
SELECT
		command
,		'EstimatedEndTime' = Dateadd(ms,estimated_completion_time,Getdate())
,		'EstimatedSecondsToEnd' = estimated_completion_time / 1000
,		'EstimatedMinutesToEnd' = estimated_completion_time / 1000 / 60
,		'BackupStartTime' = start_time
,		'PercentComplete' = percent_complete
FROM	sys.dm_exec_requests
WHERE	session_id = <spid da sess�o que esta rodando o backup>

-- Acha o spid da Sess�o
Select @@SPID

-- ### RESTORE ###
--Verifica Cabe�alho do arquivo de backup
RESTORE HEADERONLY 
FROM DISK = N'D:\SQL2005\Backup\ControleCD_backup_200804172138.bak' 
WITH NOUNLOAD;
GO

--Verifica Informa��es Media de Backup
RESTORE LABELONLY 
FROM DISK = N'D:\SQL2005\Backup\ControleCD_backup_200804172138.bak' 

--Verificar se o backup esta completo e legivel.(N�o verifica estrutura)
RESTORE VERIFYONLY
FROM DISK = N'D:\SQL2005\Backup\ControleCD_backup_200804172138.bak'
-- Caso OK aparecer�: The backup set on file 1 is valid.

--Restaurando um Backup de uma base j� existente
USE ControleCD
RESTORE DATABASE ControleCD FROM  DISK = N'D:\SQL2005\Backup\ControleCD_backup_200804172138.bak' WITH REPLACE

--Restaurando um Backup diferencial 
USE master;
RESTORE DATABASE ControleCD FROM DISK='D:\SQL2005\Backup\ControleCD_backup_200804172138.bak' 
WITH NORECOVERY; --Restaurando apenas o Full Backup, com a op��o NORECOVERY
RESTORE DATABASE ControleCD FROM DISK='D:\SQL2005\Backup\ControleCD_backup_200804172138_1.bak' 
WITH RECOVERY; --Restaurando o Differential Backup, com a op��o RECOVERY

--Restaurando um Backup do Log
USE master;
RESTORE LOG ControleCD FROM DISK='D:\SQL2005\Backup\ControleCD_backupLog_200804172140.bak	' WITH RECOVERY;

--Restaurando Backup de um arquivo somente
USE master;
RESTORE DATABASE ControleCD FILE='ControleCD' 
	TO DISK=N'D:\SQL2005\Backup\ControleCD_backup_por arquivo_200804172146.bak';

--Restaurando um Backup de um FileGroup
USE master;
RESTORE DATABASE ControleCD FILEGROUP='PRIMARY' 
	TO DISK='D:\SQL2005\Backup\ControleCD_backup_FG_200804172146.bak';

/*************************************
 * Informa��es relacionada a tabelas *
 *************************************/
-- Informa��es de Tabela (Cria��o / Tipos / Foreign Key / Indices etc)
sp_help TbMde

-- Ver as tabelas do Banco de Dados corrente
sp_tables 
select * from sys.tables 
select * from sysobjects obj where obj.type = 'u'

-- Colunas
sp_columns <nome da tabela> 
select * from sys.columns
select * from syscolumns

-- Privilegios 
	-- Tabelas
		sp_table_privileges <nome da tabela> 
		sp_table_privileges_rowset <nome da tabela>
	-- Colunas
		sp_column_privileges TbTeste
		sp_column_privileges_rowset TbTeste

-- Collations de Tabelas
sp_tablecollations <nome da tabela> 
sp_tablecollations_90 <nome da tabela>

-- Depend�ncia de tabelas
sp_depends tbObj

-- Renomear tabela
Exec sp_rename 'TbTeste', 'TbTeste1'

-- Colocando resultado de uma Query em uma NOVA TABELA
Select  Func.NmFunc
,       Func.VrSalFunc
-- Vou armazenar nesta tabela (TbAuxiliarFuncionario) apenas o Nome e o Salario dos funcion�rios
INTO    TbAuxiliarFuncionario -- � s� Adicionar esta linha
From    TbFunc as Func

/***********************
 * Dicion�rio de Dados *
 ***********************/
Select distinct 
	Tabela = obj.name
,	Coluna = col.name
from	sysobjects obj
join	syscolumns col on col.id = obj.id
where	obj.type = 'u'
Order by
	obj.name
,	col.name

/*********************************
 * Informa��es de Chave Prim�ria *
 *********************************/
--Script que apresenta tabelas sem Primary Key: 
SELECT 
		u.name
,		o.name
FROM	sysobjects o
INNER JOIN sysusers u ON o.uid = u.uid
WHERE xtype = 'U' AND NOT EXISTS
	(SELECT i.name FROM sysindexes i WHERE o.id = i.id AND (i.status & 2048)<>0)

--Script que apresenta tabelas com Primary Key e as respectivas PKs:
SELECT 
		u.name
,		o.name
,		i.name
FROM	sysobjects o
INNER JOIN sysindexes i ON o.id = i.id
INNER JOIN sysusers u ON o.uid = u.uid
WHERE (i.status & 2048)<>0

/***********************************
 * Informa��es de Chave Segund�ria *
 ***********************************/
use ControleCD
sp_foreign_keys_rowset TbAutor
sp_fKeys <nometabela>

-- Checar consist�ncia de tabelas.
USE AdventureWorks;
GO
DBCC CHECKTABLE ('HumanResources.Employee');

/**************
 * Filegroups *
 **************/
select * from sys.filegroups

/***********
 * Ind�ces *
 ***********/
sp_helpindex <nome da tabela> 

-- Mostra Tabelas sem indices do BD corrente
Select 
			object_name(i.id) 
From		sysindexes i
inner join	sysobjects o ON i.id = o.id
Where		indid = 0 
AND			xtype = 'U'

-- Como saber rapidamente se sua tabela precisa ou n�o de um �ndice
-- Exemplo:
USE AdventureWorks;
GO
SELECT City, StateProvinceID, PostalCode
FROM Person.Address
WHERE StateProvinceID = 9;
GO
-- O retorno ser� 4564 linhas e ser� executada menos de um segundo.
-- Mas, ser� que quando tivermos milh�es de registros, o desempenho vai cair ?
-- Para saber isso execute logo em seguida a seguinte view din�mica:
Select * From sys.dm_db_missing_index_details
-- Retornara qual a coluna que dever� ter o indice, no caso: equality_columns = StateProvinceID 

-- Apresenta a data da �ltima altera��o em cada �ndice nas tabelas de usu�rio no banco de dados corrente.
Select
		tabelas.name as 'Nome da Tabela'
,		indices.name as 'Nome do Indice'
,		indices.type_desc as 'Tipo de Indice'
,		STATS_DATE(indices.object_id,indices.index_id) as 'Ultima Atualiza��o'
From	sys.indexes indices 
join	sys.tables tabelas on tabelas.object_id = indices.object_id 
Where	indices.type > 0
Order by 
		tabelas.name ASC 
,		indices.type_desc ASC 
,		indices.name ASC

/***************
 * Reindexa��o *
 ***************/
-- 1� Maneira
USE AdventureWorks; 
GO
DBCC DBREINDEX ('HumanResources.Employee', '', 70);

-- 2� Maneira
-- Pega informa��es de todas as tabelas do banco corrente e deixa no layout de reindexa��o
select 'dbcc dbreindex(' + name + ')' from sysobjects where type = 'u' 
dbcc dbreindex <nome da tabela>

/*****************************
 * Usu�rios / Grupos / Senha *
 *****************************/
sp_helpuser -- Usuarios
sp_helplogins -- Informa��es sobre Logins
xp_loginconfig -- Configura��o de Login
xp_logininfo

-- Adicionar Login
sp_addlogin 'login', 'senha'
--Trocar senha
sp_password @new = 'senha', @loginame = 'login'

-- Associando usuario a login
exec SP_GRANTDBACCESS 'Login','usr' 

-- Libeando acessos ao usu�rio
-- DCL (DATA CONTROL LANGUAGE)
GRANT SELECT ON TB_PERM TO J
GRANT INSERT ON TB_PERM TO J
-- DENY
DENY SELECT ON TB_PERM TO J
-- REVOKE
REVOKE INSERT ON TB_PERM TO J
GRANT CREATE TABLE TO J

-- Libeando acessos ao Schemas
GRANT SELECT ON SCHEMA::nomeschema to usr

sp_helprole -- Lista os Database's Roles
sp_helpsrvrole -- Lista os Server's Roles
sp_srvrolepermission -- Permiss�es Server Roles
sp_helpsrvrolemember -- Membros por Server Roles

-- Adicionando ou removendo um Login de um Server Role
exec sp_addsrvrolemember 'login', 'role name'  -- Adiciona
exec sp_dropsrvrolemember 'login', 'role name' -- Remove

-- Listar os membros das Roles de Servidor
SELECT sRole.name AS [Server Role Name] , sPrinc.name AS [Members],
'EXEC master..sp_addsrvrolemember @loginame = N''' + sPrinc.name + ''', @rolename = N''' + sRole.name + ''''
FROM sys.server_role_members AS sRo
JOIN sys.server_principals AS sPrinc ON sRo.member_principal_id = sPrinc.principal_id
JOIN sys.server_principals AS sRole ON sRo.role_principal_id = sRole.principal_id;

-- Listar as permiss�es a n�vel de Servidor
SELECT pe.state_desc, pe.permission_name,PR.NAME,
PE.state_desc COLLATE SQL_LATIN1_GENERAL_CP1_CI_AI + ' ' + PE.permission_name + ' TO ' + PR.name
FROM SYS.SERVER_PERMISSIONS PE
JOIN SYS.SERVER_PRINCIPALS PR ON (PE.GRANTEE_PRINCIPAL_ID = PR.PRINCIPAL_ID)
--WHERE PR.name NOT LIKE '##%' --remover logins de sistema relacionados a certificados
--AND PE.PERMISSION_NAME <> 'CONNECT SQL'  --remover a listagem de permiss�es de conectar ao servidor
ORDER BY PR.NAME


/*-------------------------------*
 * Exemplos relacionados a ROLES *
 *-------------------------------*/
USE DBTeste

-- Criando uma tabela para teste
CREATE TABLE TbEstudoRoles (
	CdEstudoRoles INT identity (1,1)
,	NmEstudoRoles varchar(10))

-- Inserindo uma Linha
insert into TbEstudoRoles values ('ROLES')

-- Alguns Select's
select * from TbEstudoRoles
select * from dbo.TbEstudoRoles

-- Criando um ROLE especifico
CREATE ROLE EstudoRoles

-- Liberando acessos ao ROLE criado
GRANT SELECT ON TBEstudoRoles TO EstudoRoles

-- Adicionando membros ao ROLE criado
SP_ADDROLEMEMBER 'EstudoRoles','usuario'

-- Removendo membros do ROLE criado
SP_DROPROLEMEMBER 'EstudoRoles','usuario'

-- Restrigindo acessos a um usuario em especifico, neste caso tem prioridade em rela��o aos direitos do ROLE
DENY SELECT ON TBEstudoRoles TO usuario

-- Verificar as permiss�es de um usuario em especifico
sp_helpuser 'usuario'

-- Verificar as permiss�es de um ROLE especifico
sp_helprolemember 'EstudoRoles'
-- ***** Fim de exemplos relacionados a ROLES *****

-- Trabalhando com Grupos
sp_helpgroup
xp_enumgroups

--Apresentar a �ltima vez em que a SENHA foi alterada.
use master
go
Select 
		[name]
,		sid
,		create_date
,		modify_date
From	sys.sql_logins

-- Usu�rios sem SENHA
use master
go
Select 
		name
,		password 
From	syslogins
Where	password is null 
and		name is not null 
and		isntname = 0

--	Alterar Status de Login (Habilitar e Desabilitar)
ALTER LOGIN sa ENABLE;

--	Alterar senha do login sa
/* 
	1. Entre como Administrador no servidor que se encontra o SQL
    2. Abra o Query Analiser ou SQL Server Management Studio com Windows Authentication (Authentication)
    3. Execute o comando abaixo */
sp_password @new = 'senha', @loginame = 'sa'

-- Cores de Comandos
output, int		-- Comandos e tipos
sp_who			-- Stored Procedures
sys.databases	-- Fun��es de Sistemas
getdate			-- Formatos 
is null			-- Palavras reservadas

--Uma forma pr�tica de identificar as permiss�es de um determinado usu�rio:
USE AdventureWorks;
Execute AS usuario
SELECT * 
FROM fn_my_permissions(NULL, 'Database') 
ORDER BY subentity_name, permission_name ; 
REVERT;
GO

--Outro exemplo agora com os direitos da instancia:
USE AdventureWorks;
SELECT * 
FROM fn_my_permissions(NULL, 'SERVER'); 
GO 
   
--Exemplo com os direitos do Database
USE AdventureWorks;
SELECT * 
FROM fn_my_permissions('AdventureWorks', 'DATABASE'); 
GO 
   
--Exemplo com os direitos das Tabelas
USE AdventureWorks;
SELECT * 
FROM fn_my_permissions('HumanResources.Employee', 'OBJECT') 
ORDER BY subentity_name, permission_name ; 
GO 

/* ####################
   # EM CASO DE ERROS #
   ####################
> COMO INICIAR O SQL SERVER EM SINGLE USER MODE
Para opera��es especiais � necess�rio que o SQL Server seja inciado em single user mode, 
como por exemplo, para restaurar o banco de dados MASTER. Essa � uma tarefa simples:
>> No prompt de comando, posicione-se na pasta BINN, para encontrar o arquivo sqlservr.exe 
dependendo da sua instala��o.
>>> Ex: C:\Arquivos de programas\Microsoft SQL Server\MSSQL.1\MSSQL\Binn
>>>> Se for uma inst�ncia default, digite: sqlservr.exe -c -m
>>>> Se for uma inst�ncia nomeada, digite: sqlservr.exe -c -s instancename -m 

> CONFIGURA��O ALTERADA...SQL SERVER N�O INICIALIZA...
Imaginem o seguinte cen�rio: Uma sexta feira no final do expediente voce resolve realizar 
altera��es na configura��o do seu servidor de banco de dados.
Ap�s as altera��es, o servidor solicita uma reinicializa��o, quando ele retorna voce descobre 
que o servi�o do SQL Server n�o inicializou.
E agora? O que fazer? � preciso um "undo".... Sem desespero, voce digita a seguinte linha de 
comando e reconfigure seu SQL Server para o estado anterior ao desastre:
>> sqlservr.exe -f
>>> Reinicialize o servi�o do SQL Server e... Pronto !Espero nunca precisar utilizar... hehehe */

/********************************************************************
 *	Eliminando o cache de mem�ria no SQL Server (STORED PROCEDURES) *
 ********************************************************************
	Como realizar a limpeza e libera��o de mem�ria cache utilizada pelas stored procedures no SQL Server.
	O cache de mem�ria, � uma �rea reservada pelo SQL Server, como o objetivo de acelerar a execu��o de 
Stored Procedures, ou transa��es podem estar sendo processadas com maior frequ�ncia.
Atrav�s dos comandos DBCC DropCleanBuffers, DBCC FreeProcChace e DBCC FreeSystemCache, podemos realizer 
os seguintes procedimentos: */
 
--1 -  Eliminar as p�ginas de buffer limpas
DBCC DROPCLEANBUFFERS
 
--2 - Eliminar todas as entradas do CACHE de "Procedures"
DBCC FREEPROCCACHE
 
--3 - Limpar as entradas de Cache n�o utilizadas
DBCC FREESYSTEMCACHE ( 'ALL' )