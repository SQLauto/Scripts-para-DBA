#
# Parando o servi�o do SQL Server
#
Get-Service | Where-Object {$_.Name -like "MSSQLSERVER"} | Stop-Service -Force

"Servico do SQL Server parado!"

#
# Iniciando o servi�o do SQL Server (retirar comentario)
#
#####Get-Service | Where-Object {$_.Name -like "MSSQLSERVER"} | Start-Service
#
#####"Servico do SQL Server inciado!" 