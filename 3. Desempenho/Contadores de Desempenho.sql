/******************************
 ** Contadores de Desempenho **
 ******************************/
--select * from sys.dm_os_performance_counters

-- Montando...                                                                                                     
Select	A = Convert(decimal (19,5), (  ( SELECT convert(decimal(19,8), cntr_value) FROM sys.dm_os_performance_counters WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Buffer cache hit ratio')
									 / ( SELECT convert(decimal(19,8), cntr_value) FROM sys.dm_os_performance_counters WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Buffer cache hit ratio base'))) * 100
,		B = ( SELECT cntr_value AS 'Page Life Expectancy - Ideal > 300' FROM sys.dm_os_performance_counters
			  WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Page life expectancy') 

-- A = Buffer cache hit ratio - Ideal > 99
-- B = Page Life Expectancy - Ideal > 300

/***************************
 ** Contadores de MEM�RIA **
 ***************************/
-- Mem�ria do Servidor
Select	counter_name 
,		cntr_value
,		cast((cntr_value/1024.0) as numeric(8,2)) as Mb
,		cast((cntr_value/1024.0)/1024.0 as numeric(8,2)) as Gb
From sys.dm_os_performance_counters
Where counter_name like '%server_memory%';

-- Mem�ria: Alocada em Cache por Banco de Dados
SELECT	DB_NAME(database_id) AS [Database Name]
,		COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
,		SUM (CAST ([free_space_in_bytes] AS BIGINT)) / (1024 * 1024) AS [Cached Size (MB) - Empty]
FROM	sys.dm_os_buffer_descriptors
WHERE	database_id > 4		 -- exclude system databases
AND		database_id <> 32767 -- exclude ResourceDB
GROUP BY 
		DB_NAME(database_id)
ORDER BY
		[Cached Size (MB)] DESC


-- Mem�ria: Utiliza��o por tipo de cache
SELECT  type, SUM(single_pages_kb)/1024. AS [SPA Mem, MB],SUM(Multi_pages_kb)/1024. AS [MPA Mem,MB]
FROM sys.dm_os_memory_clerks
GROUP BY type
HAVING  SUM(single_pages_kb) + sum(Multi_pages_kb)  > 40000 -- S� os maiores consumidores de mem�ria
ORDER BY SUM(single_pages_kb) DESC

-- O CACHESTTORE_OBJCP  � o cache das Stored procedures, Triggers e Functions.
-- O CACHESTORE_SQLCP � o cache de Ad-hoc queries e n�o � muito reutilizado pelo SQL Server, pois para uma mesma consulta com par�metros diferentes, s�o gerados dois planos de execu��es diferentes.
-- O USERSTORE_TOKENOERM � o cache que armazena v�rias informa��es de seguran�a que s�o utilizadas pela Engine do SQL Server.

-- Mem�ria: Total utilizado
SELECT  SUM(single_pages_kb)/1024. AS [SPA Mem, MB],SUM(Multi_pages_kb)/1024. AS [MPA Mem, MB]
FROM sys.dm_os_memory_clerks


/*************************
 ** Performance Monitor **
 *************************

 *************************************
 * Objeto: SQL Server:Buffer Manager *
 *************************************
 (Est� relacionado a inst�ncia SQL Server, cada inst�ncia SQL Server ter� objetos pr�prios)
    - Buffer Cache Hit Ratio: indica o percentual de p�ginas de foram atendidas pelo buffer pool. O ideal � que este 
valor seja igual ou superior a 99%. Valores inferiores podem indicar mem�ria insuficiente para a inst�ncia SQL Server.
		- Ideal: > 90%
		- Ruim.: < 90%

    - Checkpoints Page/sec: indica o n�mero de p�ginas limpas no disco por segundo. O valor ideal � abaixo de 50. Se este valor 
estiver constantemente alto, pode indicar que a inst�ncia SQL Server precisa de mais mem�ria.
		- Ideal: < 50
		- Ruim.: > 50 (Constantemente)

    - Lazy writes/sec: indica o n�mero de vezes por segundo que o lazy write elimina as p�ginas do buffer cache. Se este valor 
estiver maior que 20, pode indicar que a inst�ncia SQL Server precisa de mais mem�ria.
		- Ideal: < 20
		- Ruim.: > 20

    - Page life expectancy: indica a expectativa de vida (em segundos) de uma p�gina de dados na mem�ria. O ideal � que este 
valor seja sempre superior a 300 segundos. Valores inferiores podem indicar necessidade de mem�ria para a inst�ncia SQL Server.
		- Ideal: > 300 seg
		- Ruim.: < 300 seg

    - Target Pages:  indica o n�mero ideal de p�ginas no buffer pool.

    - Total Pages: indica o n�mero de p�ginas que est�o no buffer pool no momento.  Este valor deve ser menor 
o valor do contador Target Pages.
		- Ideal: < Target Pages
		
	- Page reads/sec (80 a 90)
	
	- Page Writes/sec (80 a 90)

 *************************************
 * Objeto: SQL Server:Access Methods *
 *************************************
	- Page Splits/sec: Mostra quantos page splits est�o ocorrendo no servidor. Este valor deve ser o mais baixo poss�vel. Se o valor estiver alto,
configurar os �ndices com um fillfactor apropriado pode ajudar a reduzir este valor.
		- Ideal: Sempre baixo

	- Full Scans/sec
	
 *************************************
 * Objeto: SQL Server:Memory Manager *
 *************************************
 (Est� relacionado a inst�ncia SQL Server) 
	- Memory Grants Pending: indica o n�mero de processos esperando na �rea de trabalho da mem�ria. O ideal � este valor fique 
pr�ximo de zero. Caso os valores sejam constantemente altos, deve-se certifica-se de que o problema est� relacionado a 
insuficiencia de mem�ria e n�o a objetos dos bancos de dados.
		- Ideal: 0 (Pr�ximo a 0)
		- Ruim.: Valores constantemente altos

    - Target Server Memory: indica o total de mem�ria que a inst�ncia SQL Server pode utilizar.

    - Total Server Memory: indica o total de mem�ria que a inst�ncia SQL Server est� utilizando no momento. Se este valor for 
igual ou maior que o valor do Target Server Memory, pode indicar a necessidade de mais mem�ria para a inst�ncia SQL Server. 
		- Ideal: < Target Server Memory
		- Ruim: >= Target Server Memory
 
 *******************
 * Objeto: Process *
 *******************
 (Relacionado ao servidor que hospeda a  inst�ncia SQL Server)
	- Working Set: indica o tamanho do conjunto da carga de trabalho dos processos em bytes na mem�ria f�sica do servidor. 
Caso este valor permane�a sempre abaixo do m�nimo de mem�ria configurada para inst�ncia SQL Server, isso indica que a inst�ncia 
est� configurada com mais mem�ria do que realmente precisa.
		- Ideal: > M�nimo de Mem�ria configurada para a instancia
		- Ruim: < M�nimo de Mem�ria configurada para a instancia
	
	- % Processor time: sqlservr ==> Indica o consumo do processador pelo processo do SQL Server.
		- Ideal : < 80%
	
	- Processo Queue Length ( < 2 )

 *******************************
 * Objeto: Disco (LogicalDisk) *
 *******************************
	- Avg disk sec/read (Ideal: < 12ms)
	- Avg disk sec/write (Ideal: < 12ms)
	
 ****************
 * Objeto: Rede *
 ****************
	- Bytes Received/sec
	- Bytes Sent/sec
 
 ******************
 * Objeto: Memory *
 ******************
	- Available Mbytes: indica a quantidade de mem�ria dispon�vel em MB no momento. O ideal � que este 
contador esteja com valor acima de 100 MB. Valores inferiores podem indicar a necessidade de mais mem�ria RAM.
		- Ideal: > 100MB
		- Ruim.: < 100 MB		
		
    - Pages/sec: indica o n�mero de p�ginas que s�o p�ginadas na mem�ria para o disco por segundo. O ideal � 
que este a m�dia deste contador esteja sempre pr�ximo de zero  em um intervalo de 24 horas e em situa��es 
normais. Picos ocasionais podem aumentar este valor. Se a m�dia do contador for maior que 20, o servidor 
precisar� de mais mem�ria RAM. 
		- Ideal: 0 (M�dia proximo a 0)
		- Ruim.: > 20 (M�dia)
		
	- Pages faults/sec
	
 ******************************************
 * Objeto: System: Processor Queue Length *
 ******************************************
	- Indica o n�mero de threads aguardando para execu��o no processador e nunca deve exceder 1 ou 2 (por processador) por 
um per�odo superior a 10 minutos.


-- Fontes:
-- http://tatianecosvieira.wordpress.com/2011/08/03/artigo-performance-no-sql-server-%E2%80%93-memoria-parte-1/
-- http://dicasdeumdba.wordpress.com/tag/perfmon/

*/