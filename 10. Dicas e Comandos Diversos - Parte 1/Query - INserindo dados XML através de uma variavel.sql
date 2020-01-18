/*	Inserindo dados XML atrav�s de uma vari�vel
	Como inserir dados armazenados dentro de 
uma vari�vel XML, em uma table, que utiliza campos XML.
Veja abaixo o c�digo de exemplo: */
 
Create Table Produtos (
	Codigo Int Identity(1,1)
,	DadosXML XML)

Declare @vXML XML
SET @vXML = '<Raiz>
                     <Codigo>1</Codigo>
                     <Nome>Arroz</Nome>
                     </Raiz>'
GO
 
SELECT @vXML
GO
 
Insert Into Produtos(Codigo, DadosXML) Values(@vXML)
GO

select * from Produtos
