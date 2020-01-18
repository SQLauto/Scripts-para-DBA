/*Antes de come�armos a aplicar as Estat�sticas Filtradas e seus benef�cios, vamos criar um novo 
ambiente para teste. Neste ambiente criaremos duas novas tabelas denominadas:Cidades e Vendas, 
conforme apresenta a C�digo 1.

C�digo 1 � Criando as tabelas Cidades e Vendas:*/
-- Criando a Tabela Cidades �
Create Table Cidades
 (Codigo Int,
   Nome VARCHAR(100),
   Estado Char(2))
Go
-- Criando a Tabela Vendas �
Create Table Vendas
  (Codigo Int,
    NumPedido Int,
    Quantidade Int)
Go
/*	Observe que ambas as tabelas possui uma estrutura simular e est�o declaradas sem chaves 
prim�rias. 
	Agora vamos adicionar em cada tabelas os recursos de Estat�sticas, que ser�o utilizados pelo 
SQL Server durante os processos de consulta e manipula��o dos registros. Posteriormente ser�o 
adicionados �ndices Clusterizados para cada tabela, com objetivo de melhorar os processos de busca 
de dados, al�m de adotar uma forma de ordena��o f�sica dos dados, conforme apresenta o C�digo 2.
*/
-- C�digo 2 � Criando Estat�sticas e �ndices para as Tabelas Cidades e Vendas:
-- Criando os �ndices Clusterizados para Tabela Cidades
Create Clustered Index Ind_Cidades_Codigo ON Cidades(Codigo)
Go
-- Crinado um novo �ndice para Tabela Cidades �
Create Index Ind_Cidade_Nome ON Cidades(Nome)
Go
-- Criando novas Estat�sticas para a Tabelas Cidades �
Create Statistics Sts_Cidade_Codigo_Nome ON Cidades(Codigo, Nome)
Go
-- Criando os �ndices Clusterizados para Tabela Vendas �
Create Clustered Index Ind_Vendas_Codigo_NumPedido ON Vendas(Codigo,NumPedido)
Go

/*	Observe que foi adicionado somente 1 �ndice Clusterizado a Tabela Vendas, ao contr�rio da 
Tabela Cidades que adicionamos, 1 �ndice Clusterizado e outro �ndice comum, nenhum recurso ou 
mecanismo de Est�tistica foi adicionado e esta tabela.
	Como nosso ambiente criado e pronto para receber nossos dados, vamos ent�o realizar os processo 
de carga de dados, para cada tabela, conforme apresenta o C�digo 3.

C�digo 3 � Carga de dados para as Tabelas Cidades e Vendas. */

-- Inserindo dados no Tabela Cidades
Insert Cidades Values(1, 'S�o Roque', 'SP')
Insert Cidades Values(2, 'S�o Roque da Fartura', 'MG')
Go
-- Bloco para inser��o de registros na Tabela Vendas
Set NoCount On
Insert Vendas Values(1, 1, 100)
Declare @Contador INT
Set @Contador = 2
While @Contador <= 1000
 Begin
  INSERT Vendas VALUES (2, @Contador, @Contador*2)
  SET @Contador +=1
End
Go

Select * from Cidades
Select * from Vendas

/* Neste momento nosso ambiente encontra-se abastecido de informa��es e preparado para come�armos 
a estudar um pouco mais sobre como as Estat�sticas podem nos ajudar no retorno mais �gil de nossos 
dados. Para demonstrar vamos utilizar o C�digo 4.

C�digo 4 � Consultando dados armazenadas nas Tabelas Cidades e Vendas. */
-- Consultados os Dados Armazenados nas Tabelas Cidades e Vendas
SELECT		V.NumPedido 
FROM		Vendas V 
Inner Join	Cidades C On V.Codigo = C.Codigo
WHERE		C.Nome='S�o Roque'
OPTION (Recompile)

/*	Vamos analisar o Plano de Execu��o que foi inclu�do em nossa query e ver como esta a distribu���o 
de processamento realizado em cada operador, conforme a apresenta a Figura 1.

Figura 1 � Plano de Execu��o processado pelo SQL Server na execu��o do C�digo 4.

	Podemos notar que nosso Plano de Execu��o distribuiu a carga de processamento em cada operador 
inclusive o Nestel Loops, operador respons�vel em realizar a jun��o dos dados enviados por cada 
tabela. Este operador consumiu 21% de todo processamento realizado pelo SQL Server.*/

