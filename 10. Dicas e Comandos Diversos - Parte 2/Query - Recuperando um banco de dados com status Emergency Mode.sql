/*	Manuten��o em um banco de dados, existente dentro de uma inst�ncia no SQL Server 2005, que esteja 
apresentando o status de emergency, mais conhecido como emergency mode.
	Este status representa que o banco de dados pode estar apresentando algum tipo de falha ou 
inconsist�ncia em sua integridade f�sica ou l�gica, para realizar uma manuten��o em banco de dados e 
reparar as poss�veis perdas de informa��es, veja abaixo o script de exemplo:*/
 

--Verificando o Status do banco
Select * from sys.sysdatabases Where Name='Estoque'

--Mudando o estado do banco para Emergency
Alter Database Estoque Set Emergency

--Verificando o Status do banco
Select * from sys.sysdatabases Where Name='Estoque'

Use Estoque
go
--Permitindo acesso somente para um usu�rio
sp_dboption 'Estoque', 'dbo use only', false
go
sp_dboption 'Estoque','single_user', true
go

--Verificando a integridade f�sica e l�gica do banco, reconstru�ndo os dados perdidos
dbcc checkdb ('SeuBanco',repair_allow_data_loss)
go
--Voltando o acesso ao banco para multi usu�rio.
sp_dboption 'Estoque', 'dbo use only', false
go
sp_dboption 'Estoque','single_user', false
go
--Verificando o Status do banco
Select * from sys.sysdatabases Where Name='Estoque'