/************************
 * SQL Server - TUNNING *
 ************************/
----------------
-- CHECKPOINT --
----------------
-- http://msdn.microsoft.com/pt-br/library/ms188748.aspx

CHECKPOINT

------------------
--  Estat�sticas --
-------------------
--> Estat�sticas s�o utilizadas pelo QueryOptimizer do SGBD do SqlServer 2005 para decidir qual 
-- �ndice traria maior benef�cio para encontrar os elementos de uma consulta.

-- http://www.linhadecodigo.com.br/artigo/704/SQL-Server-Melhorando-a-performance-atrav%C3%A9s-das-estat%C3%ADsticas.aspx

-- Valores setados para AUTO_CREATE_STATS e AUTO_UPDATE_STATS
SELECT name AS "Name", 
    is_auto_create_stats_on AS "Auto Create Stats",
    is_auto_update_stats_on AS "Auto Update Stats",
    is_read_only AS "Read Only" 
FROM sys.databases
WHERE database_ID > 4;
GO

-- Ver as Estatisticas de uma Banco ou Tabela
USE TopManagerTeste;
GO
SELECT OBJECT_NAME(s.object_id) AS object_name,
    COL_NAME(sc.object_id, sc.column_id) AS column_name,
    s.name AS statistics_name
FROM sys.stats AS s Join sys.stats_columns AS sc
    ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id
WHERE s.name like '_WA%'
and		OBJECT_NAME(s.object_id) = 'TbObj' -- Por Tabela
ORDER BY s.name;

-- Para ver as informa��es estat�sticas de um �ndice  
DBCC SHOW_STATISTICS ('TbObj', 'Pk_TbObj')
--(DBCC SHOW_STATISTICS) 
-- http://technet.microsoft.com/pt-br/library/ms174384.aspx

-- Atualizar Estatisticas do Banco
-- SP_UPDATESTATS

-- Por tabela
UPDATE STATISTICS [dbo].[TbRcd]

-- Por indice
UPDATE STATISTICS TbMde I_MdeBcb

-- Estatisticas em XML (Identificar Missing Index)
SET STATISTICS XML ON
Select Top 100 * From TbLds
SET STATISTICS XML OFF

-- DROP STATISTICS TbMde._WA_Sys_00000003_4BA90D9E;


-------------------------
-- SQL SERVER PROFILER --
-------------------------
-- Informa��es para o PROFILE (Maiores que 5 Segundos)
/*
Trace Properties � Events Selection
                Marcar as op��es:
                Stored Procedures
                               SP: Completed
                               SP: StmtCompleted
							   RPC:Completed
                T-SQL
                               SQL: BatchCompleted
                               SQL: BatchStarting
                               SQL: StmtCompleted
                Transactions
                               TM: Commit Tran completed
               
Trace Properties � Column Filters
                Desmarcar a op��o 'Exclude rows that do not contain values'
*/

-- Observa��es
---> Em todas consultas que est�o demorando, analizar o plano de execu��o.
---> Table scans devem ser eliminados.
---> Analizaro XML do plano de execu��o para identificar missing indexes
---> Missing indexes devem ser criados (na maioria dos casos).

-------------
-- �NDICES --
-------------
-- ClusteredIndex    --> �ndices cluster cont�m os dados da tabela no n�vel folha (8060 bytes).
-- NonClusteredIndex --> �ndices noncluster cont�m ponteiros para os dados no n�vel folha.

-- FillFactor: http://technet.microsoft.com/pt-br/library/ms177459.aspx

-- Cria��o de um �ndice: CREATE INDEX <nomeIndice> ON <Tabela>(Campo) INCLUDE (Campos)  
-- Exemplo:
-- CREATE INDEX I_TbPes_NmPesON TbPes(NmPes) INCLUDE(TpPes)

-- Informa��es de uma tabela
exec sp_help TbRcd

