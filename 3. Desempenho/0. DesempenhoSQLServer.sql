-- Exibi��es e fun��es de gerenciamento din�mico (Transact-SQL) - https://technet.microsoft.com/pt-br/library/ms188754.aspx

/*************************************
 ** Requisi��es / Tarefas de espera **
 *************************************/
-- Requisi��es ao SQL Server - https://technet.microsoft.com/pt-br/library/ms177648.aspx
--- Para cada pedido de execu��o feito ao servidor SQL Server existe uma linha registrada em sys.dm_exec_requests.

-- Tarefas de espera - https://technet.microsoft.com/pt-br/library/ms188743.aspx

-- Parallel Query Processing - https://technet.microsoft.com/en-us/library/ms178065(v=sql.105).aspx
-- - The Parallelism Operator - http://blogs.msdn.com/b/craigfr/archive/2006/10/25/the-parallelism-operator-aka-exchange.aspx

--SELECT r.session_id, 
--       status, 
--       command,
--       r.blocking_session_id,
--       r.wait_resource,
--       r.wait_type as [request_wait_type], 
--       r.wait_time as [request_wait_time],
--       t.wait_type as [task_wait_type],
--       t.wait_duration_ms as [task_wait_time*],
--       t.blocking_session_id,
--       t.resource_description,
--       obs = ' -> EXTRAS >>',
--       r.*,
--       t.*   
--  FROM      sys.dm_exec_requests r                                   -- Requisi��es ao SQL Server
--  LEFT JOIN sys.dm_os_waiting_tasks t on r.session_id = t.session_id -- Tarefas em espera
-- WHERE r.session_id >= 50
--   AND r.session_id <> @@spid;

-- Observa��o:
-- - *CXPACKET. Pedidos que mostram esse tipo de espera est�o realmente mostrando que as tarefas que deveriam ter produzido dados 
-- de consumo n�o est�o produzindo quaisquer dados (ou dados suficientes). Essas tarefas de produtores, por sua vez, podem ser suspensas, 
-- esperando outro tipo de trava/espera, e � isso que est� bloqueando seu pedido, n�o o operador exchange.


/********************
 ** Tipo de Espera **
 ********************/

-- Limpara os contadores 
-- DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);
-- GO

-- Status de espera agregados - https://msdn.microsoft.com/pt-br/library/ms179984.aspx
SELECT *
     , [Tempo M�dio] = wait_time_ms/waiting_tasks_count --  vai dizer o tempo m�dio que um tipo de espera em particular tem aguardado.
  FROM sys.dm_os_wait_stats
 WHERE [wait_type] NOT IN (
        N'CLR_SEMAPHORE',    N'LAZYWRITER_SLEEP',
        N'RESOURCE_QUEUE',   N'SQLTRACE_BUFFER_FLUSH',
        N'SLEEP_TASK',       N'SLEEP_SYSTEMTASK',
        N'WAITFOR',          N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'CHECKPOINT_QUEUE', N'REQUEST_FOR_DEADLOCK_SEARCH',
        N'XE_TIMER_EVENT',   N'XE_DISPATCHER_JOIN',
        N'LOGMGR_QUEUE',     N'FT_IFTS_SCHEDULER_IDLE_WAIT',
        N'BROKER_TASK_STOP', N'CLR_MANUAL_EVENT',
        N'CLR_AUTO_EVENT',   N'DISPATCHER_QUEUE_SEMAPHORE',
        N'TRACEWRITE',       N'XE_DISPATCHER_WAIT',
        N'BROKER_TO_FLUSH',  N'BROKER_EVENTHANDLER',
        N'FT_IFTSHC_MUTEX',  N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'DIRTY_PAGE_POLL',  N'SP_SERVER_DIAGNOSTICS_SLEEP')
   AND  waiting_tasks_count > 0
ORDER BY wait_time_ms DESC;
--ORDER BY wait_time_ms/waiting_tasks_count DESC;


