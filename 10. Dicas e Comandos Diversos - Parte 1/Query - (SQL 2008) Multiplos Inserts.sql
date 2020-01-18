/* At� a vers�o 2005 do SQL Server, para incluir registros era necess�rio utilizar um 
INSERT para cada registro. No SQL Server 2008 esse problema foi resolvido, permitindo
agora a inclus�o de mais de um registro em um �nico INSERT. O exemplo abaixo demonstra 
a sua utiliza��o: */
 
INSERT Clientes (cod, nome, endereco) VALUES
	(1, 'Alexandre Lopes', 'Quadra 1 lote 10')
,	(2, 'K�tia Rodrigues', 'Quadra 1 lote 12')
,	(3, 'Marcia Cristina', 'Quadra 2 lote 10)