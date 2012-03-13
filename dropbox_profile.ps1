
$DebugPreference = "SilentlyContinue"

write-debug "LOAD profile"
#misc env vars
$env:EDITOR = "gvim.exe"
$env:hosts = resolve-path "c:\windows\system32\drivers\etc\hosts"
$env:profile = (join-path $env:profile_dir "profile.ps1")
$env:HOST = $env:COMPUTERNAME

if(gcm -ErrorAction SilentlyContinue GetDropboxPath) {
	$env:dropboxpath = (getdropboxpath)
    # tcc
	$env:PATH += (";{0}" -f (join-path $env:dropboxpath "tcc"))
    # GO
	$env:GOROOT = (join-path (join-path $env:dropboxpath "gowin386_release.r60.3") "go")
	$env:GOBIN = (join-path $env:GOROOT "bin")
	$env:GOARCH = "386"
	$env:PATH += (";{0}" -f $env:GOBIN)
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
