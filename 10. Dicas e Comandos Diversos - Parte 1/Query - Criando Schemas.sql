/*	Cole��o de Objetos dentro de um Database que permite agrupar objetos ao n�vel de
aplica��es(Maior seguran�a).
	Pode atribuir usuarios a Schemas e etc. */

Use AdventureWorks
GO

Create Schema RH Authorization [dbo]

Create Table Funcionarios (
	Cod		int
,	Nome	varchar(50)
,	Descr	varchar(50))
GO