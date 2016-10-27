## helper functions
write-debug "LOAD misc_functions"

function get-identity {
	return [Security.Principal.WindowsIdentity]::GetCurrent()
}

function is-admin {
	return ([Security.Principal.WindowsPrincipal] (get-identity)).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

# PROMPT
function prompt { 
	if(is-admin) {
		$Host.UI.RawUI.WindowTitle = [string]("(ADMIN) {0:yyyy-MM-dd HH:mm:ss} -- {1}" -f (get-date),(pwd).Path);
		"# "
	} else {
		$Host.UI.RawUI.WindowTitle = [string]("{0:yyyy-MM-dd HH:mm:ss} -- {1}" -f (get-date),(pwd).Path);
		"$ "
	}
}

function elevate-shell {
	start-process -verb runas powershell
}

set-alias -name "less" -value "more"

set-alias -name "w" -value "get-identity"
set-alias -name "whoami" -value "get-identity"

function timed-history { 
	"{0,15} {1,-15} {2}" -f "Id", "Seconds", "Command"
	"{0,15} {1,-15} {2}" -f "--", "-------", "-------"
	Get-History | %{ "{0,15}  {1,-15} {2}" -f $_.Id, ($_.EndExecutionTime - $_.StartExecutionTime).TotalSeconds, $_.CommandLine } 
} 
set-alias -name "hi" -value "timed-history"

function lsa { param($path="."); Get-ChildItem -Force $path }
set-alias -name "la" -value "lsa"
set-alias -name "ll" -value "lsa"
function lsd { param($path="."); lsa $path | ? { $_.PSIsContainer } }
function lsf { param($path="."); lsa $path | ? { !$_.PSIsContainer } }
function lat { param($path="."); lsa $path | sort -property lastwritetime -descending }
function latr { param($path="."); lsa $path | sort -property lastwritetime }
function fi { param($pat,$root="."); gci -r $root | ? {$_.Name -match $pat} | % { $_.FullName } }

function get-uptime { return "{0}" -f [TimeSpan]::FromMilliseconds([Environment]::TickCount); }

function do-recursively {param($root=".",$cmd={lsf},$test={$True;});pushd $root;if(&$test){&$cmd};lsd|%{&$myinvocation.mycommand.scriptblock -root $_.FullName -cmd $cmd -test $test};popd;}

function find-hosts { param($ip="127.0.0.1",$name); show-hosts | ?{$l=$_.Split(",");$ip -eq $l[0] -and $name -eq $l[1]}}
function show-hosts { gc $env:hosts | ?{$_ -match "^[^#]"} | format-hosts }

function browse-url { param($url="http://www.google.com"); (new-object -com shell.application).ShellExecute($url); }
set-alias -name "browse" -value "browse-url"
function launch-explorer {
	param($url = "about:blank")
	(new-object -com shell.application).ShellExecute("iexplore.exe", $url)
}

#set-alias -name "ckml" -value "CheckMail.exe"
function checkmail { clear }

set-alias -name "ckml" -value "checkmail"

function zip-command { &'7za.exe' $Args }
set-alias -name "zip" -value "zip-command"

set-alias -name "connect" -value (join-path (split-path $PROFILE) "Connect-Computer.ps1")

function shell-execute { param($fn); [Diagnostics.Process]::Start($fn) }
set-alias -name "se" -value "shell-execute"

## .NET functions
function show-assemblies { [appdomain]::currentdomain.getassemblies() }
function load-assembly { param($ass = "System.Web"); return [system.reflection.assembly]::loadwithpartialname($ass) }
function load-web { return load-assembly }

set-alias ngen @(
	gci ((join-path ${env:\windir} "Microsoft.NET\Framework") + "\*\*") ngen.exe | 
	sort -descending lastwritetime
	)[0].fullName

## UI / Console functions
function small-buffer {
	$winsize = $host.UI.RawUI.WindowSize
	$bufsize = new-object System.Management.Automation.Host.Size
	$bufsize.Width = $winsize.Width
	$bufsize.Height = 3000 #$winsize.Height
	$host.UI.RawUI.BufferSize = $bufsize
}

function large-buffer {
	$winsize = $host.UI.RawUI.WindowSize
	$bufsize = new-object System.Management.Automation.Host.Size
	$bufsize.Width = 1000
	$bufsize.Height = 3000
	$host.UI.RawUI.BufferSize = $bufsize
}

function find-junctions { junction.exe -q -s | ? {$_.endswith(": JUNCTION")} | %{ $_.replace(": JUNCTION","") }}
function remove-junctions { find-junctions | %{ junction.exe -d $_ }}

function show-path { return $env:Path.Split(';'); }

function get-bytes { param($file = $(throw "specify file name")); return [byte[]](gc $file -encoding byte) }
function set-bytes { param($file = $(throw "specify file name"),[byte[]]$bytes); $bytes | sc $file -encoding byte }

# courtesy of :  http://winterdom.com/2009/09/formatting-byte-arrays-in-powershell
function byteToChar { param([byte]$b = 0); if($b -lt 32 -or $b -gt 127){return '.'}else{return [char]$b}}
function format-bytes {
	param([byte[]]$bytes, [int]$bytesPerLine = 8)
	$buffer = new-object system.text.stringbuilder
	for($offset=0; $offset -lt $bytes.Length; $offset+= $bytesPerLine) {
		[void]$buffer.AppendFormat('{0:X8}	', $offset)
		$numbytes = [math]::min($bytesPerLine, $bytes.Length - $offset)
		for ($i=0; $i -lt $numbytes; $i++) { [void]$buffer.AppendFormat('{0:X2} ', $bytes[$offset + $i]) }
		[void]$buffer.AppendFormat(' ' * ((($bytesPerLine - $numBytes) * 3) + 3))
		for ($i=0; $i -lt $numbytes; $i++) { [void]$buffer.Append((byteToChar $bytes[$offset + $i])) }
		[void]$buffer.Append([environment]::newline)
	}
	$buffer.tostring()
}

function convert-tobase64 { param([string]$s); [convert]::tobase64string([system.text.encoding]::utf8.getbytes($s)); }
function convert-frombase64 { param([string]$s); [system.text.encoding]::utf8.getstring([convert]::frombase64string($s)); }

set-alias -name "log" -value "openlogfile.exe"
 
function list-dates {
	param(
		[datetime]$begin = $([datetime]::today.adddays(-7)),
		[datetime]$end = $([datetime]::today)
		)
	for($i=$begin; $i -le $end; $i = $i.AddDays(1)) {
		("{0:yyyy-MM-dd}" -f $i)
	}

}

function open-logs {
	gvim ( list-dates | %{ $_ + ".log" } | ?{ test-path $_ } )
}

function mstsc-fullscreen {
	param($host_name = $env:DEFAULT_RDP_HOST)
	mstsc /v:$host_name /f 
}

function mstsc-fullscreenmulti {
	param($host_name = $env:DEFAULT_RDP_HOST)
	mstsc /v:$host_name /f /multimon
}

set-alias -name "rdpf" -value "mstsc-fullscreen"
set-alias -name "rdp" -value "mstsc-fullscreenmulti"

write-debug "DONE loading misc_functions"