-------------------------------------------
-- Disco e IO relacionado a tipos de espera
-------------------------------------------
-- PAGEIOLATCH_* (Este � o IO por excel�ncia: os dados lidos do disco s�o gravados sob a forma de um tipo de espera. A tarefa bloqueada nesse tipo de espera est� aguardando dados a serem transferidos entre o disco e o cache de dados em mem�ria (o pool de buffer). Em um sistema que tem alta PAGEIOLATCH_* agregada a algum tipo de espera, � muito prov�vel que a mem�ria seja consumida e esteja gastando muito tempo lendo dados do disco para o buffer.)

-- WRITELOG (Esse tipo de espera ocorre quando uma tarefa emite um COMMIT e aguarda o registro ser conclu�do para escrever a transa��o no log do disco. Tempos de resposta m�dios e elevados nesse tipo de espera indicam que o disco est� escrevendo o log lentamente, e isso diminui a cada transa��o. Tempos de resposta muito frequentes nesse tipo de espera s�o indicativos de que est�o criando muitas pequenas transa��es e ter�o que ser bloqueadas com frequ�ncia para esperar pelo COMMIT (lembre-se de que tipos que escrevem todos os dados exigem uma transa��o separada e que � implicitamente criada para cada declara��o, sen�o BEGIN TRANSACTION � usado explicitamente).)

-- IO_COMPLETION (Esse tipo de espera ocorre para as tarefas que est�o esperando por algo mais do que os dados de IO. Por exemplo, carregar uma DLL, ler e escrever arquivos de ordena��o do tempdb, ou ent�o esperam por dados especiais referentes a opera��es de leitura DBCC.)

-- ASYNC_IO_COMPLETION (Esse tipo de espera � geralmente associado com backup, restaura��o de dados e opera��es com arquivos de banco de dados.Se, em sua an�lise, o tempo de espera constatar que o registro de IO e disco s�o importantes tipos de espera, ent�o sua tarefa deve se concentrar em analisar a atividade de disco.)

-----------------------------------------
-- Tipos de espera relacionados � mem�ria
-----------------------------------------
-- RESOURCE_SEMAPHORE (Esse tipo de espera indica as consultas que est�o � espera de uma concess�o de mem�ria. Confira o documento Entenda a concess�o de mem�ria do servidor SQL. Consultas do tipo de carga de trabalho de OLTP n�o devem exigir grandes concess�es de mem�ria. Caso voc� se depare com esse tipo de espera em um sistema OLTP, reveja seu projeto de software. Cargas de trabalho OLAP muitas vezes possuem a necessidade de concess�es de mem�ria (algumas vezes grande) e grandes tempos de espera que geralmente apontam para o aumento das atualiza��es de mem�ria RAM.)

-- SOS_VIRTUALMEMORY_LOW (Voc� ainda est� convivendo com sistemas de 32 bits? Siga em frente!)

--------------------------------------
-- Tipos de espera relacionados � rede
--------------------------------------
-- ASYNC_NETWORK_IO (Esse tipo de espera indica que o SQL Server possui determinados conjuntos de resultados que devem ser enviados para o aplicativo, mas este pode n�o process�-los. Isso pode indicar uma conex�o de rede lenta, mas n�o necessariamente. Mas, mais frequentemente, o problema est� relacionado com o c�digo do aplicativo, ou ent�o com algum bloqueio ao processar o conjunto de resultados, ou ainda est� solicitando um enorme conjunto de resultados que n�o est�o sendo entregues em tempo h�bil.)

