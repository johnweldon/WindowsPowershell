
copy function:\TabExpansion function:\DefaultTabExpansion
function TabExpansion {
	param([string]$line, [string]$lastword)
	if($line.tolower().trim().startswith("g:") -or $line.tolower().trim().startswith(":")) {
		$script:pr = @(list-projects)
		foreach ($script:v in $script:pr) {
			if(-not($lastword.endswith(":g ")) -or -not($lastword.endswith(": "))) {
				if($script:v.Project.tolower().startswith($lastword.tolower())) { $script:v.Project }
			} else {
				$script:v.Project
			}
		}
	} else {
	$res = @(DefaultTabExpansion $line $lastword)
		foreach ($r in $res){ $r }
	}
}
