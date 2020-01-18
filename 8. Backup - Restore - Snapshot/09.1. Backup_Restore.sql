Select * From sysfiles -- Arquivos da base corrente
EXEC xp_fixeddrives -- Espa�o em disco
EXEC sp_spaceused 'Person.Address' -- Informa��es de espa�o de uma tabela
DBCC SQLPERF (LOGSPACE) -- informa��es de log

-- Ver ultimo backup realizado
Select max(backup_start_date) From backupset
Where database_name = 'AdventureWorks'

--Setando o banco a ser utilizado
Use AdventureWorks

-- ################
-- #### BACKUP #### 
-- ################
-- Tipo: Completo
BACKUP DATABASE AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_20110429_Completo.bak';

--Criando um backup do tipo DIFFERENTIAL
BACKUP DATABASE AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_20110429_Diferencial.bak' WITH DIFFERENTIAL;

--Criando um backup do LOG
BACKUP LOG AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_20110429_Log.bak'; 
-- O banco deve ter modelo de recupera��o diferente de SIMPLES

--Criando Backup de um arquivo somente
BACKUP DATABASE AdventureWorks FILE = 'AdventureWorks_Data' -- Nome l�gico
	TO DISK = N'C:\Backups\AdventureWorks_20110429_Arquivo.bak'

--Criando Backup de um FileGroup
BACKUP DATABASE AdventureWorks FILEGROUP = 'PRIMARY'
	TO DISK = N'C:\Backups\AdventureWorks_20110429_Filegroup.bak'

-- ****************************
-- * Backup via TSQL com Data *
-- ****************************
Declare @Backup VarChar(1000)
Declare @Database Varchar(1000)
Declare @Caminho Varchar(1000)

-- Informe o nome do banco de dados e caminho logo abaixo
Set		@Database = 'AdventureWorks'
Set		@Caminho = 'C:\Backups\'

