-- Estudando SQL Server 2008

-- Capitulo: 14
-- Create Database EstudoSQL2008;

-- Use the CREATE DDL statement to create a new table named Produce
--Create table Produce(
--	Productid int primary key
--,	ProductName varchar(50)
--,	ProductType varchar(20))
--GO

-- Use the INSERT DML statement to add rows to the Produce table
INSERT Produce VALUES
	(1, 'Tomato', 'Vegetable')
,	(2, 'Pear', 'Fruit')
,	(3, 'Kiwifruit', 'Fruit');
GO

-- Use the CREATE DDL statement to create a new view named Fruit that shows us only produce of type 'Fruit'
CREATE VIEW Fruit AS
	SELECT * FROM Produce WHERE ProductType = 'Fruit';
GO

-- Add a new column
ALTER TABLE Produce
	ADD Price Money;
GO

-- Ver estrutura da tabela
sp_help Produce

-- Use the UPDATE statement to set prices
UPDATE Produce SET Price = 2.50 WHERE ProductID = 1;
UPDATE Produce SET Price = 3.95 WHERE ProductID = 2;
UPDATE Produce SET Price = 4.25 WHERE ProductID = 3;
GO

-- Visualizando dados da tabela Produce
Select * From Produce;

ALTER VIEW Fruit AS
SELECT ProductID, ProductName, Price FROM Produce WHERE ProductType =
'Fruit';
GO

-- Visualizando dados da View Fruit
Select * From Fruit;


/*------------------------
--Use Dw_NegociandoCE
SELECT *
FROM Transacao, Cliente
WHERE Transacao.CdCliente *= Cliente.CdCliente
------------------------*/
Mensagem 4147, N�vel 15, Estado 1, Linha 3
A consulta usa operadores de jun��o externa n�o-ANSI ('*=' ou '=*'). Para executar esta consulta sem modifica��es, defina o n�vel de compatibilidade do banco de dados atual como 80, usando a op��o SET COMPATIBILITY_LEVEL de ALTER DATABASE. � bastante recomend�vel regravar a consulta usando operadores de jun��o externa ANSI (LEFT OUTER JOIN, RIGHT OUTER JOIN). Nas vers�es futuras do SQL Server, os operadores de jun��o n�o-ANSI n�o ter�o suporte nem mesmo para manter compatibilidade com vers�es anteriores.