/* Ap�s executarmos o C�digo 4, poderemos observar que mesmo existindo somente 1 registro cadastrado 
que possui venda relacionada a cidade de S�o Roque, o Plano de Execu��o estimou o retorno de 500 
linhas, conforme apresenta a Figura 2, na propriedade Estimated Number of Rows.
 
Figura 2 � Propriedades do operador Nested Loops, ap�s a execu��o do C�digo 4.

Este comportamento nos indica que o Plano de Execu��o atualmente processado pelo SQL Server esta 
levando em considera��o uma por��o da massa de dados existente em nossa tabela Vendas, ao inv�s 
de tentar identificar qual realmente � a linha que possui o dados correto a ser apresentado.
Muito bem, � justamente para esta situa��o que podemos utilizar as Estat�sticas filtradas, o que 
nos possibilitar� realizar a execu��o da mesma query e trar� ao SQL Server a possibilidade de 
aplicar um filtro sobre esta por��o de dados, sem necessitarmos de qualquer tipo de altera��o 
em nossa consulta, �ndice ou tabela.

Para criar e aplicar a estat�stica filtrada, utilizaremos o C�digo 5, apresentado a seguir: */

-- Criando novas estat�sticas para as Tabela Cidades, utilizando as Estat�sticas Filtradas �
CREATE STATISTICS StsFiltrada_Cidades_SaoRoque ON Cidades(Codigo)
WHERE Nome = 'S�o Roque'
GO
CREATE STATISTICS StsFiltrada_Cidades_Mairinque ON Cidades(Codigo)
WHERE Nome = 'Mairinque'
GO

/*	Para ilustrar e entender como nosso ambiente esta definido, a Figura 3 apresentar a Tabela 
Cidades, seus �ndices e estat�sticas, vale destacar que as duas novas estat�sticas filtradas 
adicionadas e esta tabela aparecem na mesma guia �Statitics� em conjunto com todas as outras.
 
Figura 3 � Tabela Cidades, �ndices, Estat�sticas e Estat�sticas Filtradas.

Agora com as estas novas Estat�sticas criadas em nossa Tabela Cidades, vamos executar novamente o 
C�digo 4, e ver qual a diferen�a apresentada pelo Plano de Execu��o ao processar mais uma vez esta 
mesma consulta.*/

-- Consultados os Dados Armazenados nas Tabelas Cidades e Vendas
SELECT		V.NumPedido 
FROM		Vendas V 
Inner Join	Cidades C On V.Codigo = C.Codigo
WHERE		C.Nome='S�o Roque'
OPTION (Recompile)

/*	Vamos come�ar novamente analisando o Plano de Execu��o apresentado pelo SQL Server, ap�s a execu��o 
do C�digo 4, mas com as Estat�sticas Filtradas aplicadas para a Tabela Cidades, conforme 
apresenta a Figura 4.
 
Figura 4 � Novo Plano de Execu��o apresentado pelo SQL Server, ap�s executar o C�digo 4.

N�o vamos necessitar de muitas an�lises para evidenciar as primeiras diferen�as apresentadas 
neste novo Plano de Execu��o, o que nos importa � novamente observar o operador Nested Loops, 
que agora apresenta 0% de todo processamento utilizado pelo SQL Server. Com base neste valor, 
podemos entender que a carga de processamento utilizada na execu��o desta consulta foi dividida 
de uma forma mais inteligente entre os outros dois operadores Index Seek e Clustered Index Seek, 
onde cada um destes operadores consumiu 50% de processamento.
Estes valores nos indicam que o SQL Server conseguiu flexibilizar o processamento de nossa query, 
identificando e responsabilizando os operadores de busca e obten��o de dados em realizar todo 
processo de consulta das informa��es, passando de forma mais organizada para o operador Nested Loops, que simplesmente realizou a jun��o dos dados e enviou para o operador Select.
Com a mudan�a apresentada neste novo Plano de Execu��o, foi claro entender que o operador Nested 
Loops estava sendo utilizado de forma incorreta e consumindo recursos sem necessidade, 
principalmente na quantidade de linhas estimadas para o resultado que antes eram 500 e agora o valor 
correto � 1, a Figura 5 apresenta os novos valores aplicados ao operador Nested Loops.
 
Figura 5 � Propriedades do operador Nested Loops.

Ficou f�cil e simples observar atrav�s da Figura 5, que nossa query retornou a quantidade correta 
de linhas, analisando as propriedades Actual Number Rows e Estimated Number of Row, ambas est�o 
apresentando o mesmos valores, algo muito diferete do que foi apresentado anteriormente na Figura 3.
Vale ressaltar que a partir do momento que a quantidade de linhas estimadas para consulta e retorno,
os valores de Custo Estimado de CPU, Custo Estimado de I/O, Tamanho Estimado de Linhas e Custo de 
Processamento do Operador s�o bem menores, o que mais uma vez nos indica um ganho de performance e 
otimiza��o no processamento de nossa query.
Ap�s estes comparativos, chegamos ao final de nossa an�lise e podemos afirmar que conseguimos de uma forma bastante simples melhorar de forma sens�vel o processamento de nossa query, al�m disso, possibilitar ao SQL Server otimizar a gera��o do Plano de Execu��o utilizado para a mesma fazendo uso das Estat�sticas Filtradas.
Espero que voc� tenha gostado de mais este artigo, que as informa��es apresentas aqui sobre �ndices e Estat�sticas possam ser
�teis no seu trabalho e estudados.

Agrade�o a sua visita, at� o pr�ximo artigo.