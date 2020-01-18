/*
	Formatando dados para exporta��o
	Quando temos que exportar dados para sistemas de terceiros ou outras empresas, algumas regras 
s�o impostas (layout). A mais comum � enviar campos num�ricos com zeros � esquerda e espa�os 
em branco a direita dos campos string.
	Segue abaixo exemplo de duas fun��es (FC) para formata��o desses tipos de campos. 
*/

create function f_dba_ad_espaco(@campo varchar(200), @tamanho int)
returns varchar(200)
as
begin
return left(@campo + replicate(' ',@tamanho), @tamanho)
end


create function f_dba_ad_zeros(@campo varchar(200), @tamanho int)
returns varchar(200)
as
begin
return right(replicate('0',@tamanho) + replace(@campo,' ',''), @tamanho)
end

/* Para testar as fun��es acima podemos utilizar o utilit�rio BCP do MS SQL Server, executado direto do 
�MS SQL Server Management Studio�.
   A partir da vers�o 2005 tempos que habilitar a execu��o do �XP_cmdshell�. */

exec sp_configure 'show advanced options',1
reconfigure
go

exec sp_configure 'xp_cmdshell',1
exec sp_configure 'show advanced options',0
reconfigure
go


----------------------------------------------------------------------
-- Exemplo
----------------------------------------------------------------------
select dbo.f_dba_ad_espaco('Tulio Rosa',30) + dbo.f_dba_ad_zeros(123,10) as arq
into ##temp

select * from ##temp


----------------------------------------------------------------------
-- Gera o arquivo texto
----------------------------------------------------------------------
declare @dir_arquivo nvarchar(500)
declare @exec nvarchar(1000)
declare @test_exec bit

set @dir_arquivo = 'k:\teste.txt'

set @exec = 'bcp "select arq from ##temp" queryout ' + @dir_arquivo + ' -r \n -Snomeservidor -Uusuario -Psenha -c -C raw'
exec @test_exec = master..xp_cmdshell @exec

if @test_exec <> 0 raiserror ('Erro na geracao do arquivo!', 16,1)


/*	Identificando espa�os em branco dentro de um campo cararacter
Como realizar a verifica��o para identificar a exist�ncia de espa�os em branco contidos dentro de um 
campo char, varchar, nvarchar, nchar. Veja abaixo o c�digo de exemplo: */ 
SELECT	
		<Campo>
,	CASE WHEN CharIndex(' ',<Campo>,1)=0 
		THEN 'N�o Tem' 
	ELSE	 'Tem'
    END
FROM	<Tabela>