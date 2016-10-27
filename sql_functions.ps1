
write-debug "LOAD sql_functions"
##
#
# SQL Connections
#
##

function execute-sqlitequery {
	param(
		[string]$db = $(throw "specify db file"),
		[string]$query = $(throw "specify query")
	)
	if(-not(get-command -ErrorAction SilentlyContinue sqlite3.exe)) { throw "sqlite not found" } 
	return sqlite3.exe $db $query
}

set-alias sq3 execute-sqlitequery

function get-sqlconnection {
	param(
		$server = $(throw "specify server"), 
		$db = $(throw "specify db"),
		$user = $(throw "specify user"),
		$pass = $(throw "specify pass")
		)
	$connStr = "Server={0};User Id={1};Password={2};Database={3}" -f $server,$user,$pass,$db
	$connection = New-Object System.Data.SqlClient.SqlConnection($connStr)
	$connection.Open()
	return $connection
}

function execute-reader {
	param(
		[string]$query = $(throw "specify sql query"),
		$connection = (get-myconnection)
	)
	$command = $connection.CreateCommand()
	$command.CommandText = $query
	$rows = $command.ExecuteReader()
	$names = @()
	0..($rows.fieldcount - 1) | %{ $names += $rows.GetName($_) }
	while($rows.Read()) {
		$o = New-Object PSObject
		$names | %{ add-member -in $o -name $_ -memberType noteproperty -value $rows.getvalue($rows.getordinal($_)) }
		$o
	}
	$rows.Close()
	$command.Dispose()
	$connection.Close()
}

 
function execute-nonquery {
	param(
		[string]$query = $(throw "specify sql query"),
		$connection = (get-myconnection)
	)
	$command = $connection.CreateCommand()
	$command.CommandText = $query
	$rows = $command.ExecuteNonQuery()
	"affected rows: {0}" -f $rows
	$command.Dispose()
	$connection.Close()
}


function get-myconnection {
	$connStr = "Data Source=(local);Initial Catalog=master;Integrated Security=SSPI;"
	$connection = New-Object System.Data.SqlClient.SqlConnection($connStr)
	$connection.Open()
	return $connection
}

set-alias er execute-reader
set-alias en execute-nonquery

$env:DEFAULT_DB_SERVER = "(local)"
$env:DEFAULT_DB_DATABASE = "master"

function sqlcmd-query {
	param(
		$script = "SELECT 1",
		$database = $env:DEFAULT_DB_DATABASE,
		$server = $env:DEFAULT_DB_SERVER
	)
	if(gcm sqlcmd -ErrorAction SilentlyContinue) {
	if(test-path $script -ErrorAction SilentlyContinue) {
		sqlcmd -W -E -S $server -d $database -i $script
	} else {
		sqlcmd -W -E -S $server -d $database -Q $script
	}
	} else {
		write-warning "sqlcmd.exe not found"
	}
}

set-alias q sqlcmd-query


write-debug "DONE loading sql_functions"