Set		@Backup='Backup Database ' + @Database +  ' To Disk = ''' + @Caminho + @Database + '_' + Convert(Char(8),GetDate(),112) + '.bak' + ''''

Select	@Backup
Exec	(@Backup)


-- ###################
-- # PEQUENO CEN�RIO #
-- ###################

-- 01. Backup Completo *****
use master
BACKUP DATABASE AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_Completo.bak';

-- 02. Criando uma tabela
use AdventureWorks;
Create Table Teste (
	id int identity (1,1) primary key 
,	nm varchar(1000)
) --drop table Teste

-- 03. Populando
use AdventureWorks;
declare @i int
declare @iTotal int

set		@i = 0
set		@iTotal = 13000 -- informe o total de linhas

While @i < @iTotal
	Begin
		insert into Teste values ('ABCDEFGHIJLMNOPQRSTUVXYZ 123456789 "!@#$%�&*()_+`{^}:><?|\/][=-�/*-+.,')
		set @i = @i + 1
	End

-- *** TOTAL: 2000 Linhas ***

-- 04. Backup Diferencial
use master;
BACKUP DATABASE AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_Diferencial.bak' WITH DIFFERENTIAL;

-- *** + 8000 Linhas ***

-- *** TOTAL: 10000 Linhas *** 

-- 05. Backup de Log
use master;
BACKUP LOG AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_Log_1.bak';

-- *** + 8000 Linhas ***

-- *** TOTAL: 18000 Linhas *** 

-- 06. Backup de Log
use master;
BACKUP LOG AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_Log_2.bak';

-- *** + 4000 Linhas ***

-- *** TOTAL: 22000 Linhas *** 

-- 07. Backup de Log
use master;
BACKUP LOG AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_Log_3.bak';

-- *** + 5000 Linhas ***

-- *** TOTAL: 27000 Linhas *** 

-- 08. Backup de Log
use master;
BACKUP LOG AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_Log_4.bak';

-- *** + 13000 Linhas ***

-- *** TOTAL: 40000 Linhas ***

-- 09. Backup Diferencial 1
use master;
BACKUP DATABASE AdventureWorks TO DISK = 'C:\Backups\AdventureWorks_Diferencial1.bak' WITH DIFFERENTIAL;

-- Select
Select * From AdventureWorks..Teste

-- ***************
-- * RESTAURANDO *
-- ***************

use master
-- Restaurando - Completo
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Completo.bak' WITH REPLACE;
Select * From AdventureWorks..Teste
-- N�o existe a tabela

-- Restaurando - Completo + Diferencial
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Completo.bak' WITH REPLACE, NORECOVERY;
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Diferencial.bak' WITH RECOVERY;
Select * From AdventureWorks..Teste
-- Tabela com 2000 Linhas

-- Restaurando - Completo + Diferencial 1 (Pulando os backups de log)
-- Vale ressaltar que o backup diferencial n�o � a mesma coisa de um backup incremental: 
-- cada backup diferencial criado pode substituir todos os backups (Diferenciais e de Log) 
-- criados anteriormente at� o ultimo backup completo, nos caso de restaura��o da base de dados.
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Completo.bak' WITH REPLACE, NORECOVERY;
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Diferencial1.bak' WITH RECOVERY;
Select * From AdventureWorks..Teste
-- Tabela com 40000 Linhas

-- Restaurando - Completo + Log1 + Log2 + Log3
-- O Transaction Log Backup (Backup do Log de Transa��es) trabalha em cima do log ativo
-- , capturando todas as transa��es finalizadas deste o ultimo backup, qualquer que seja o tipo.
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Completo.bak' WITH REPLACE, NORECOVERY;
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Diferencial.bak' WITH NORECOVERY;
RESTORE LOG AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Log_1.bak' WITH NORECOVERY;
RESTORE LOG AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Log_2.bak' WITH NORECOVERY;
RESTORE LOG AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_Log_3.bak' WITH RECOVERY;
Select * From AdventureWorks..Teste
-- Tabela com 22000 Linhas


-- ###############################################
-- ### ANALIZANDO ARQUIVOS DE BACKUP - RESTORE ### 
-- ###############################################

/*	O comando RESTORE LABELONLY retorna informa��es sobre as m�dias (Media Set) armazenadas em um dispositivo. 
Este comando � utilizando nos casos onde o Administrador precisa descobrir a qual conjunto de m�dia aquele 
dispositivo faz parte. */
RESTORE LABELONLY 
FROM DISK = 'C:\Backups\AdventureWorks_20110429_Completo.bak' 

--Verifica Cabe�alho do arquivo de backup
/*O comando RESTORE HEADERONLY retorna informa��es sobre os backups (Backup Set) armazenados em um dispositivo. 
� um dos comandos mais utilizando, pois retorna para o Administrador todos os backups armazenados no dispositivo, 
seus tipos e de quais bases eles pertencem */
RESTORE HEADERONLY 
FROM DISK = 'C:\Backups\AdventureWorks_20110429_Completo.bak' 
WITH NOUNLOAD;
GO

--Verificar se o backup esta completo e legivel.(N�o verifica estrutura)
/*	O comando RESTORE VERIFYONLY realiza uma checagem na integridade dos backups de um dispositivo, verificando 
se o mesmo � leg�vel. No entanto, este comando n�o verifica a estrutura de dados existente dentro do backup. 
Se o backup for v�lido, o SQL Server retorna uma mensagem de sucesso. 
	Caso OK aparecer�: The backup set on file 1 is valid. */
RESTORE VERIFYONLY
FROM DISK = 'C:\Backups\AdventureWorks_20110429_Completo.bak'

/*	RESTORE FILELISTONLY
	O comando RESTORE FILELISTONLY retorna informa��es sobre os arquivos de dados e log (*.mdf, *.ndf e *.ldf) 
armazenados em um dispositivo. */
RESTORE FILELISTONLY FROM DISK = 'C:\Backups\AdventureWorks_20110429_Completo.bak'


-- ####################################
-- ### RESTAURANDO BACKUP - RESTORE ### 
-- ####################################
--Restaurando um Backup de uma base j� existente (A op��o Replace sobrescreve)
USE master;
RESTORE DATABASE AdventureWorks 
FROM  DISK = 'C:\Backups\AdventureWorks_20110429_Completo.bak' WITH REPLACE

--Restaurando um Backup diferencial 
USE master;
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_20110429_Completo.bak' 
WITH NORECOVERY; --Restaurando apenas o Full Backup, com a op��o NORECOVERY
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_20110429_Diferencial.bak'
WITH RECOVERY; --Restaurando o Differential Backup, com a op��o RECOVERY

--Restaurando um Backup do Log
USE master;
RESTORE LOG Backup_Alex FROM DISK = 'C:\Backups\AdventureWorks_20110429_Log.bak' WITH RECOVERY;

--Restaurando Backup de um arquivo somente
USE master;
RESTORE DATABASE AdventureWorks FILE = 'AdventureWorks_Data' 
TO DISK = N'C:\Backups\AdventureWorks_20110429_Arquivo.bak';

--Restaurando um Backup de um FileGroup
USE master;
RESTORE DATABASE AdventureWorks FILEGROUP = 'PRIMARY'
TO DISK = N'C:\Backups\AdventureWorks_20110429_Filegroup.bak';


-- ##############################################
-- ### RESTAURANDO BACKUP COM ERROS - RESTORE ### 
-- ##############################################
USE master;
--Restaurando um backup, ignorando os erros 
RESTORE DATABASE AdventureWorks FROM DISK = 'C:\Backups\AdventureWorks_20110429_Completo.bak'
WITH	CONTINUE_AFTER_ERROR
,		REPLACE;

-- N�o checando o backup...
BACKUP DATABASE DbCorrompido TO DISK = 'C:\Alex\Corrompido.bak';

-- Checando o backup...
BACKUP DATABASE DbCorrompido TO DISK = 'C:\Alex\Corrompido.bak'
WITH CHECKSUM;

-- Checando o backup, mas deixando continuar...
BACKUP DATABASE DbCorrompido TO DISK = 'C:\Alex\Corrompido.bak'
WITH CHECKSUM, CONTINUE_AFTER_ERROR;


-- ###########################
-- ### DISPOSITIVO L�GICOS ### 
-- ###########################
/*
Para CRIAR um dispositivo l�gico usando T-SQL, o SQL Server oferece um procedimento chamado sp_addumpdevice. 
Sintaxe b�sica para a cria��o de um Backup Device.*/
USE master;
--Criando um dispositivo l�gico
sp_addumpdevice @devtype = 'disk', @logicalname = 'Nome_Dispositivo_Logico', @physicalname = '\\Servidor\Share\Backup.bak';

/*
Para REMOVER um dispositivo l�gico usando T-SQL, utilize o procedimento sp_dropdevice. 
Sintaxe b�sica para a remo��o de um Backup Device.*/
USE master;
--Removendo um dispositivo l�gico
sp_dropdevice @logicalname = 'Nome_Dispositivo_Logico';

-- ###############################
-- ### BACKUP COM ESPELHAMENTO ### 
-- ###############################
--Sintaxe b�sica para a CRIA��O de um backup com espelhamento.
USE master;
--Criando um backup com Espelhamento
BACKUP DATABASE AdventureWorks TO DISK = 'C:\Backups\Original.bak' 
MIRROR TO DISK='D:\Backups\Mirror.bak' WITH FORMAT;

/* Por fim, observe no final do comando o par�metro WITH FORMAT. A cl�usula FORMAT � um par�metro opcional para o comando 
BACKUP: este comando � utilizado para escrever um novo cabe�alho na m�dia de backup, sobrescrevendo o cabe�alho anterior 
e invalidando os backups anteriores.
Entretanto, para garantir que as p�ginas de dados do espelhamento estejam escritas da mesma forma que no backup original, 
n�o � poss�vel armazenar m�ltiplos backups em um arquivo ou fita espelhado. Portanto, a propriedade FORMAT � obrigat�ria 
para a cria��o de c�pias espelhadas. O recurso de espelhamento s� est� dispon�vel na edi��o Enterprise e Developer. */

-- ###########################################
-- ### CONJUNTO DE M�DIAS SET E BACKUP SET ### 
-- ###########################################
--Criando um backup com Media Set composto de tr�s discos
BACKUP DATABASE AdventureWorks TO
DISK = 'D:\SQL2005\Backup\P1.bak', DISK = 'D:\SQL2005\Backup\P2.bak', DISK = 'D:\SQL2005\Backup\P3.bak'
WITH FORMAT, MEDIANAME = 'Nome_Conjunto_M�dia';

--CRIANDO um backup com Media Set composto de tr�s discos (DIFFERENTIAL)
BACKUP DATABASE AdventureWorks TO
DISK = 'D:\SQL2005\Backup\P1.bak', DISK = 'D:\SQL2005\Backup\P2.bak', DISK = 'D:\SQL2005\Backup\P3.bak'
WITH MEDIANAME = 'Nome_Conjunto_M�dia', DIFFERENTIAL;

/*	Observe que foram armazenado no mesmo Midia Set (O que diferencia � o que podemos ver logo abaixo,
ou seja a op��o FILE)
	Este recurso est� dispon�vel em todas as edi��es do SQL Server 2005.*/

--RESTAURANDO o Backup Completo do Media Set
RESTORE DATABASE AdventureWorks FROM
DISK = 'D:\SQL2005\Backup\P1.bak', DISK = 'D:\SQL2005\Backup\P2.bak', DISK = 'D:\SQL2005\Backup\P3.bak'
WITH MEDIANAME = 'Nome_Conjunto_M�dia', FILE = 1, NORECOVERY;

--Restaurando o Backup Differential do Media Set
RESTORE DATABASE AdventureWorks FROM
DISK = 'D:\SQL2005\Backup\P1.bak', DISK = 'D:\SQL2005\Backup\P2.bak', DISK = 'D:\SQL2005\Backup\P3.bak'
WITH MEDIANAME = 'Nome_Conjunto_M�dia', FILE = 2, RECOVERY;


-- #############################################
-- # Tempo restante para a conclus�o do backup #
-- #############################################
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
-- Select @@SPID

-- ##########################################
-- # Backup de todos os bancos da instancia #
-- ##########################################
Use master 
GO
declare @BackupPath nvarchar(512)
,		@DB nvarchar(512)
,		@SQLCommand nvarchar(1024)

Set @BackupPath = 'C:\Backups'
Print '-- Backup Path: ' + @BackupPath

DECLARE DBCursor CURSOR FAST_FORWARD FOR 
	SELECT name FROM master..sysdatabases
	OPEN DBCursor
		FETCH NEXT FROM DBCursor INTO @DB
			WHILE @@FETCH_STATUS <> -1
				BEGIN
					IF @DB NOT IN ('distribution', 'tempdb', 'Northwind', 'AdventureWorks', 'pubs')
						Begin
							PRINT  '-- Backing up database: ' + @DB
							SELECT @SQLCommand = N'Backup database [' + @DB + '] to disk = N' + char(39) + @BackupPath + char(92) + @DB + '.bak' + char(39) + ' with init'
							PRINT  @SQLCommand
							--EXEC  (@SQLCommand)
						End
					FETCH NEXT FROM DBCursor INTO @DB
			END
	DEALLOCATE DBCursor
	

--http://msdn.microsoft.com/pt-br/library/ms191239.aspx -- Introdu��o �s estrat�gias de backup e restaura��o no SQL Server
--http://msdn.microsoft.com/pt-br/library/ms178094.aspx -- Planejando a recupera��o de desastres
--http://msdn.microsoft.com/pt-br/library/ms175987.aspx -- Escolhendo o modelo de recupera��o para um banco de dados
--http://msdn.microsoft.com/pt-br/library/ms190190.aspx -- Considera��es sobre backup e restaura��o de bancos de dados do sistema
--http://msdn.microsoft.com/pt-br/library/ms186858.aspx -- RESTORE
--http://msdn.microsoft.com/pt-br/library/ms189275.aspx -- Vis�o geral do modelo de recupera��o
--http://msdn.microsoft.com/pt-br/library/ms190244.aspx -- Restaurando um banco de dados para um ponto em um backup
