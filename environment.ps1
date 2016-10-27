write-debug "LOAD environment"
## LOAD VS variables
function set-env {
	param($command=$(throw "mandatory"),$arguments = "")
	write-debug ("set-env [{0}]" -f $command)
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
		write-debug (">>>>     {0}" -f $_)
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
		$vsargs = "x64"
	)
	$vsfolder = ($vsfolder -f $vsver)
	$vsparent = ($vsparent -f $vscpu)
	$vs = join-path (join-path $vsdrive $vsparent) $vsfolder
	$vc = join-path $vs "VC\vcvarsall.bat"
	write-debug ("what's this? {0}" -f $vc)
	if(test-path $vc) { 
		set-env -Command $vc -Arguments $vsargs 
		return $True
	}
	return $False
}

$script:foundvs = $False
function load-visualstudio {
	param($vsver = "9.0")
	if ($script:foundvs) { return }
	write-debug "load-visualstudio"
	if ($search_all_drives) {
		[System.IO.DriveInfo]::GetDrives() | ?{ $_.DriveType -eq "Fixed" } | %{
			$drive = $_.Name
			""," (x86)" | %{
				if (load-vcvars -vsver $vsver -vscpu $_ -vsdrive $drive) {
					$script:foundvs = $True
				}
			}
		}
	} else {
		""," (x86)" | %{ 
			if (load-vcvars -vsver $vsver -vscpu $_ -vsdrive "c:\") {
					$script:foundvs = $True
			}
		}
	}
}

function load-vs2015 { load-visualstudio -vsver "14.0" }
function load-vs2013 { load-visualstudio -vsver "12.0" }
function load-vs2012 { load-visualstudio -vsver "11.0" }
function load-vs2010 { load-visualstudio -vsver "10.0" }
function load-vs2008 { load-visualstudio -vsver "9.0" }

function load-platformsdk {
	write-debug "load-platformsdk"
	$found = $False
	if (-not $env:MSSdk) {
		@{cmd="C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.cmd";args="/xp /x64"},
		@{cmd="C:\Program Files\Microsoft SDKs\Windows\v7.0\Bin\SetEnv.cmd";args="/xp /x64"},
		@{cmd="C:\Program Files\Microsoft SDKs\Windows\v6.1\Bin\SetEnv.Cmd";args="/xp /x64"},
		@{cmd="C:\Program Files\Microsoft Platform SDK\SetEnv.Cmd";args="/xp /x64"},
		@{cmd="c:\default.cmd";args=""}|
		?{ -not $found -and (test-path $_.cmd)} | %{
			write-debug ("	set-env {0} {1}" -f $_.cmd, $_.args)
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
		if(-not ($private:p.ContainsValue($private:v)) -and (-not ($private:v -eq "")) -and (test-path $private:v)) {
			$private:p.Add($private:k++,$private:v)
		}
	}
	$env:Path = ""
	$private:p.Keys | sort | %{
		$env:Path += $private:p[$_] + ';'
	}
	$env:Path = $env:Path.Trim(';')
}

function clean-lib {
	$private:p = @{}
	$private:k = 0
	if($env:LIB) {
		$env:LIB.Split(';') | %{
			$private:v = $_.tolower()
			if(-not ($private:p.ContainsValue($private:v)) -and (-not ($private:v -eq "")) -and (test-path $private:v)) {
				$private:p.Add($private:k++,$private:v)
			}
		}
		$env:LIB = ""
		$private:p.Keys | sort | %{
			$env:LIB += $private:p[$_] + ';'
		}
		$env:LIB = $env:LIB.Trim(';')
	}
}

function get-versions {
	get-dotnetpaths | %{ split-path -leaf $_ }
}

function get-dotnetpaths {
	gcm msbuild | ?{$_.Definition.Contains($env:FrameworkDir.tolower())} | %{ split-path $_.Definition } 
}

function get-versionpath {
	param($version = "v4.0.30319")
	get-dotnetpaths | ?{ $_.contains($version)}
}

function set-version {
	param($version = "v4.0.30319")
	$env:path = ("{0};{1}" -f ([array](get-versionpath $version))[0],$env:path)
	clean-path
}

function load-env {
	write-debug "Load Visual Studio Env"
	if ($True -and -not $env:DevEnvDir) { 
		load-platformsdk
		load-vs2015 
		load-vs2013 
		load-vs2012 
		load-vs2010 
	}

	write-debug "Set .NET framework path"

	$private:root = join-path $env:SystemRoot "Microsoft.NET"
	if($True) {
		$found = $False
		"Framework64","Framework" | %{
			$private:cur = join-path $private:root $_
			"v4.0.30319","v3.5","v2.0.50727" | %{
				$private:dir = join-path $private:cur $_
				if(-not $found -and (test-path $private:dir)) {
					$env:PATH = ("{0};{1}" -f $private:dir,$env:PATH)
					$found = $True
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

	write-debug "Set MSBuild paths"
	$private:root = join-path ${env:ProgramFiles(x86)} "MSBuild"
	if($True) {
		$found = $False
		"14.0","12.0", "4.0" | %{
			$private:dir = join-path (join-path $private:root $_) "Bin"
			if(-not $found -and (test-path $private:dir)) {
				$env:PATH = ("{0};{1}" -f $private:dir,$env:PATH)
				$found = $True
			}
		}
	}

	write-debug "clean-lib"
	clean-lib
}

load-env
$env:Platform = "Any CPU"
write-debug "DONE loading environment"
