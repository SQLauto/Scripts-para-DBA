-- select * from sys.databases
-- create database BDTeste
use BDTeste

/*	D�vida - Quest�o em concurso publico
	Trata-se de uma quest�o que foi utilizada em concursos publicos:
	Considere as tabelas R,S,T com 10, 30 e 50 registros respectivamente.
	O comando sql produz: Comando -> select sum(3) from r r1, r r2, s s1, t t1 

	Quantos registros ser�o produzidos? 
	A resposta � esta: Em virtude da aus�ncia de operadores JOIN e de jun��es na cl�usula WHERE
, normalmente ter�amos um produto cartesiano produzindo uma quantidade de registros resultado da 
multiplica��o dos registros de todas as tabelas o que inicialmente nos levaria a 15.000 registros. 
No entanto, como a fun��o SUM � uma fun��o de agrega��o e n�o h� nenhuma cl�usula GROUP BY, ser� 
produzido um �nico registro (possivelmente com o resultado igual a 45.000). 

	Exemplo desenvolvido no SQL Server 2005, para facilitar a compreens�o: */ 

--create table R (codigo int identity(1,1)) 
--create table S (codigo int identity(1,1)) 
--create table T (codigo int identity(1,1)) 

--insert into R default values
--go 10 

--insert into S default values 
--go 30 

--insert into T default values 
--go 50 

Select sum(3) as 'Qtd. Registros' from R r1, R r2, S s1, T t1