-------------------------------------------------------------
-- CPU, disputa e concorr�ncia relacionadas a tipos de espera
-------------------------------------------------------------
-- LCK_* (Locks ou travas. Todos os tipos de espera que come�am com LCK indicam uma tarefa suspensa � espera de um bloqueio qualquer. 
--O tipo de espera LCK_M_S* indica uma tarefa que est� esperando para ler dados (que podem ser bloqueios compartilhados) e est� bloqueada 
--por outra tarefa que tinha modificado os dados (tinha adquirido uma trava LCK_MX* exclusiva). O tipo de espera LCK_M_SCH* indica bloqueio 
--de objetos relacionados � modifica��o de esquema e indicam que o acesso a um objeto (como uma tabela) est� bloqueada por outra tarefa que 
--fez uma modifica��o em alguma DLL que acessa esse objeto (ALTER).)

-- PAGELATCH_* (N�o confunda esse tipo de espera com o PAGEIOLATCH_*. Tempos de espera elevados para PAGELATCH_* indicam um ponto de 
--grande acesso no banco de dados, uma regi�o de dados que s�o � frequentemente atualizada (que, por exemplo, poderia ser um �nico 
--registro em uma tabela que � constantemente modificada). Para uma an�lise mais aprofundada, recomendo o whitepaper Diagnosticando e 
--resolvendo disputas e travas no SQL Server. SQLServerLatchContention.pdf)

-- LATCH_* (Esses tipos de espera indicam conten��o em recursos internos do SQL Server, mas n�o necessariamente em dados (ao contr�rio 
--do PAGELATCH_*, n�o indicam um ponto muito movimentado do servidor). Para investigar essas esperas, ser� preciso cavar ainda mais fundo 
--usando os sys.dm_os_latch_stats DMV que detalham os tempos de espera por tipo de trava. Mais uma vez, � uma boa ideia ler o whitepaper 
--Diagnosticando e resolvendo disputas e travas no SQL Server.)

-- CMEMTHREAD (Esse tipo de espera ocorre quando as tarefas est�o bloqueadas, esperando para acessar um alocador de mem�ria compartilhada. Coloquei esse tipo aqui, na se��o de concorr�ncia, e n�o na se��o de �mem�ria�, pois o problema est� relacionado com a concorr�ncia interna do SQL Server. Se voc� ver tipos de espera com altos valores em CMEMTHREAD, certifique-se de que voc� est� utilizando a vers�o mais recente do SQL Server Service Pack dispon�vel e tamb�m a Atualiza��o Cumulativa para a sua vers�o, porque alguns desses tipos de problemas reportam quest�es internas do SQL Server e muitas vezes s�o tratados em vers�es mais recentes.)

-- SOS_SCHEDULER_YIELD (Esse tipo de espera pode indicar uma conten��o do tipo spinlock. Spinlocks s�o tipos de espera extremamente leves e primitivos no SQL Server, utilizados para proteger o acesso a recursos que podem ser modificados dentro de poucas instru��es de bloqueio da CPU. Tarefas do SQL Server adquirem spinlocks por fazer opera��es interligadas � CPU dentro de um loop, assim, a conten��o em spinlocks queima um monte de tempo de CPU (contadores de uso de CPU mostram entre 90-100% de uso, mas o progresso � lento). Uma an�lise mais aprofundada precisa ser feita usando sys.dm_os_spinlock_stats:)
-- SELECT * FROM sys.dm_os_spinlock_stats ORDER BY spins DESC; -- http://www.microsoft.com/en-us/download/details.aspx?id=26666

-- RESOURCE_SEMAPHORE_QUERY_COMPILE (Esse tipo de espera indica que uma tarefa est� esperando para compilar seu pedido. Tempos de resposta elevados para esse tipo de espera indicam que a compila��o da consulta enfrenta um problema de desempenho. Para mais detalhes, recomendo a leitura do documento Resolu��o de problemas com cache.)
-- https://technet.microsoft.com/en-us/library/cc293620.aspx

-- SQLCLR_QUANTUM_PUNISHMENT (Esse tipo de espera ocorre se for executado c�digo CLR dentro do motor SQL Server, e esse c�digo CLR n�o ceder espa�o de CPU. Isso resulta em um estrangulamento do c�digo CLR. Se voc� tiver o c�digo CLR que potencialmente poder� sequestrar o uso de CPU por um longo per�odo, deve chamar Thread.BeginThreadAffinity(). Para mais detalhes, recomendo conferir o link Dados mais r�pidos: t�cnicas para melhorar o desempenho do Microsoft SQL Server com SQLCLR.)

