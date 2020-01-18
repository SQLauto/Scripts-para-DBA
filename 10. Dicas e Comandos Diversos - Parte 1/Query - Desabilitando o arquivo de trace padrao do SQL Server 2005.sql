/* Como desabilitar o arquivo de trace existente no Microsoft SQL Server 2005. Por padr�o toda 
inst�ncia do SQL Server 2005, possui um monitoramento realizado automaticamente e armazenado dentro 
de arquivo .trc(trace), muitas vezes este arquivo poder� gerar falhas na inicializa��o de novas sess�es 
de monitoramento atrav�s da ferramenta Profiler. */
 
-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1
GO
-- To update the currently configured value for advanced options.
RECONFIGURE
GO
-- To disable the feature.
EXEC sp_configure 'default trace enabled', 0
GO
-- To update the currently configured value for this feature.
RECONFIGURE
GO 

