$script:gdp = "GetDropboxPath.exe"
if(get-command $script:gdp -ErrorAction SilentlyContinue) {
    $env:DROPBOXPATH = (&$script:gdp)

    # TODO: Uncomment if HOME doesn't co-incide with ~
    # $script:fs = get-psprovider filesystem
    # $script:fs.Home = $env:HOME

    $script:ppth = (Join-Path $env:DROPBOXPATH "WindowsPowershell/dropbox_profile.ps1")
    $script:bpth = (Join-Path $env:DROPBOXPATH "bin")

    if(test-path $script:bpth) {
        $env:PATH += ";" + $script:bpth
    } else {
        write-warning ("Path '{0}' doesn't exist" -f $script:bpth)
    }
    if(test-path $script:ppth) {
        write-host "Loading..."
        $env:profile_dir = split-path $script:ppth
        . $script:ppth
    } else {
        write-warning ("Path '{0}' doesn't exist" -f $script:ppth)
    }
} else {
	write-warning "GetDropboxPath not found"
}