----------------------------
-- Tipos de espera especiais
----------------------------
-- TRACEWRITE (Esse tipo de espera indica que as tarefas s�o bloqueadas pelo SQL Profiler. Esse tipo de espera ocorre somente se voc� tiver o SQL Profiler conectado ao servidor e ocorre com frequ�ncia durante a investiga��o de problemas de desempenho, se voc� tiver criado um rastreamento SQL Profiler muito agressivo (que recebe muitos eventos, por exemplo).)

-- PREEMPTIVE_OS_WRITEFILEGATHER (Esse tipo de espera ocorre, entre outros motivos, quando o aumento autom�tico dos arquivos � acionado. T�cnica chamada de autocrescimento, ela ocorre quando um arquivo de tamanho insuficiente � mantido pelo SQL Server em um evento muito dispendioso para a CPU do servidor. Durante o crescimento do arquivo, toda a atividade no banco de dados estar� congelada. Esse crescimento do arquivo de dados pode ser feito rapidamente, permitindo o crescimento do arquivo instant�neos � consulte Arquivo de inicializa��o de banco de dados para mais informa��es. Mas o crescimento do log n�o pode se beneficiar da inicializa��o instant�nea de arquivo de log, porque o crescimento � sempre lento, e �s vezes muito lento. Registrar eventos de autocrescimento pode ser diagnosticado simplesmente olhando para o contador de desempenho no log (confira o link banco de dados de objetos SQL Server para mais informa��es), onde 0 significa que o log registrou o autocrescimento pelo menos uma vez. O monitoramento em tempo real pode ser feito observando o arquivo de dados de autocrescimento e o log de autocrescimento de arquivos no SQL Profiler.)

----------------------------------------
-- Tipos de Wait Types (Tipos de espera)
----------------------------------------
-- Ver planilha: WaitTypes_Descri��o.xls

-- (OUTRA FORMA DE OBTER ESSES DADOS)Wait statistics, or please tell me where it hurts 
-- http://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/


/*******************************************************
 ** Analisar a atividade do disco: estat�sticas de IO **
 *******************************************************/
  
select db_name(io.database_id) as database_name,
    mf.physical_name as file_name,
    io.* 
from sys.dm_io_virtual_file_stats(NULL, NULL) io
join sys.master_files mf on mf.database_id = io.database_id 
    and mf.file_id = io.file_id
order by (io.num_of_bytes_read + io.num_of_bytes_written) desc;


-- SET STATISTICS TIME ON

-- SET STATISTICS IO ON
-- - verifica��o de contagem (N�mero de vezes em que os exames ou a busca foram iniciados em uma tabela. Idealmente, cada tabela deve ser verificada no m�ximo uma vez.)
-- - leituras l�gicas (N�mero de p�ginas de dados a partir do qual as linhas foram lidas a partir do cache de mem�ria (pool de buffer).)
-- - leituras f�sicas (N�mero de p�ginas de dados a partir do qual os dados foram ou tiveram de ser transferidos do cache na mem�ria (�rea de buffer) e a tarefa teve que bloquear para esperar que a transfer�ncia terminasse.)
-- - read-ahead (N�mero de p�ginas de dados que foram transferidas de forma ass�ncrona do disco para o pool do buffer e cuja tarefa n�o esperou nenhum dado para a transfer�ncia.)
-- - LOB l�gico/f�sico (O mesmo que suas contrapartes n�o-LOB, mas referindo-se � leitura de grandes colunas de dados (LOBs).)


/************************************************************************
 ** Analisando o tempo de espera e a execu��o de consultas individuais **
 ************************************************************************/
