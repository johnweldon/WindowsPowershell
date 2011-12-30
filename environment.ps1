write-debug "LOAD environment"
## LOAD VS variables
function set-env {
	param($command=$(throw "mandatory"),$arguments = "")
	$private:tfile = [System.IO.Path]::GetTempFileName()
	$private:cmdline = "/v:on /c @`"{0}`" {1} && set > `"{2}`" && type `"{2}`"" -f $command,$arguments,$private:tfile
	write-debug $private:cmdline
	$private:pinfo = new-object System.Diagnostics.ProcessStartInfo("cmd", $private:cmdline)
	$private:pinfo.CreateNoWindow = $True
	$private:pinfo.LoadUserProfile = $False
	$private:pinfo.UseShellExecute = $True
	$private:pinfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
	$private:pinfo.WorkingDirectory = $env:TEMP
	$private:proc = [System.Diagnostics.Process]::Start($private:pinfo)
	$private:proc.WaitForExit()
	gc $private:tfile | %{
		write-debug (">>>>       {0}" -f $_)
		$private:pair = $_.Split("=");
		if ($private:pair.Length -eq 2) {
			set-item -path ("env:{0}" -f $private:pair[0]) -value ("{0}" -f $private:pair[1])
		}
	}
	write-debug "processed $command"
	[System.IO.File]::Delete($private:tfile)
}

##
#
# Visual Studio / SDK
#
##
## LOAD VS variables
function load-vcvars {
	param(
		$vsver = "8",
		$vscpu = "",
		$vsfolder = "Microsoft Visual Studio {0}", 
		$vsparent = "Program Files{0}",
		$vsdrive = "C:\",
		$vsargs = "x86"
	)
	$vsfolder = ($vsfolder -f $vsver)
	$vsparent = ($vsparent -f $vscpu)
	$vs = join-path (join-path $vsdrive $vsparent) $vsfolder
	$vc = join-path $vs "VC\vcvarsall.bat"
	if(test-path $vc) { set-env -Command $vc -Arguments $vsargs }
}

function load-visualstudio {
	param($vsver = "9.0")
	write-debug "load-visualstudio"
	[System.IO.DriveInfo]::GetDrives() | ?{ $_.DriveType -eq "Fixed" } | %{
		$drive = $_.Name
		""," (x86)" | %{ load-vcvars -vsver $vsver -vscpu $_ -vsdrive $drive }
	}
}

function load-vs2010 { load-visualstudio -vsver "10.0" }
function load-vs2008 { load-visualstudio -vsver "9.0" }

function load-platformsdk {
	write-debug "load-platformsdk"
	$found = $False
	if (-not $env:MSSdk) {
		@{cmd="C:\Program Files\Microsoft SDKs\Windows\v7.0\Bin\SetEnv.cmd";args="/xp /x86"},
		@{cmd="C:\Program Files\Microsoft SDKs\Windows\v6.1\Bin\SetEnv.Cmd";args="/xp /x86"},
		@{cmd="C:\Program Files\Microsoft Platform SDK\SetEnv.Cmd";args="/xp /x86"},
		@{cmd="c:\default.cmd";args=""}|
		?{ -not $found -and (test-path $_.cmd)} | %{
			write-debug ("    set-env {0} {1}" -f $_.cmd, $_.args)
			set-env -Command $_.cmd -Arguments $_.args -ea SilentlyContinue ; $found = $?
			write-debug($env:Path)
			$Error.clear()
		}
	}
}

function clean-path {
	$private:p = @{}
	$private:k = 0
	$env:Path.Split(';') | %{
		$private:v = $_.tolower()
		if(-not ($private:p.ContainsValue($private:v)) -and (test-path $private:v)) {
			$private:p.Add($private:k++,$private:v)
		}
	}
	$env:Path = ""
	$private:p.Keys | sort | %{
		$env:Path += $private:p[$_] + ';'
	}
	$env:Path = $env:Path.Trim(';')
}

function get-versions {
	get-dotnetpaths | %{ split-path -leaf $_ }
}

function get-dotnetpaths {
	gcm msbuild | ?{$_.Definition.Contains($env:FrameworkDir.tolower())} | %{ split-path $_.Definition } 
}

function get-versionpath {
	param($version = "v3.5")
	get-dotnetpaths | ?{ $_.contains($version)}
}

function set-version {
	param($version = "v3.5")
	$env:path = ("{0};{1}" -f ([array](get-versionpath $version))[0],$env:path)
	clean-path
}

function load-env {

	write-debug "Load Visual Studio Env"
	if ($True -and -not $env:DevEnvDir) { 
		load-platformsdk
		load-vs2008 
		load-vs2010 
	}

	write-debug "Set .NET framework path"

	$private:root = join-path $env:SystemRoot "Microsoft.NET"
	if($True) {
		"Framework64","Framework" | %{
			$private:cur = join-path $private:root $_
			"v2.0.50727","v3.5","v4.0.30319" | %{
				$private:dir = join-path $private:cur $_
				if(test-path $private:dir) {
					$env:PATH = ("{0};{1}" -f $private:dir,$env:PATH)
				}
			}
		}
	}

	write-debug "Set FrameworkDir env var"

	if ($True -and -not $env:FrameworkDir) {
		$private:csc = (get-command -totalcount 1 csc)
		if($private:csc) {
			$env:FrameworkPath = split-path $private:csc.path
			$env:FrameworkDir = split-path $env:FrameworkPath
			$env:FrameworkVersion = split-path -leaf $env:FrameworkPath
		}
	}

	write-debug "Set tempfiles"

	## Other useful variables
	if($env:FrameworkDir -and $env:FrameworkVersion) {
		$env:tempfiles = (join-path (join-path $env:FrameworkDir $env:FrameworkVersion) "Temporary ASP.NET Files")
	}
}

load-env
write-debug "DONE loading environment"
