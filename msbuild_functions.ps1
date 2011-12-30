write-debug "LOAD msbuild_functions"
## MSBuild stuff
function show-targets { param($proj = (resolve-path *.proj)); ([xml](gc $proj)).Project.Target | %{$_.Name} }
function msbuild-custom {
	param(
		[string]$proj = (resolve-path *.proj),
		[string]$targ = "Build",
		[string]$prop = "Configuration=Debug"
	)
	msbuild /nologo $proj /t:$targ /p:$prop /v:n /m:2 /fl /flp:"LogFile=buildlog.log;Verbosity=normal;Encoding=UTF-8" 
}

write-debug "DONE loading msbuild_functions"