-- Ver: 01. AnaliseConsulta_WAIT.sql


/*****************************************************************
 ** Analise de Desempenho utilizando o SQL Server e Ferramentas **
 *****************************************************************
 
-- Pontos a serem analisados:
1. CPU - Processamento
2. Mem�ria
3. I/O - Entrada e Sa�da
4. Banco de Dados TempDB
5. Lentid�o na execu��o de Querys

***** Detec��o de Problemas *****
1. Identificar Bottleneck ("Gargalo") - Maior fator que afeta a perfomance
2. Por onde come�ar? Defina sempre problema
	2.1 Qual seu "baseline"?
		- Planilha com informa��es dos problemas que mais apresenta no sistema
	2.2 Aconteceu alguma altera��o no sistema
		- Algum software ou Service Pack novo instalado
3. Aten��o ao limite do seu sistema
	3.1 Trabalhar proximo da capacidade m�xima X Uso ineficiente de recursos

***** Questionamentos *****
1. Existe algum outro recurso do sistema que ser� afetado?
2. Quais os possiveis passos para solucionar o problema?
- Documenta��o � interessante
3. Foi realizada alguma altera��o que possa ter causado o problema?	
- Cria��o de Stored Procedures e etc
- Documenta��o � interessante

##########################
# 1. CPU - Processamento #
##########################
***** Ferramentas utilizadas *****
- System Monitor (Microsoft Windows Server 2003 / 2008)
	- Processor object
		- % Processor Time Counter > 80% (Sinal que CPU � o Gargalo)
	- SQL Statistics
		- Batch Request/sec
		- SQL Compilations/sec
		- SQL Re-Compilations/sec (Ideal: Baixas taxas de recompila��o nas requisi��es)
- Task Manager
	- Performance > CPU Usage
- SQL Server (View DMV's) */
	Select * From sys.dm_os_schedulers
		-- Tarefas que est�o na fila para serem executadas
		-- Identificar se o campo runnable_tasks_count esta alto
	Select * From sys.dm_exec_query_stats
		-- Estatisticas de Plano de Query
		-- Estatisticas do Plano de Cache - (Campos: total_worker_time, execution_count)

/* ***** Causa de Problemas: CPU *****
1. Compila��o e/ou recompila��o excessiva:
	- Problemas:
		- WITH RECOMPILE nas StoredProcedure
	- Ferramentas: 
		- System Monitor > SQL Statistics
		- SQL Trace (SP:Recompile;SQL:StmtRecompile)
	- Objetivo: Identificar e reduzir
	- Solu��es:
		- Considere utilizar tabelas tempor�rias e/ou variavel Table
		- Atualiza��o de estatisticas automaticas (on / off)
		- Use nome de objetos qualificados (dbo.TableA X TableA)
		- N�o misture comandos DDL e DML.
		- Use DTA (Database Engine Tuning Advisor) 
			- http://www.microsoft.com/technet/prodtechnol/sql/2005/sql2005dta.mspx
			- identificar indices n�o utilizados ou necessidade de cria��o de indices.
		- Considere a real necessidade de utilizar WITH RECOMPILE em Stored Procedures

2. Plano de Query ineficiente
	- Ferramentas:
		- DMV's */
			Select * From sys.dm_exec_query_stats
			Select * From sys.dm_exec_sql_text -- Diagnosticar CPU  
			-- Procuram por Querys que fazem uso itensivo de CPU
			Select * From sys.dm_exec_cached_plans -- Procura por operadores que fazem uso da CPU 
			/*
	- Objetivo: 
		- Coletar informa��es para escrever query com planos mais eficientes 
	- Solu��es:
		- Use DTA para checar recomenda��es de indices
		- Use de forma restritiva a clausula WHERE
			- Causa problemas em rela��o a CPU
		- Mantenha as estatisticas atualizadas
		- Procure por Query que n�o foram escritas seguindo boas praticas de desenvolvimento
		- Considere utilizar "Query hints"
			- OPTIMIZE FOR - valor de parametro particular para otimiza��o
			- FORCE ORDER - preserva a ordem dos joins
			- USE PLAN - for�a o Plano de Query

3. Paralelismo "Intra-query"
	- Problema:
		Querys utilizando paralelismo tem um custo alto para a CPU
	- Ferramentas:
		- DMV's */
			Select * From sys.dm_exec_requests
			Select * From sys.dm_os_tasks
			Select * From sys.dm_exec_sessions
			Select * From sys.dm_exec_sql_text
			Select * From sys.dm_exec_query_stats --Campos: total_worker_time e total_elapsed_time
			/*			
	- Objetivo: Identificar querys rodando com paralelismo e torna-las mais eficientes.
	- Solu��es:
		- Use DTA
		- Mantenha as estatisticas atualizadas
		- Procure por estatisticas desatualizadas
		- Avalie se a query pode ser reescrita de forma mais eficiente utilizando o T-SQL.

$$$$$ Demonstra��o CPU $$$$$ */	
---------------------------------------------------------
-- 1. Retorna as 10 Querys com maior tempo de execu��o --
---------------------------------------------------------
Select  Top 10
		creation_time
