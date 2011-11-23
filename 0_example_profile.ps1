
$gdp = "GetDropboxPath.exe"
if(get-command $gdp -ErrorAction SilentlyContinue) {
	$gdpp = (&$gdp)
	$ppth = (Join-Path $gdpp "WindowsPowershell/dropbox_profile.ps1")
	$bpth = (Join-Path $gdpp "bin")

	if(test-path $bpth) {
		$env:PATH += ";"+$bpth
	} else {
		write-warning ("Path '{0}' doesn't exist" -f $bpth)
	}
	if(test-path $ppth) {
		write-host "Loading..."
		$env:profile_dir = split-path $ppth
		. $ppth
	} else {
		write-warning ("Path '{0}' doesn't exist" -f $ppth)
	}
} else {
	write-warning "GetDropboxPath not found"
}
