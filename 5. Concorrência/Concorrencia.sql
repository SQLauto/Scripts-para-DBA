--ALTER DATABASE TopManager SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE

Select * From sys.databases

-- Muda o n�vel de isolamento
--SET TRANSACTION ISOLATION LEVEL READ COMMITTED

-- Habilita o n�vel de isolamento para Read Committed Snapshot
--ALTER DATABASE Concorrencia SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE

-- Desativa o n�vel de isolamento de Read Committed Snapshot
--ALTER DATABASE Concorrencia SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE

-- is_read_committed_snapshot_on
-- Op��es:
-- 1 = A op��o READ_COMMITTED_SNAPSHOT est� ON. Opera��es de leitura sob o n�vel de isolamento confirmado por leitura s�o baseados em varreduras de instant�neo e n�o adquirem bloqueios.
-- 0 = A op��o de READ_COMMITTED_SNAPSHOT est� OFF (padr�o). Opera��es de leitura sob o n�vel de isolamento confirmado por leitura usam bloqueios de compartilhamento. 

--http://msdn.microsoft.com/pt-br/library/ms173763.aspx