,		last_execution_time
,		total_clr_time
,		total_clr_time / execution_count as [Avg CLR Time]
,		last_clr_time
,		execution_count
,		Substring (st.text, (qs.statement_start_offset / 2) + 1,
		((Case statement_end_offset
			when -1 then datalength(st.text)
			else qs.statement_end_offset 
			end -qs.statement_start_offset)/2) + 1) as Query
From	sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as st
Order by
		total_clr_time / execution_count desc

-----------------------------------------------------------------------
-- 2. Retorna a M�dia das 5 Query's que mais consumiram tempo de CPU --
-----------------------------------------------------------------------
Select Top 10
		total_worker_time / execution_count as [Avg CPU Time]
,		Substring (st.text, (qs.statement_start_offset / 2) + 1,
		((Case statement_end_offset
			when -1 then datalength(st.text)
			else qs.statement_end_offset 
			end	-qs.statement_start_offset)/2) + 1) as Query		
From	sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as st
Order by
		total_worker_time / execution_count desc	

/*############
# 2. Mem�ria #
##############
- Problemas:
	- Erros expl�citos relacionados a mem�ria (ex. "Out of memory", "timeout" enquanto aguarda
    por recursos de m�moria livre)
	- Valor baixo de "buffer cache hit ratio"
	- Utiliza��o incomum e excessiva de I/O
	- Lentid�o no sistema de uma forma geral
- Erros relacionados(Mensagens):*/
	Select * from sys.messages 
	Where	message_id in (701, 802, 8628, 8645, 8651)
	and		language_id = 1033 --Ingl�s
	/*
- Ferramentas: (Detec��o e An�lise)
	- Task Manager
		- Mem Usage, Virtual Machine Size
		- Physical Memory, Commit charge (Uso do Page File)
			- Ideal: Page File Fixo
	- System Monitor
		- Performance object: Process
			- Counters: Working set, Private bytes
		- Performance object: Memory 
			- Counters: Avaliable KBytes, System Cache, Resident Bytes, Committed bytes, Commit Limit
		- Performance object: SQLServer: Buffer Manager
			- Counters: Buffer cache hit ratio, Page file expectancy, Checkpoint pages/sec, Lazy writes/sec
		- Performance object: SQLServer: Memory Manager
	- DM'V's: */
		Select * From sys.dm_os_memory_clerks
			-- Trabalhadores ativos de mem�ria (por inst�ncia)
		Select * From sys.dm_os_memory_cache_clock_hands
			-- Status de ponteiro para cache especifico
		Select * From sys.dm_os_memory_cache_counters
			-- Snapshot (Estado do Cache), endere�o de entrada do cache
		Select * From sys.dm_os_ring_buffers
			-- Altera��es no estado da mem�ria
		Select * From sys.dm_os_virtual_address_dump /*
	- DBCC */
		dbcc memorystatus /*
			- Buffer distribution
			- Buffer counts
			- Global memory objects
			- Query memory object
			- gateways
- Objetivo:
	- Analisar consumo de mem�ria
- Solu��es:
	- Verifique par�metros de configura��o de mem�ria no servidor (Configura��es inconsistentes)
		- Min memory per query 
		- Min/Max server memory
		- Awe enable
		- Lock pages em mem�ria privilegiada
	- Realize sucessivas coletas de informa��es utilizando DMV's e DBCC memorystatus e dos contadores
	de performance do System Monitor (Compare com sua "BaseLine")
	- Confira a carga de trabalho (N�mero de Queries/sessions)
	- Entenda a raz�o do aumento de consumo de mem�ria e tente sempre que possivel elimina-las.
		- Muitas vezes n�o ser� possivel, ai cabe analisar se vai ser necess�rio adi��o de + mem�ria.

$$$$$ Demonstra��o MEM�RIA $$$$$ */
	Select * From sys.dm_os_memory_cache_counters -- Exemplo 1 > Detalhes mais acima
	dbcc memorystatus -- Exemplo 2 > Detalhes mais acima
	Select * From sys.dm_os_memory_clerks -- Exemplo 3 > Detalhes mais acima 

