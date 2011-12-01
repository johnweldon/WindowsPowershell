write-debug "LOAD sourcecontrol_functions"
## svn functions
filter strip-status { $_.Substring(1).Trim(); }
function svn-status { param($status=".",$root="."); svn.exe status $root | ?{$_ -match ("^{0}" -f $status)} | strip-status }
function svn-conflicted { param($root="."); svn-status -status C -root $root }
function svn-modified { param($root="."); svn-status -status M -root $root }
function svn-versioned { param($root="."); svn-status -status "[^\?]" -root $root }
function svn-unversioned { param($root="."); svn-status -status "\?" -root $root }
function svn-info { [string]::join(" :: ", ( svn info | ?{$_.StartsWith("Revision") -or $_.StartsWith("Last")})) }
function svn-ignores { param($path="."); svn st --no-ignore | ?{ $_.StartsWith("I") } | %{ $_.Trim("I").Trim() } }
function svn-unknown { param($path="."); svn st | ?{ $_.StartsWith("?") } | %{ $_.Trim("?").Trim() } }
function wrap-svn { param($output); return [xml]($output | %{$_.Replace("wc-status","wc_status").Replace("item","itm")}); }
## tsvn functions
set-alias -name "tsvn" -value "C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe"
function tsvn-base { param($path=".",$command="log"); tsvn /command:$command /path:"$path" /notempfile /closeonend $Args }
function tsvn-add { param($path="."); tsvn-base -path $path -command "add" }
function tsvn-blame { param($path="."); tsvn-base -path $path -command "blame" /startrev:1 /endrev:-1 }
function tsvn-browse { param($path="."); tsvn-base -path $path -command "repobrowser" }
function tsvn-cleanup { param($path="."); tsvn-base -path $path -command "cleanup" }
function tsvn-commit { param($path="."); tsvn-base -path $path -command "commit" }
function tsvn-compare { param($path="."); tsvn-base -path $path -command "diff" }
function tsvn-conflict { param($path="."); tsvn-base -path $path -command "conflicteditor"; }
function tsvn-delete { param($path="."); tsvn-base -path $path -command "remove" }
function tsvn-help { param($path="."); tsvn-base -path $path -command "help" }
function tsvn-log { param($path="."); tsvn-base -path $path -command "log" }
function tsvn-merge { param($path="."); tsvn-base -path $path -command "merge"; }
function tsvn-patch { param($path="."); tsvn-base -path $path -command "createpatch"; }
function tsvn-properties { param($path="."); tsvn-base -path $path -command "properties"; }
function tsvn-resolve { param($path="."); tsvn-base -path $path -command "resolve"; }
function tsvn-revert { param($path="."); tsvn-base -path $path -command "revert" }
function tsvn-settings { param($path="."); tsvn-base -path $path -command "settings"; }
function tsvn-status { param($path="."); tsvn-base -path $path -command "repostatus"; }
function tsvn-update { param($path="."); tsvn-base -path $path -command "update" }
function tsvn-updateall { param($path=".");$paths = (get-childitem -fo -r -inc .svn $path|%{"`"{0}`"" -f $_.FullName}); write-host $paths; write-host $paths.Count ; tsvn-update ([string]::Join('*',$paths));}
## hg functions
function hg-clean { ls -r -inc *.rej,*.orig | rm }
function hg-edit { gvim (ls -r -inc *.rej) }
function hg-ignores { param($path="."); $local:root = (hg root); hg st -i -n | %{ join-path $local:root $_}}
function hg-unknown { param($path="."); $local:root = (hg root); hg st -u -n | %{ join-path $local:root $_}}
function hg-adds { 
	hg-unknown | ?{ -not (hg-iscruft $_) } 
	hg-ignores | ?{ -not (hg-iscruft $_) }
}
function hg-iscruft { 
	param($path);
	$local:p = $path.tolower();
	"\bin\","\obj\","resharper","\sandbox\","\documents\","\music\","\favorites\","\downloads\","\links\","\videos\" | %{ if($local:p.contains($_)){return $true} }
	".log",".txt",".xml",".suo",".user",".bin",".dat",".dll",".exe",".pdb",".exe.config",".dll.config" | %{ if($local:p.endswith($_)){return $true} }
	return $false
}

## git functions
function get-gitbinpath {
    $private:gp = (gcm git -ErrorAction SilentlyContinue)
    if($private:gp) {
        $private:pth = split-path (split-path $private:gp.Definition)
        return join-path $private:pth "bin"
    }
    return $null
}

function kill-sshagent {
	ps ssh-agent -ErrorAction SilentlyContinue | stop-process
	start-sleep 2
}

function start-sshagent {
	if($env:SSH_AGENT_PID) { echo "ssh-agent running"; return }
    $private:gp = get-gitbinpath
    if($private:gp) {
        $private:out = & (join-path $private:gp "ssh-agent")
        $private:out | ?{$_.contains("=")} | %{
            $private:cur = $_.split(";")[0]
            $private:pair = $private:cur.split("=")
            $private:cmd = ('$env:{0}="{1}"' -f $private:pair)
            invoke-expression $private:cmd
        }
        write-warning "Use exit to leave shell"
        register-engineevent powershell.exiting -action {
        	ps -Id $env:SSH_AGENT_PID -ErrorAction SilentlyContinue | stop-process
        } | out-null
    }
}

function addkey-sshagent {
	if($env:SSH_AGENT_PID) {
        $private:gp = get-gitbinpath
        if($private:gp) {
        	& (join-path $private:gp "ssh-add") (join-path $env:USERPROFILE "/.ssh/id_rsa")
        }
    }
}


write-debug "DONE loading sourcecontrol_functions"
