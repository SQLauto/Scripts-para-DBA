/* Realiza o comando DBCC CHECKDB das databases do servidor. */

CREATE PROCEDURE dbo.stpCHECKDB_Databases
AS
BEGIN
	DECLARE @Databases TABLE(
			Id_Database INT IDENTITY(1,1)
	,		Nm_Database VARCHAR(50))
	
	DECLARE @Total INT, @Loop INT, @Nm_Database VARCHAR(50)
	/* Caso n�o deseje fazer o check
	de alguma database basta retir�-la na
	cl�usula WHERE*/

	INSERT INTO @Databases (Nm_Database) 
		SELECT Name From master.dbo.Sysdatabases
		WHERE Name not in ('Tempdb')

	SELECT	@Total = max(Id_Database)
	FROM	@Databases

	SET @Loop = 1

	WHILE (@Loop <= @Total)
	BEGIN
		SELECT @Nm_Database = Nm_Database FROM @Databases
		WHERE Id_Database = @Loop

		DBCC CHECKDB(@Nm_Database) WITH NO_INFOMSGS
		--WITH PHYSICAL_ ONLY --> Realiza apenas uma verifica��o da integridade f�sica
	
		SET @Loop = @Loop + 1
	END
END

-- Executa a procedure
--EXEC stpCHECKDB_Databases

/***** Criar um Job para rodar este teste *****/

/* Faz a leitura dos arquivos de Log do SQL Server e armazena o resultado em uma tabela tempor�ria */
CREATE TABLE #TempLog (
	LogDate DATETIME
,	ProcessInfo NVARCHAR(50)
,	[Text] NVARCHAR(MAX))

CREATE TABLE #logF (
	ArchiveNumber INT
,	LogDate DATETIME
,	LogSize INT )

-- Seleciona o n�mero de arquivos.
INSERT INTO #logF
	EXEC sp_enumerrorlogs

DECLARE @TSQL NVARCHAR(2000)
DECLARE @lC INT

SELECT @lC = MIN(ArchiveNumber) FROM #logF

--Loop para realizar a leitura de todo o log.
WHILE @lC IS NOT NULL
BEGIN
	INSERT INTO #TempLog 
		EXEC sp_readerrorlog @lC

	SELECT @lC = MIN(ArchiveNumber) FROM #logF
	WHERE ArchiveNumber > @lC
END

/* Filtrando esse resultado para visualizarmos apenas as informa��es referentes � execu��o
do comando DBCC CHECKDB. Deve-se filtrar a query atrav�s da coluna Logdate de acordo com o 
hor�rio agendado para a execu��o dessa rotina. No exemplo � retornado todas as execu��es
realizadas no dia anterior. */

SELECT		[Data do Log] = LogDate
,			Substring(Text,charindex('found',Text)
,			Charindex('Elapsed Time',Text) - charindex('found',Text)) Possiveis_Erros
,			Text Texto_Completo
FROM		#TempLog
WHERE		Convert(varchar, LogDate, 103) >=  Convert(varchar, getdate() - 2, 103)
and			Convert(varchar, LogDate, 103) <=  Convert(varchar, getdate(), 103)
and			Text like '%CHECKDB%'
ORDER BY	LogDate

/* Acompanha o progresso da execu��o */
SELECT Percent_Complete,*
FROM sys.dm_exec_requests
WHERE Command LIKE '%DBCC%'