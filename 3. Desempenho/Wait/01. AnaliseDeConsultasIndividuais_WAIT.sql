------------------------------------------------------------------------
-- Analisando o tempo de espera e a execu��o de consultas individuais --
------------------------------------------------------------------------
/* Se for necess�rio aprofundar-se ainda mais em detalhes relacionados ao tempo de execu��o e �s estat�sticas de IO para uma 
consulta ou um procedimento armazenado, a melhor informa��o s�o os tipos de espera e tempos de espera que ocorreram durante a 
execu��o. A obten��o dessa informa��o j� n�o � simples, mas envolve o uso estendido de eventos de monitoramento. O m�todo que 
estou apresentando neste artigo � baseado nos tempos de resposta lentos de debug do SQL Server 2008. Ele envolve a cria��o de 
uma sess�o de evento estendido que captura a informa��o sqlos.wait_info e filtra a sess�o de eventos estendida para uma sess�o 
de execu��o espec�fica (SPID):

- links
uso estendido de eventos de monitoramento - https://technet.microsoft.com/en-us/library/bb630354(v=sql.105).aspx
tempos de resposta lentos de debug do SQL Server 2008 - http://blogs.technet.com/b/sqlos/archive/2008/07/18/debugging-slow-response-times-in-sql-server-2008.aspx

*/

-- Script
-- SET STATISTICS TIME ON
-- SET STATISTICS IO ON

create event session session_waits on server
add event sqlos.wait_info
(WHERE sqlserver.session_id=<execution_spid_here> and duration>0) -- INFORMAR O ID da Sess�o que deseja analisar
, add event sqlos.wait_info_external
(WHERE sqlserver.session_id=<execution_spid_here> and duration>0) -- INFORMAR O ID da Sess�o que deseja analisar
add target package0.asynchronous_file_target
      (SET filename=N'c:\temp\wait_stats.xel', metadatafile=N'c:\temp\wait_stats.xem');
go
 
alter event session session_waits on server state= start;
go

/* Com a sess�o de eventos estendidos criada e iniciada, agora ser� poss�vel executar a consulta ou O procedimento que deseja 
analisar. Depois disso, pare a sess�o de eventos estendida e verifique os dados capturados: */
alter event session session_waits on server state= stop;
go

with x as (
select cast(event_data as xml) as xevent
from sys.fn_xe_file_target_read_file
      ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem', null, null))
select * from x;
go

-- Voc� pode analisar o XML em colunas para uma melhor visualiza��o:
with x as (
select cast(event_data as xml) as xevent
from sys.fn_xe_file_target_read_file
      ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem', null, null))
select xevent.value(N'(/event/data[@name="wait_type"]/text)[1]', 'sysname') as wait_type,
    xevent.value(N'(/event/data[@name="duration"]/value)[1]', 'int') as duration,
    xevent.value(N'(/event/data[@name="signal_duration"]/value)[1]', 'int') as signal_duration
 from x;
 
-- Finalmente, podemos agregar todos os dados capturados na sess�o de eventos estendidos:
with x as (
select cast(event_data as xml) as xevent
from sys.fn_xe_file_target_read_file
      ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem', null, null)),
s as (select xevent.value(N'(/event/data[@name="wait_type"]/text)[1]', 'sysname') as wait_type,
    xevent.value(N'(/event/data[@name="duration"]/value)[1]', 'int') as duration,
    xevent.value(N'(/event/data[@name="signal_duration"]/value)[1]', 'int') as signal_duration
 from x)
 select wait_type, 
    count(*) as count_waits, 
    sum(duration) as total__duration,
    sum(signal_duration) as total_signal_duration,
    max(duration) as max_duration,
    max(signal_duration) as max_signal_duration
from s
group by wait_type
order by sum(duration) desc;

-- Ser� exibida uma excepcional riqueza de informa��es sobre o que aconteceu durante a execu��o de um determinado pedido.



/************************
 ** TEMPO DE CONSULTAS **
 ************************/
 
--SELECT st.text,
--       pl.query_plan,
--       qs.*
--  FROM       sys.dm_exec_query_stats qs
-- cross apply sys.dm_exec_sql_text(qs.sql_handle) as st
-- cross apply sys.dm_exec_query_plan(qs.plan_handle) as pl;

-- Se voc� n�o sabe qual tipo de consulta deve procurar, para come�ar, o meu conselho � concentrar-se na seguinte ordem:
-- 1. Contagem de alto tempo de execu��o: identificar quais consultas s�o executadas, na maioria das vezes �, na minha opini�o, mais importante do que identificar quais consultas s�o particularmente lentas. Na maioria das vezes, as consultas encontradas em uma fila de execu��o s�o uma surpresa e simplesmente limitam o rendimento que a contagem do tempo de execu��o ajudaria a ganhar em termos de desempenho.
-- 2. Grandes leituras l�gicas: grandes varreduras de dados s�o o culpado habitual para a maioria dos problemas de desempenho do servidor SQL. Essas grandes varreduras podem ser causadas por �ndices perdidos, por um modelo de dados mal projetado, por planos de execu��o mal planejados, por estat�sticas desatualizadas, por par�metros n�o utilizados e v�rias outras causas.
-- 3. Tempo decorrido alto com baixa carga de trabalho: consultas de bloqueio n�o custam muito ao servidor, mas os usu�rios do aplicativo n�o se importam se o tempo em que esperam os resultados na frente da tela do computador foi gasto pelo servidor ativo ou bloqueado.