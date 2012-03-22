
copy function:\TabExpansion function:\DefaultTabExpansion
function TabExpansion {
	param([string]$line, [string]$lastword)
	if($line.tolower().trim().startswith("g:") -or $line.tolower().trim().startswith(":")) {
		$script:pr = @(list-projects)
		foreach ($script:v in $script:pr) {
		    $script:q = $script:v.Project
		    if($script:q.contains(" ")) { $script:q = ("'{0}'" -f $script:q) }
			if(-not($lastword.endswith(":g ")) -or -not($lastword.endswith(": "))) {
				if($script:v.Project.tolower().startswith($lastword.tolower())) { $script:q }
			} else {
				$script:q
			}
		}
	} else {
	$res = @(DefaultTabExpansion $line $lastword)
		foreach ($r in $res){ $r }
	}
}
