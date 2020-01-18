--DEMO RECOVERY MODEL
	
--CRIA BANCO PARA RECOVERY MODEL
IF EXISTS (SELECT NULL FROM SYS.DATABASES WHERE NAME = 'SQLSERVER_RS_RECOVERY')
           DROP DATABASE SQLSERVER_RS_RECOVERY
CREATE DATABASE SQLSERVER_RS_RECOVERY
ON PRIMARY
(NAME='SQLSERVER_RS_RECOVERY', FILENAME='C:\temp\SQLServerRS\Dados\SQLSERVER_RS_RECOVERY.mdf')
LOG ON
(NAME = 'SQLSERVER_RS_RECOVERY_LOG', FILENAME = 'C:\temp\SQLServerRS\Log\SQLSERVER_RS_RECOVERY_Log.ldf')
GO


--VERIFICAR MODELO DE RECUPERA��O DE TODAS AS BASES
SELECT NAME, RECOVERY_MODEL_DESC
  FROM SYS.DATABASES
 WHERE NAME = 'SQLSERVER_RS_RECOVERY'
 

 --ALTERDAR MODELO DE RECUPERA��O DE UMA BASE
 ALTER DATABASE SQLSERVER_RS_RECOVERY SET RECOVERY SIMPLE
 ALTER DATABASE SQLSERVER_RS_RECOVERY SET RECOVERY FULL
 ALTER DATABASE SQLSERVER_RS_RECOVERY SET RECOVERY BULK_LOGGED

 
 --OBSERVA��ES IMPORTANTES

 /*
	BULK_LOGGED: 
		* Aumenta consideravelmente o tamanho dos backups de log, pois carrega todos os extents continentes das p�ginas
		* N�o permite restore point in time.

	FULL:
		* Exige a realiza��o de backups de logs peri�dicos, para controle de tamanho do Log de Transa��es (.ldf)

	SIMPLE:
		* Mais facilidade de Administra��o, por�m sem muitas possibilidades de Restore, pois permite restaura��o somente at�  
		   final do backup full
	

 */