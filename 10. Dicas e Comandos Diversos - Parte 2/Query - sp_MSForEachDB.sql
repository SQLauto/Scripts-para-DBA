-- Verificar em todas as base de dados de uma determinada instancia a ultima vers�o do TopManager.
EXEC sp_MSForEachDB 'USE [?]; SELECT top 1 NrVer, Teste = (SELECT ''?'') From TbVer Order By CdVer desc'