-- Espa�o utilizado por uma tabela (http://msdn.microsoft.com/pt-br/library/ms188776.aspx)
exec sp_spaceused 'TbRcd', @updateusage = N'TRUE';

-- Informa��es do �ndice
sp_helpindex TbRct

-- Split (Divis�o de P�ginas)
Select  AllocUnitName
,		COUNT(*) as Splits
From    ::fn_dblog(null, null)
Where Operation = 'LOP_DELETE_SPLIT'
Group by allocUnitName
Order by COUNT(*) desc

-- Modo 2
Declare @Tabela varchar(100)
Set		@Tabela = 'TbRcd'

Select	idx.*
From	sys.indexes idx
join	sys.objects obj on obj.object_id = idx.object_id
Where	obj.name = @Tabela


-- Indices, Colunas e includes
select	i.object_id
,		i.name
,		i.type_desc
,		c.name
,		*
from	sys.index_columns ic
join	sys.indexes i on i.object_id = ic.object_id and i.index_id = ic.index_id
join	sys.columns c on c.object_id = ic.object_id and c.column_id = ic.column_id
Where	i.object_id = 123563924


-- Informa��es de �ndices (Clustered, nonclusteres, unicos e etc)
Select	o.name
,		i.name 
From	sys.indexes i
join	sys.objects o on o.object_id = i.object_id and o.type = 'U'
Where	i.type = 2 --(0 - HEAP; 1 - CLUSTERED; 2 - NONCLUSTERED)
and		i.object_id > 100
--and	i.is_unique = 1 -- (INDICES UNICOS)
and		i.is_unique = 0 -- (N�O UNICOS)
Order by
		o.name

-- ************************************************
-- * Consulta a utiliza��o dos �ndices por tabela *
-- ************************************************
SELECT		DB_NAME(database_id) As Banco
,			OBJECT_NAME(I.object_id) As Tabela
,			I.Name As Indice
,			U.User_Seeks As Pesquisas	-- N�mero de buscas atrav�s de consultas de usu�rio. 
,			U.User_Scans As Varreduras	-- N�mero de exames atrav�s de consultas de usu�rio. 
,			U.User_Lookups As LookUps	-- N�mero de pesquisas de indicador atrav�s de consultas de usu�rio.
,			U.User_updates AS Updates
,			U.Last_User_Seek As UltimaPesquisa
,			U.Last_User_Scan As UltimaVarredura
,			U.Last_User_LookUp As UltimoLookUp
,			U.Last_User_Update As UltimaAtualizacao
FROM		sys.indexes As I
LEFT JOIN	sys.dm_db_index_usage_stats As U ON I.object_id = U.object_id AND I.index_id = U.index_id
JOIN		sys.objects As Obj ON Obj.object_id = I.object_id
WHERE	DB_NAME(database_id) = 'TopManager'
and		I.object_id = OBJECT_ID('TbRcd')
--and		U.User_Seeks < 10 -- Somente com menos de 10
--and		U.User_Scans < 10 -- Somente com menos de 10
--and		U.User_Lookups < 10 -- Somente com menos de 10

-- **********************************************
-- * Quantidade de Indices e Colunas por Tabela *
-- **********************************************
Select	Tabela = o.name
,		[Qtd de Indices] = Count(o.name)
,		[Qtd de Colunas] = (Select count(*) From sys.columns Where object_id = o.object_id)
From	sys.indexes i
join	sys.objects o on o.object_id = i.object_id and o.type = 'U'
Group by
		o.name
,		o.object_id
Order by
		Count(o.name) desc

-- **************************
-- * �NDICES N�O UTILIZADOS *
-- **************************
/* Parte(A) identifica �ndices sem entrada na DMV 'dm_db_index_usage_stats', isto indica que o �ndice nunca foi utilizado desde a inicializa��o do SQL Server */
SELECT DB_NAME(), OBJECT_NAME(i.object_id) AS 'Table', ISNULL(i.name, 'heap') AS 'Index', x.used_page_count AS 'SizeKB'
FROM sys.objects o
INNER JOIN sys.indexes i
ON i.[object_id] = o.[object_id]
LEFT JOIN sys.dm_db_index_usage_stats s
ON i.index_id = s.index_id and s.object_id = i.object_id
LEFT JOIN sys.dm_db_partition_stats x
ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
WHERE OBJECT_NAME(o.object_id) IS NOT NULL AND OBJECT_NAME(s.object_id) IS NULL
AND o.[type] = 'U' AND ISNULL(i.name, 'heap') <> 'heap'

UNION ALL

/* Parte(B) identifica �ndices que n�o s�o mais utilizados desde a inicializa��o da inst�ncia do SQL Server */
SELECT DB_NAME(), OBJECT_NAME(i.object_id) AS 'Table', ISNULL(i.name, 'heap') AS 'Index', x.used_page_count AS 'SizeKB'
FROM sys.objects o
INNER JOIN sys.indexes i
ON i.[object_id] = o.[object_id]
LEFT JOIN sys.dm_db_index_usage_stats s
ON i.index_id = s.index_id and s.object_id = i.object_id
LEFT JOIN sys.dm_db_partition_stats x
ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
WHERE user_seeks = 0 AND user_scans = 0 AND user_lookups = 0
AND o.[type] = 'U' AND ISNULL(i.name, 'heap') <> 'heap'
ORDER BY 2 ASC


-- EXEMPLO DE REORGANIZE E REBUILD:
-- REORGANIZE
ALTER INDEX PK_Teste	ON TbTeste REORGANIZE; -- Por �ndice
ALTER INDEX ALL			ON TbTeste REORGANIZE;

-- REBUILD
-- *** Se o banco estiver em produ��o e for SQL 2005 Enterprise, utilize a op��o ONLINE = ON ***
ALTER INDEX PK_Teste	ON TbTeste REBUILD;
ALTER INDEX ALL			ON TbTeste REBUILD;

-- Pega informa��es de todas as tabelas do banco corrente e deixa no layout de reindexa��o
Select 'dbcc dbreindex(' + name + ')' From sysobjects Where type = 'u'

-- ANALISE INDIVIDUAL DE FRAGMENTA��O DE �NDICE
-- http://www.sqlmagazine.com.br/Colunistas/PauloRibeiro/06_Performance_Defragmentando.asp
-- Avg. Page Density (full)               --> Proximo a 100% (OK)
-- Scan Density [Best Count:Actual Count] --> Proximo a 100% (OK)

DBCC SHOWCONTIG ('TbLds','I_LdsCdLdsses')
ALTER INDEX I_LdsCdLdsses ON TbLds REBUILD; -- RECRIANDO O �NDICE

-- Auxiliar
Declare @Tabela varchar(100)
Set		@Tabela = 'TbRcd'

Select	'DBCC SHOWCONTIG (''' + obj.name + ''',''' + idx.name + ''');'
From	sys.indexes idx
join	sys.objects obj on obj.object_id = idx.object_id
Where	obj.name = @Tabela

Select	'ALTER INDEX ' + idx.name + ' ON ' + obj.name + ' REBUILD;'
From	sys.indexes idx
join	sys.objects obj on obj.object_id = idx.object_id
Where	obj.name = @Tabela

-------------------------------------
--  FRAGMENTA��O EXTERNA E INTERNA --
-------------------------------------
--http://msdn.microsoft.com/pt-br/library/ms188917.aspx -- DOCUMENTA��O DA sys.dm_db_index_physical_stats

--> FRAGMENTA��O EXTERNA - Ocorre quando as p�ginas dos �ndices n�o est�o fisicamente ordenadas.

-- (Fragmenta��o Externa) Quando for maior do que 5% e menor do que 30%.(avg_fragmentation_in_percent) -- REORGANIZE
-- (Fragmenta��o Externa) Quando for maior que 30%.(avg_fragmentation_in_percent)                       -- REBUILD

Declare @Database Varchar(100)
Set		@Database = 'IVT' -- Informe aqui o nome do banco de dados

SELECT	Tabela = OBJECT_NAME(dt.object_id)
,		si.name
,		dt.avg_fragmentation_in_percent as [Fragmenta��o Externa]
,		CASE	WHEN dt.avg_fragmentation_in_percent between 5 and 30 THEN 'REORGANIZE'
				WHEN dt.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
		ELSE	'OK'
		END		as [Indexa��o]
FROM	(SELECT object_id, index_id, avg_fragmentation_in_percent, avg_page_space_used_in_percent
		 FROM sys.dm_db_index_physical_stats (DB_ID(@Database), NULL, NULL, NULL, 'DETAILED')
		 WHERE index_id <> 0) AS dt
INNER JOIN sys.indexes si ON si.object_id = dt.object_ID AND si.index_id = dt.index_id
Order by
		dt.avg_fragmentation_in_percent desc -- Fragmenta��o Externa

--> FRAGMENTA��O INTERNA - Faz com que o espa�o em disco n�o seja utilizado de forma eficiente 
-- fazendo com que sejam utilizadas mais p�ginas do que o necess�rio.

-- (Fragmenta��o Interna) Quando for menor do que 75% e maior do que 60%.(avg_page_space_used_in_percent) -- REORGANIZE
-- (Fragmenta��o Interna) Quando for menor que 60% .(avg_page_space_used_in_percent)                      -- REBUILD

Declare @Database Varchar(100)
Set		@Database = 'IVT' -- Informe aqui o nome do banco de dados

SELECT	Tabela = OBJECT_NAME(dt.object_id)
,		si.name
,		dt.avg_page_space_used_in_percent as [Fragmenta��o Interna]
,		CASE	WHEN dt.avg_page_space_used_in_percent between 60 and 75 THEN 'REORGANIZE'
				WHEN dt.avg_page_space_used_in_percent < 60 THEN 'REBUILD'
		ELSE	'OK' 
		END as [Indexa��o]
FROM	(SELECT object_id, index_id, avg_fragmentation_in_percent, avg_page_space_used_in_percent
		 FROM sys.dm_db_index_physical_stats (DB_ID(@Database), NULL, NULL, NULL, 'DETAILED')
		 WHERE index_id <> 0) AS dt
INNER JOIN sys.indexes si ON si.object_id = dt.object_ID AND si.index_id = dt.index_id
Order by
		dt.avg_page_space_used_in_percent desc -- Fragmenta��o Interna


-- FRAGMENTA��O EXTERNA - POR TABELA
Declare @Database Varchar(100)
Declare @Tabela int

Set		@Database = 'TopManager' -- Informe aqui o nome do banco de dados
Set		@Tabela = (Select object_id From sys.objects Where name = 'TbRcd')

SELECT	IDX.name
,		PHS.avg_fragmentation_in_percent as [Fragmenta��o Externa]
,		CASE	WHEN PHS.avg_fragmentation_in_percent between 5 and 30 THEN 'REORGANIZE'
				WHEN PHS.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
		ELSE	'OK'
		END		as [Indexa��o]
,		CASE	WHEN PHS.Index_level = 0 THEN 'N�vel FOLHA'
		ELSE	'N�vel N�O FOLHA'
		END
FROM	sys.dm_db_index_physical_stats (DB_ID(@Database), NULL, NULL, NULL, 'LIMITED') PHS -- Somente n�vel folha
--FROM	sys.dm_db_index_physical_stats (DB_ID(@Database), NULL, NULL, NULL, 'DETAILED') PHS -- Todos n�veis
JOIN	sys.indexes IDX ON IDX.object_id = PHS.object_ID AND IDX.index_id = PHS.index_id
WHERE	PHS.index_id <> 0
and		PHS.object_id = @Tabela
Order by
		PHS.avg_fragmentation_in_percent desc -- Fragmenta��o Externa


-- FRAGMENTA��O INTERNA - POR TABELA
Declare @Database Varchar(100)
Declare @Tabela int

Set		@Database = 'TopManager' -- Informe aqui o nome do banco de dados
Set		@Tabela = (Select object_id From sys.objects Where name = 'TbRcd')

SELECT	Tabela = OBJECT_NAME(dt.object_id)
,		si.name
,		dt.avg_page_space_used_in_percent as [Fragmenta��o Interna]
,		CASE	WHEN dt.avg_page_space_used_in_percent between 60 and 75 THEN 'REORGANIZE'
				WHEN dt.avg_page_space_used_in_percent < 60 THEN 'REBUILD'
		ELSE	'OK' 
		END as [Indexa��o]
FROM	(SELECT object_id, index_id, avg_fragmentation_in_percent, avg_page_space_used_in_percent
		 FROM sys.dm_db_index_physical_stats (DB_ID(@Database), NULL, NULL, NULL, 'DETAILED')
		 WHERE index_id <> 0) AS dt
INNER JOIN sys.indexes si ON si.object_id = dt.object_ID AND si.index_id = dt.index_id
WHERE	dt.index_id <> 0
and		dt.object_id = @Tabela
Order by
		dt.avg_page_space_used_in_percent desc -- Fragmenta��o Interna


-- *******************************************************************
-- * Listando as p�ginas de dados usadas e reservadas para a tabela. *
-- *******************************************************************
SELECT		au.*
FROM		sys.allocation_units au
INNER JOIN	sys.partitions p ON au.container_id = p.partition_id
WHERE		p.object_id = object_id('TbTra')
-- http://msdn.microsoft.com/pt-br/library/ms189792.aspx  (sys.allocation_units)

/* Atrav�s da sa�da acima podemos observar as colunas total_pages, used_pages, data_pages na coluna Total_pages 
retorna o total de p�ginas alocadas para a tabela inclu�ndo p�ginas IAM que s�o para controle do SQL Server, 
como em nosso exemplo inserimos 3 valores foram criadas 3 p�ginas de dados. Na coluna Used_Pages como o nome 
j� diz, � retornado todas as p�ginas de dados usadas pela tabela incluindo a p�gina IAM, � diferente da coluna 
Total_pages de qual lista as p�ginas alocadas, que n�o necess�riamente est�o usadas pela tabela, supondo que 
inserimos mais 6 linhas, nossa tabela teria 9 p�ginas de dados com isso o SQL Server iria alocar um extend 
uniforme para a tabela, com isso a coluna Total_pages retornaria 17 p�ginas (16 p�ginas de dados alocadas + 1 
p�gina IAM) e a coluna Used_pages retornariam 10 p�ginas (9 p�ginas de dados + 1 p�gina IAM). Na coluna 
Data_pages � retornado somente as p�ginas utilizadas como p�ginas de dados para a tabela, em nosso exemplo 
3 p�ginas de dados. */
-- http://felipesantanadba.wordpress.com/2010/04/05/usando-dmv%C2%B4s-para-consultar-metadados-de-uma-tabela/


/* http://pedrogalvaojunior.wordpress.com/2009/04/13/trabalhando-com-sys-dm_db_index_physical_stats-no-sql-server-2008-final/
Avaliando o uso do espa�o em disco
A coluna avg_page_space_used_in_percent indica que a p�gina est� cheia. Para se obter um �timo uso do espa�o em 
disco, esse valor dever� estar perto de 100% para um �ndice que n�o ter� muitas inser��es aleat�rias. Entretanto, 
um �ndice que tem muitas inser��es aleat�rias e p�ginas muito cheias ter� um n�mero maior de divis�es de p�gina. 
Isso causa mais fragmenta��o. Por isso, para reduzir as divis�es de p�gina, o valor deve ser menor que 100%. 
A recria��o de um �ndice com a op��o FILLFACTOR especificada permite que o preenchimento da p�gina seja alterado para
atender ao padr�o de consulta do �ndice. Avaliando fragmentos de �ndice

Um fragmento � composto de p�ginas de folha fisicamente consecutivas no mesmo arquivo de uma unidade de aloca��o. 
Um �ndice tem pelo menos um fragmento. O m�ximo de fragmentos que um �ndice pode ter � igual ao n�mero de p�ginas no 
n�vel de folha do �ndice. Fragmentos maiores indicam que menos E/S de disco � necess�ria para ler o mesmo n�mero de p�ginas. 
Por isso, quanto maior o valor avg_fragment_size_in_pages, melhor o desempenho de exame de intervalo. Os valores 
avg_fragment_size_in_pages e avg_fragmentation_in_percent s�o inversamente proporcionais entre si. Por isso, a reconstru��o 
ou a reorganiza��o de um �ndice deve reduzir a quantidade de fragmenta��o e aumentar o tamanho do fragmento.
*/

-- Exemplo de parti��o e unidade de aloca��o
USE FAE;
GO
SELECT o.name AS table_name,p.index_id, i.name AS index_name , au.type_desc AS allocation_type, au.data_pages, partition_number
FROM sys.allocation_units AS au
    JOIN sys.partitions AS p ON au.container_id = p.partition_id
    JOIN sys.objects AS o ON p.object_id = o.object_id
    JOIN sys.indexes AS i ON p.index_id = i.index_id AND i.object_id = p.object_id
WHERE o.name = 'TbLds'
ORDER BY o.name, p.index_id;

---------------------------------
-- QUERYS AUXILIARES (�NDICES) --
---------------------------------
-- Identificando aus�ncia de �ndices (Identifica os �ndices que poss�velmente devam ser criados)
---> O SQL Server 2005 guarda informa��o sobre os �ndices que foram necess�rios mas n�o foram encontrados. (DMF)
---> Estas informa��es podem ser acessadas atrav�s das views:
----> sys.dm_db_missing_index_group_stats
----> sys.dm_db_missing_index_groups
----> sys.dm_db_missing_index_details

---> 1. indexes_Identifica os indices que precisam ser criados

SELECT	index_advantage AS Advantage -- Vantagem percentual para as queries que precisaram destes �ndices. Na linha 1, a vantagem � de (718 + 100) / 100, 818%.
,		mid.object_id AS ID
,		mid.Statement AS TableStatement -- TableStatement � composto por nome do banco + owner+ tabela
,		mid.Equality_columns AS Equality -- Colunas que aparecem em equality, representam as colunas onde o filtro foi feito com operadores de igualdade ( =, is)
,		mid.inequality_columns AS Inequality -- As colunas que aparecem em inequality, representam as colunas onde o filtro foi feito com outros operadores ( <> , >, <, etc...)
,		included_columns AS Included -- Included s�o as colunas que ser�o facilmente plotadas pelo �ndice, pois participar�o da folha na �rvore B.
,		mig.index_handle AS Handler
FROM(
	SELECT (user_seeks + user_scans) * avg_total_user_cost * (avg_user_impact * 0.01) AS index_advantage, migs.* 
		FROM sys.dm_db_missing_index_group_stats migs 
	) AS migs_adv, 
   sys.dm_db_missing_index_groups mig, 
   sys.dm_db_missing_index_details mid 
WHERE	migs_adv.group_handle = mig.index_group_handle 
and		mig.index_handle = mid.index_handle
and		index_advantage > 0
--and	mid.Statement = '[TopManager].[dbo].[TbRcd]'
ORDER BY 
		migs_adv.index_advantage DESC

/*	Para criar indices com estas informa��es, basta usar:
	- TableStatement como a tabela onde o �ndice deve ser criado
	- Equality e Inequality como as colunas onde o �ndice deve ser criado
	- Included como as colunas que devem estar inclu�das no �ndice. */

--> Monta as Querys para a cria��o dos �ndices
---> 2. indexes_Monta as querys de cria�ao dos indices

DECLARE @MIN_INDEX_ADVANTAGE AS INT
DECLARE @Advantage AS NUMERIC(10,3)
DECLARE @ID AS INT
DECLARE @TableStatement AS VARCHAR(80)
DECLARE @Equality AS VARCHAR(1000)
DECLARE @Inequality AS VARCHAR(1000)
DECLARE @Included AS VARCHAR (8000)
DECLARE @Handler AS INT

SET		@MIN_INDEX_ADVANTAGE = 0

DECLARE MissingIndexes CURSOR FOR
SELECT index_advantage AS Advantage, mid.object_id AS ID, mid.Statement AS TableStatement, mid.Equality_columns AS Equality, mid.inequality_columns AS Inequality, included_columns AS Included, mig.index_handle AS Handler 
FROM(
	SELECT (user_seeks + user_scans) * avg_total_user_cost * (avg_user_impact * 0.01) AS index_advantage, migs.* 
		FROM sys.dm_db_missing_index_group_stats migs 
	) AS migs_adv, 
   sys.dm_db_missing_index_groups mig, 
   sys.dm_db_missing_index_details mid 
WHERE 
   migs_adv.group_handle = mig.index_group_handle and 
   mig.index_handle = mid.index_handle and
   index_advantage > @MIN_INDEX_ADVANTAGE
   --and	mid.Statement = '[TopManager].[dbo].[TbRcd]'
ORDER BY migs_adv.index_advantage DESC 

OPEN MissingIndexes
FETCH NEXT FROM MissingIndexes 
INTO @Advantage, @ID, @TableStatement, @Equality, @Inequality, @Included, @Handler

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @Columns AS Varchar(2000)
	SET @Columns = ''

	IF @Equality IS NOT NULL SET @Columns = @Columns + @Equality
	IF @Inequality IS NOT NULL AND @Equality IS NOT NULL SET @Columns = @Columns + ', ' + @Inequality
	IF @Inequality IS NOT NULL AND @Equality IS NULL SET @Columns = @Inequality

	IF @Included IS NULL
		print('/* ' + CONVERT(VARCHAR(14), @Advantage) + '% */ CREATE INDEX I_REGINA_' + convert(varchar(8), @Handler)) + ' ON ' + @TableStatement + ' (' + @Columns + ')'
	ELSE
		print('/* ' + CONVERT(VARCHAR(14), @Advantage) + '% */ CREATE INDEX I_REGINA_' + convert(varchar(8), @Handler)) + ' ON ' + @TableStatement + ' (' + @Columns + ') INCLUDE (' + @Included + ')'

	FETCH NEXT FROM MissingIndexes 
	INTO @Advantage, @ID, @TableStatement, @Equality, @Inequality, @Included, @Handler
END

CLOSE MissingIndexes
DEALLOCATE MissingIndexes

-- Mostra os �ndices que est�o criados
---> 3. Indexes_Mostra os indices que estao criados
DECLARE @table_object_id AS int
DECLARE @index_id AS int
DECLARE @index_name AS varchar(60)
DECLARE @table_name AS varchar(30)
DECLARE @clause AS varchar(30)
DECLARE @column_id AS int
DECLARE @is_included_column AS bit
DECLARE @TABLE_TO_SEARCH AS Varchar(30)
SET @TABLE_TO_SEARCH = ''

IF @TABLE_TO_SEARCH = '' SET @TABLE_TO_SEARCH = '%%'
DECLARE indexes CURSOR FOR 
	SELECT		sys.indexes.object_id, sys.indexes.name, index_id 
	FROM		sys.indexes 
	INNER JOIN	sys.objects on sys.objects.object_id = sys.indexes.object_id
	WHERE		sys.indexes.Object_id > 100 and sys.objects.name like @TABLE_TO_SEARCH

OPEN indexes
FETCH NEXT FROM indexes 
INTO @table_object_id, @index_name, @index_id

WHILE @@FETCH_STATUS = 0
BEGIN
      SELECT @table_name = name FROM sys.objects 
            WHERE object_id = @table_object_id
      DECLARE index_columns CURSOR FOR
            SELECT column_id, is_included_column FROM sys.index_columns 
            WHERE sys.index_columns.object_id= @table_object_id
                  AND sys.index_columns.index_id = @index_id
            ORDER BY index_column_id
      print '---------------'
      print 'Nome da tabela: ' + @table_name
      print 'Nome do �ndice: ' + @index_name
      print 'ID do �ndice: ' + convert(varchar(3),@index_id)
      print 'Colunas do �ndice: ' 
      OPEN index_columns

      FETCH NEXT FROM index_columns 

      INTO @column_id, @is_included_column

            WHILE @@FETCH_STATUS = 0
            BEGIN
                  DECLARE @column_name AS varchar(30)
                  SELECT @column_name = name FROM sys.columns 
                        WHERE object_id = @table_object_id
                        AND column_id = @column_id
                  IF @is_included_column = 0 print @column_name
                  ELSE print '(included)' +@column_name 
                  FETCH NEXT FROM index_columns 
                  INTO @column_id, @is_included_column
            END;
      CLOSE index_columns

      DEALLOCATE index_columns
      FETCH NEXT FROM indexes 
      INTO @table_object_id, @index_name, @index_id
END

CLOSE indexes
DEALLOCATE indexes

-------------------------
-- AUXILIARES DIVERSAS --
-------------------------
-- Mostra Tabelas sem indices do BD corrente
Select 
			object_name(i.id) 
From		sysindexes i
inner join	sysobjects o ON i.id = o.id
Where		indid = 0 
AND			xtype = 'U'

-- **************************************
-- Espa�o utilizado por tabelas e �ndices
-- **************************************
SELECT	OBJECT_NAME(ps.object_id) As Tabela
,		Row_count As Linhas
,		SUM(CASE WHEN index_id <= 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) * 8192 / 1024 / 1024 as Total_Tabela_Usado_MB
--,		SUM(CASE WHEN index_id <= 1 THEN convert(real,in_row_reserved_page_count) ELSE 0 END) * 8192 / 1024 / 1024 as Total_Tabela_Reservado_MB
,		SUM(CASE WHEN index_id > 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) *  8192 / 1024 / 1024 as Total_Indice_Usado_MB
--,		SUM(CASE WHEN index_id > 1 THEN convert(real,in_row_reserved_page_count) ELSE 0 END) * 8192 / 1024 / 1024 as Total_Indice_Reservado_MB
,		[% do Tamanho Indice em rela��o a tabela]
			 = (((SUM(CASE WHEN index_id > 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) *  8192 / 1024 / 1024) 
				- (SUM(CASE WHEN index_id <= 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) * 8192 / 1024 / 1024))
					/ (SUM(CASE WHEN index_id <= 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) * 8192 / 1024 / 1024)) * 100
FROM	sys.dm_db_partition_stats PS
GROUP BY
		OBJECT_NAME(ps.object_id), Row_Count
having (SUM(CASE WHEN index_id <= 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) * 8192 / 1024 / 1024) < (SUM(CASE WHEN index_id > 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) *  8192 / 1024 / 1024)
and		SUM(CASE WHEN index_id <= 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) * 8192 / 1024 / 1024 <> 0
and		SUM(CASE WHEN index_id > 1 THEN convert(real,in_row_used_page_count) ELSE 0 END) *  8192 / 1024 / 1024 <> 0
ORDER BY
		-- Total_Tabela_Usado_MB DESC -- Tamanho da Tabela
		 Row_count DESC -- Numero de Linhas

-- **************************************************************
-- Informa��es de �ndices (Clustered, nonclusteres, unicos e etc)
-- **************************************************************
Select	o.name
,		i.name
,		i.type_desc 
From	sys.indexes i
join	sys.objects o on o.object_id = i.object_id
Where	i.type = 2 --(0 - HEAP; 1 - CLUSTERED; 2 - NONCLUSTERED)
and		i.object_id > 100
--and	is_unique = 1 -- (INDICES UNICOS)
and		i.is_unique = 0 -- (N�O UNICOS)
Order by
		o.name

-- ********************************
-- Quantidade de �ndices por tabela
-- ********************************
Select	[Nome da Tabela] = o.name
,		[Qtd de �ndices] = count(o.name)
From	sys.indexes i
join	sys.objects o on o.object_id = i.object_id
Group by
		o.name
Order by 
		count(o.name) desc

-- ********************************************
-- Consulta a utiliza��o dos �ndices por tabela
-- ********************************************
SELECT		DB_NAME(database_id) As Banco
,			OBJECT_NAME(I.object_id) As Tabela
,			I.Name As Indice
,			U.User_Seeks As Pesquisas	-- N�mero de buscas atrav�s de consultas de usu�rio. 
,			U.User_Scans As Varreduras	-- N�mero de exames atrav�s de consultas de usu�rio. 
,			U.User_Lookups As LookUps	-- N�mero de pesquisas de indicador atrav�s de consultas de usu�rio.
,			U.Last_User_Seek As UltimaPesquisa
,			U.Last_User_Scan As UltimaVarredura
,			U.Last_User_LookUp As UltimoLookUp
,			U.Last_User_Update As UltimaAtualizacao
FROM		sys.indexes As I
LEFT JOIN	sys.dm_db_index_usage_stats As U ON I.object_id = U.object_id AND I.index_id = U.index_id
JOIN		sys.objects As Obj ON Obj.object_id = I.object_id
WHERE	DB_NAME(database_id) = 'TopManager'
--and		I.object_id = OBJECT_ID('TbMde')
and		U.User_Seeks < 10 -- Somente com menos de 10
and		U.User_Scans < 10 -- Somente com menos de 10
and		U.User_Lookups < 10 -- Somente com menos de 10

-- ******************************************
-- Quantidade de Indices e Colunas por Tabela
-- ******************************************
Select	Tabela = o.name
,		[Qtd de Indices] = Count(o.name)
,		[Qtd de Colunas] = (Select count(*) From sys.columns Where object_id = o.object_id)
From	sys.indexes i
join	sys.objects o on o.object_id = i.object_id and o.type = 'U'
Group by
		o.name
,		o.object_id

-- Mostra em quais tabelas existem mais indices do que colunas na tabela
having Count(o.name) > (Select count(*) From sys.columns Where object_id = o.object_id)

Order by
		Count(o.name) desc

------------------
-- Bibliografia --
------------------
--http://msdn.microsoft.com/pt-br/library/ms188388.aspx (Indices)