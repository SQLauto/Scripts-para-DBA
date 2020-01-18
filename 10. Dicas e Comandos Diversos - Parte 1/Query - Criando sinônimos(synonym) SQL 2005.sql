/*	Uma das novidades existentes no SQL Server 2005, mas pouco conhecida e utilizada s�o os sin�nimos. 
	Este recurso tem como objetivo proporcionar a possibilidade de criar apelidos para um ou mais 
objetos que fa�am parte deste sin�nimo. Sua utiliza��o facilita em muito o desenvolvimento de scripts, 
quando se existe a necessidade de utilizar objetos em locais distintos armazenados no SQL Server. 
Com esta alternativa o SQL Server torna-se ainda mais pr�tico e flex�vel no desenvolvimento de blocos 
de transa��o, acelerando a busca de objetos na composi��o do c�digo esta sendo criado.
	Para criar um sin�mino � poss�vel utilizar tables, views, fun��es scalar, fun��es in-line, 
stored procedure, extended stored procedure, assembly e filtros de replica��o, sendo necess�rio que 
estes objetos existam fisicamente no servidor SQL Server, caso contr�rio a cria��o ou altera��o deste 
sinonimo � cancelada.
	Veja abaixo o c�digo de exemplo para se criar um novo sin�nimo(synonym)*/
 
-- Create a synonym for the Product table in AdventureWorks.
USE tempdb;
GO
CREATE SYNONYM MeusProdutos
FOR AdventureWorks.Production.Product;
GO

-- Query the Product table by using the synonym.
USE tempdb;
GO
SELECT ProductID, Name
FROM MeusProdutos
WHERE ProductID < 5;
GO