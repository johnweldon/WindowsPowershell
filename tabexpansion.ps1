
copy function:\TabExpansion function:\DefaultTabExpansion

function optionally-quote {
    param($script:str)
    if($script:str.contains(" ") -or $script:str.startswith("{") -or [char]::isdigit($script:str.substring(0,1))) {
        $script:str = ("'{0}'" -f $script:str);
    }
    return $script:str;
}

function TabExpansion {
	param([string]$line, [string]$lastword)
	if($line.tolower().trim().startswith("g:") -or $line.tolower().trim().startswith(":")) {
		$script:pr = @(list-projects)
		foreach ($script:v in $script:pr) {
		    $script:q = $script:v.Project
		    if($script:q.contains(" ")) { $script:q = ("'{0}'" -f $script:q) }
			if(-not($lastword.endswith(":g ")) -or -not($lastword.endswith(": "))) {
				if($script:v.Project.tolower().startswith($lastword.tolower())) { (optionally-quote $script:v.Project) }
			} else {
				(optionally-quote $script:v.Project)
			}
		}
	} else {
	$res = @(DefaultTabExpansion $line $lastword)
		foreach ($r in $res){ $r }
	}
}
