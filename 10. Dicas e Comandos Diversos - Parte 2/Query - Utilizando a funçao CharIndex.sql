Create Table #ExemploCharIndex (
	CampoTexto VarChar(100))

--drop table #ExemploCharIndex

Insert Into #ExemploCharIndex Values('Com Espa�o')
Insert Into #ExemploCharIndex Values('Sem_Espa�o')
Insert Into #ExemploCharIndex Values('Testando1')
Insert Into #ExemploCharIndex Values('Testando 2 e 3')
Insert Into #ExemploCharIndex Values('Teste(),TESTE__)(')
Insert Into #ExemploCharIndex Values('Teste(),TESTE__)( ')

Select 
	CampoTexto
,	[Tem Espa�o ?] = Case 
						When CharIndex(' ', CampoTexto, 1) = 0 Then 'N�o Tem' Else 'Tem'
					 End
From #ExemploCharIndex