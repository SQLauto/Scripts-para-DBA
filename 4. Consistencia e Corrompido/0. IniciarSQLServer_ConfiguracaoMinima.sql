-- http://msdn.microsoft.com/pt-br/library/ms162773.aspx -- Utilit�rio sqlcmd
-- http://msdn.microsoft.com/pt-br/library/ms165702.aspx -- Usando o utilit�rio sqlcmd (SQL Server Express)
-- http://msdn.microsoft.com/pt-br/library/ms190737.aspx -- Usando as op��es de inicializa��o do servi�o do SQL Server
-- http://msdn.microsoft.com/pt-br/library/ms180965.aspx -- Como iniciar uma inst�ncia do SQL Server (sqlservr.exe)


-- Para iniciar a inst�ncia padr�o do SQL Server com configura��o m�nima
sqlservr.exe -f

-- Aumetando a mem�ria
sp_configure 'show advanced options', 1
RECONFIGURE
GO
sp_configure 'max server memory', 24000

