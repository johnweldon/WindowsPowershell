
write-debug "LOAD Infrastructure"

function get-projectsfile { return (join-path (split-path $PROFILE) "projects.xml") }

function get-projects { 
	$private:p = [xml](gc (get-projectsfile)) 
	$private:usf = (gi 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders')
	
	$private:usf.GetValueNames() | %{
		$private:e = ($private:p).CreateElement("project");
		$null = $private:e.SetAttribute("name", $_);
		$null = $private:e.SetAttribute("folder", ( "'{0}'" -f $private:usf.GetValue($_)));
		$null = ($private:p.projects).AppendChild($private:e);
	}

	return $private:p
}

function expand-path {
	param($path = ".")
	$private:ppath = invoke-expression ("echo {0}" -f $path)
	if(-not(test-path $private:ppath)){
		write-error ("'{0}' does not exist" -f $private:ppath)
		$private:ppath = "."
	}
	return resolve-path $private:ppath
}

function show-projectstack {
	" - path stack - "
	"	 --> {0}" -f (get-location)
	$private:ix = 0;
	$private:stack = (get-location -Stack -StackName ProjectStack -ErrorAction SilentlyContinue)
	if($private:stack) {
		$private:stack.ToArray() | %{ 
			"   {1,5} {0}" -f $_.Path, $private:ix-- 
		}
	}
}

function goto-project {
	param($project = "help")

	$private:projects = get-projects
	$private:proj = $private:projects.SelectSingleNode(("descendant::project[@name='{0}']" -f $project))

	if(-not($private:proj)) {
		"invoke with one of the project names defined below:"
		list-projects
		"--------"
		""
		show-projectstack
		return
	}

	push-location -StackName ProjectStack (expand-path $private:proj.folder)
	show-projectstack

	if(-not $private:proj.script) { return }
	$private:pscript = invoke-expression ("echo {0}" -f $private:proj.script)
	if(-not $private:pscript) { return }
	invoke-expression "$private:pscript"
}

function edit-projects { gvim (get-projectsfile) }

function list-projects { 
	(get-projects).selectnodes("descendant::project") | %{ 
		$obj = new-object system.object
		$obj | add-member -type noteproperty -name Project -value $_.name
		$obj | add-member -type noteproperty -name Path -value (expand-path $_.folder)
		$obj
	}
}

function pop-project {
	pop-location -StackName ProjectStack -ErrorAction SilentlyContinue
	show-projectstack
}

set-alias -name "g:" -value "goto-project"
set-alias -name ":" -value "list-projects"
set-alias -name ":g" -value "goto-project"

set-alias -name "pp" -value "pop-project"
set-alias -name "pw" -value "show-projectstack"
set-alias -name "ge" -value "edit-projects"






write-debug "DONE loading infrastructure"
