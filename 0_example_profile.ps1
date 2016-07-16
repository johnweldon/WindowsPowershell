if ($env:vsconsoleoutput) { return }

$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

if (-not(test-path env:\GOPATH))        { $env:GOPATH = (resolve-path "C:\build\go") }
if (-not(test-path env:\DROPBOXPATH))   { $env:DROPBOXPATH = (resolve-path "C:\build\dropbox\Dropbox") }

$env:PATH += ";" + (resolve-path (join-path $env:GOPATH "bin"))
$env:PATH += ";" + (get-item "Env:ProgramFiles(x86)").Value + "\Git\bin"

$script:fs = get-psprovider filesystem
$script:fs.Home = $env:USERPROFILE

$script:ppth = (resolve-path (join-path $env:DROPBOXPATH "WindowsPowershell/dropbox_profile.ps1"))
$script:bpth = (resolve-path (join-path $env:DROPBOXPATH "bin"))
$script:mpth = (resolve-path (join-path $env:DROPBOXPATH "WindowsPowershell/Modules"))

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
if(test-path $script:mpth) {
    $env:PSModulePath += ';'+$script:mpth
} else {
    write-warning ("Path '{0}' doesn't exist" -f $script:mpth)
}



function global:prompt { 
    $realLASTEXITCODE = $LASTEXITCODE
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor
    write-host($pwd.ProviderPath) -nonewline -foreground "green"
    write-vcsstatus

    $Host.UI.RawUI.WindowTitle = [string]("{0:yyyy-MM-dd HH:mm:ss} -- {1}" -f (get-date),(pwd).Path);
    $local:p = " $ "
    if(is-admin) {
        $Host.UI.RawUI.WindowTitle = [string]("(ADMIN) {0:yyyy-MM-dd HH:mm:ss} -- {1}" -f (get-date),(pwd).Path);
        write-host " #" -nonewline -foreground "red"
    } else {
        write-host " $" -nonewline -foreground "green"
    }
    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}

Import-Module PsGet
Import-Module PsUrl
Import-Module posh-git
