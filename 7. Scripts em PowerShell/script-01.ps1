#
# Dispara JObs.
# No exemplo dispara JObs que come�am por "Backup"
#
# Servidor: OTISRUSH
# Instancia: DEFAULT
#
cls

DIR SQLSERVER:\SQL\OTISRUSH\DEFAULT\JobServer\Jobs\Backup* | % {$_.Start()}

"Executou os Jobs"