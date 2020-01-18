-- Servidor principal.: ServidorA
-- Servidor secund�rio: ServidorB\Teste

-- Estou no ServidorA e quero acessar ServidorB\Teste
-- Tb pega os dados da hora anterior
Select *
from [ServidorB\Teste].BancoTesteB.dbo.TbTesteB
Where Datepart(hour, DataHora) = Datepart(hour, getdate())-1
and	Convert(varchar,DataHora,112) = Convert(varchar,getdate(),112)
order by DataHora desc

---- Para inserir estas informa��es em uma tabela do BancoTesteA
--insert into BancoTesteA..TbTesteA
--Select *
--from [ServidorB\Teste].BancoTesteB.dbo.TbTesteB
--Where Datepart(hour, DataHora) = Datepart(hour, getdate())-1
--and	Convert(varchar,DataHora,112) = Convert(varchar,getdate(),112)
--order by DataHora desc

--Criando um linked server entre o SQL Server e o Access
--EXEC sp_addlinkedserver
--@server = 'BigSolo', -->nome do linked server
--@provider = 'Microsoft.Jet.OLEDB.4.0', -->provider de conex�o para o Access
--@srvproduct = 'OLE DB Provider for Jet', -->descri��o do provider utilizado na conex�o
--@datasrc = 'C:\Big-Solo.mdb' --> nome do arquivo.mdb
--GO
--Select * from [BigSolo]...Produto -->Forma de acesso 
