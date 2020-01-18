/*	Muitas vezes temos a necessidade de criar uma seq��ncia n�merica de valores de forma autom�tica. 
	O SQL Server fornece esta funcionalidade atrav�s da op��o Identity que pode ser configurada para 
um campo dentro de uma table.
	Mas caso seja necess�rio alterar esta seq��ncia num�rica j� existe mantendo os dados j� existentes,
o SQL Server tamb�m consegui fazer este gerenciamento de valores tranquilamente, mas caso o servidor 
seja reinicializada o valor Identity definido para a coluna � reinicializado, ou seja, caso o �ltimo 
valor identity gerado seja o n�mero 10, ap�s a reinicializa��o do servidor este valor ser� reinicializado 
para o n�mero 1.
	Justamente por este motivo, o script a seguir permite melhorar esta l�gica, possibilitando mant�r 
este valor sequencial sempre atualizado, veja abaixo o c�digo de exemplo: */ 

-- Para desativar a propriedade identity na table desejada: 
SET IDENTITY_INSERT NomedaTable Off
 
-- Para ativar a propriedade identity na table desejada: 
SET IDENTITY_INSERT NomedaTable On

Declare @Identity Int
---Refazendo numera��o Controle de Entrada - Mat�ria Prima ---
Set @Identity=(Select Ident_Current('CTEntrada_PQC'))
DBCC CheckIdent('CTEntrada_PQC',Reseed,@Identity)

---Refazendo numera��o Controle de Produ��o - Moinho ---
Set @Identity=(Select Ident_Current('CTProducao_Moinho'))
DBCC CheckIdent('CTProducao_Moinho',Reseed,@Identity)

---Refazendo numera��o Controle de Entrada - Recebimento - L�tex ---
Set @Identity=(Select Ident_Current('CTEntrada_Recebimento_L�tex'))
DBCC CheckIdent('CTEntrada_Recebimento_Latatex',Reseed,@Identity)

---Refazendo numera��o Controle de Produ��o - PVM ---
Set @Identity=(Select Ident_Current('CTProducao_PVM'))
DBCC CheckIdent('CTProducao_PVM',Reseed,@Identity)