/*	O SQL Server 2005, apresenta v�rias inova��es em rela��o ao SQL Server 2000, dentro as quais 
destacamos a cla�sula TableSample.
	Atrav�s desta cla�sula � poss�vel retornar os dados especificados no select, de forma aleat�ria
sem ter a necessidade de utilizar a fun��o NewID().
 
Veja abaixo o c�digo de exemplo: */
 
USE AdventureWorks
GO
WITH Aleatorio AS
(SELECT * FROM Person.Contact TABLESAMPLE(1 PERCENT))
SELECT TOP(3) * FROM Aleatorio

SELECT FirstName, LastName FROM Person.Contact
TABLESAMPLE (10 percent)
 
SELECT FirstName, LastName  FROM Person.Contact
TABLESAMPLE (100 rows)
 
SELECT FirstName, LastName FROM Person.Contact
 TABLESAMPLE (10 percent)
 repeatable(10)