/*###########################
# 3. I/O - Entrada e Sa�da #
############################
- Problemas(Vil�es):
	- Movimenta��o de p�ginas do banco de dados da mem�ria para o disco e vice-versa
	- Opera��es dos arquivos de Log
	- Opera��es no Banco de Dados TempDB
- Sinais de Problemas:
	- Tempo de resposta baixo
	- Mensagem com erros de "timeout"
	- O sistema de I/O operando em sua capacidade m�xima
- Objetivo:
	- Identificar "gargalos" no I/O
- Fases de Detec��o / Ferramentas:
	- System Monitor (Performande Monitor)
		- % Disk Time > 50% (Problema)
		- Avg. Disk Queue Length > 2 (Problema Grave)
		- Avg. Disk sec/Read ou Avg. Disk sec/Write 
			- < 10ms (Muito Bom)
			- > 10 e <= 20ms (Bom)
			- > 20 e <= 50ms (Aten��o Especial)
			- > 50ms (Grave - Gargalo no I/O)
		- Avg. Disk Reads/sec ou Avg. Disk Writes/sec > 85% da capacidade do disco
			- Problema Grave
			- Ajustes para RAID:
				- RAID 0  : I/Os per disk = (reads + writes) / numero de discos
				- RAID 1  : I/Os per disk = [reads + (2 * writes)] / 2
				- RAID 5  : I/Os per disk = [reads + (4 * writes)] / numero de discos
				- RAID 1+0: I/Os per disk = [reads + (2 * writes)] / numero de discos
	- DMV's: */
		Select * From sys.dm_os_wait_stats where wait_type like 'PAGEIOLATCH%'
			-- Tempo gasto na fila (Ficaram na fila)
		Select * From sys.dm_io_pending_io_requests
			-- 1 Linha para cada requisi��o de I/O pendente
		Select * From sys.dm_exec_query_stats
			-- *_reads
			-- *_writes columns
		/*
- Solu��o / An�lise:	
	- Certifique-se que esta usando �timos planos de query
		- Possibilidade de reescrever em caso de planos de query n�o eficientes
	- Alto I/O pode indicar "Gargalo" na mem�ria
	- Confira a quantidade de mem�ria e analise a possibilidade de adi��o.
	- Aumente a largura de banda do I/O
		- Discos r�pidos
		- Controladoras	com mais cache (Em sincronia com os discos)
	- Esteja sempre atento a capacidade do seu sistema	
	
$$$$$ Demonstra��o I/O $$$$$ */
	Select * From sys.dm_os_wait_stats where wait_type like 'PAGEIOLATCH%'`
		-- Exemplo 1 > [Tempo gasto na fila (Ficaram na fila)]
	Select * From sys.dm_io_virtual_file_stats (DB_ID(N'AdventureWorks'), 1) 
		-- 1 � para arquivos de Dados (Informa��es de Escrita e Leitura)
	Select * From sys.dm_io_virtual_file_stats (DB_ID(N'AdventureWorks'), 2)
		-- 2 � para arquivos de Log (Informa��es de Escrita e Leitura)

/*##########################
# 4. Banco de Dados TempDB #
############################
- Utiliza��o:
	- Armazenamento de tabelas tempor�rias (#Locais e/ou ##Globais)
	- SQL Server utiliza para criar objetos internos
	- Tem o seu conte�do eliminado quando o servi�o do SQL Server � parado
		- Recriado novamente ao iniciar o servi�o 
- Problema:
	- Procedimentos sendo executados fora do TempDB
	- "Gargalos" nas "System Tables" devido as excessivas opera��es de DDL
- Objetivo:
	- Monitorar o uso excessivo de DDL, procurar e, se poss�vel, 
	eliminar "procedimentos intrusos" no TempDB.
- Ferramentas:
	- DMV's: */
		Select * From sys.dm_db_file_space_usage
			-- Retorna informa��es de espa�o utilizado por cada arquivo no Database
			-- Usuarios, Objetos internos e Espa�o utilizado
		Select * From sys.dm_tran_active_snapshot_database_transactions
			-- Transa��es que rodam lentamente > Maior Espa�o
			-- Retorna todas as transa��es ativas no TempDB
		Select * From sys.dm_db_session_space_usage
			-- N�mero de p�ginas alocadas ou n�o alocadas para cada sess�o do Database
		Select * From sys.dm_db_task_space_usage 
			-- Retorna atividades de Aloca��o e Desaloca��o das tarefas do Database
		/*
	- System Monitor(PerfMon):
		- SQL Server: Transactions Object
			- Version Generation / Cleanup rates
- Solu��o:
	- Fa�a um plano de capacidade para o TempDB
		- Contabilize os procedimentos que utilizam o TempDB
		- Reserve espa�o suficente para o TempDB
	- Objetos "User": Identifique e elimine usu�rios desnecess�rios no TempDB
	- Cuidados com o tamanho do TempDB
		- Elimine longas transa��es sempre que poss�vel
 	- Excessivos DDL:
		- Considere quando criar tabelas tempor�rias (Locais e/ou Globais)
		- Considere os planos de query que criam diversos objetos internos e verifique se
		est�o escritos de forma eficiente ou se ser� preciso descreve-los.	
	
##########
# Extras # 
##########
---- Script com tarefas em tempo real no TempDB */
Select 
		t1.session_id
,		(t1.internal_objects_alloc_page_count + task_alloc) as allocated
,		(t1.internal_objects_dealloc_page_count + task_dealloc) as deallocated 
From	sys.dm_db_session_space_usage as t1
,		(Select 
				session_id
		,		sum(internal_objects_alloc_page_count) as task_alloc
		,		sum (internal_objects_dealloc_page_count) as task_dealloc 
		From	sys.dm_db_task_space_usage 
		Group by 
				session_id) as t2
Where 
		t1.session_id = t2.session_id and t2.session_id > 50
order by 
		allocated DESC

-- Para otimiza��o (Estudar)
Select * From	sys.dm_exec_query_optimizer_info
Where	counter in ( 
	'optimizations'
,	'elapsed time'
,	'trivial plan'
,	'tables'
,	'insert stmt'
,	'update stmt'
,	'delete stmt')


-- Auxiliares
Select @@TRANCOUNT -- Transa��es da sess�o corrente

------------------
-- Bibliografia --
------------------
--http://msdn.microsoft.com/pt-br/library/bb510669.aspx (Performance)