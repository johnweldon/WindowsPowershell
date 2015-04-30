
$DebugPreference = "SilentlyContinue"

write-debug "LOAD profile"
#misc env vars
$env:EDITOR = "gvim.exe"
$env:hosts = resolve-path "c:\windows\system32\drivers\etc\hosts"
$env:profile = (join-path $env:profile_dir "profile.ps1")
$env:HOST = $env:COMPUTERNAME
#$env:TERM = "msys" # http://stackoverflow.com/a/10820885/102371

if(-not($env:dropboxpath) -and (gcm -ErrorAction SilentlyContinue GetDropboxPath)) {
    $env:dropboxpath = (getdropboxpath)
}


## source the following list of files
$sources = 
	"environment.ps1",
	"infrastructure.ps1",
	"misc_functions.ps1",
	"msbuild_functions.ps1",
	"sql_functions.ps1",
	"logfiles_functions.ps1",
	"network_functions.ps1",
	"sourcecontrol_functions.ps1",
	"tabexpansion.ps1"

$sources | %{ join-path $env:profile_dir $_ } | ?{ test-path $_ } | %{ write-debug "loading $_";  . $_ }
rm variable:\sources

$env:PATH += ";" + (join-path $env:dropboxpath "bin\tcc")


function rdp-yzma { mstsc /v:"yzma.jw4.us:23389" /f /multimon }
function rdp-rack { mstsc /v:"portal.valuevision.com" /f /multimon }
set-alias -name rpy -value rdp-yzma
set-alias -name rpr -value rdp-rack

write-debug "clean-path"
clean-path
set-location ~
write-debug "DONE loading profile"
