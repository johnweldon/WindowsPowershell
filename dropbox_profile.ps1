
$DebugPreference = "SilentlyContinue"

write-debug "LOAD profile"
#misc env vars
$env:EDITOR = "gvim -f"
$env:hosts = resolve-path "c:\windows\system32\drivers\etc\hosts"
$env:profile = (join-path $env:profile_dir "profile.ps1")
if(gcm -ErrorAction SilentlyContinue GetDropboxPath) {
	$env:dropboxpath = (getdropboxpath)
	$env:PATH += (";{0}" -f (join-path $env:dropboxpath "tcc"))
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

write-debug "clean-path"
clean-path
write-debug "DONE loading profile"
