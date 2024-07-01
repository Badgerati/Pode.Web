param(
    [string]
    $ReleaseNoteVersion,

    [switch]
    $SkipDockerPack
)

$dest_path = './src/Templates/Public'
$src_path = './pode_modules'


<#
# Dependency Versions
#>

$Versions = @{
    MkDocs      = '1.6.0'
    MkDocsTheme = '9.5.23'
    Mike        = '2.1.1'
    PlatyPS     = '0.14.2'
}

<#
# Helper Functions
#>

function Test-PodeBuildIsWindows {
    $v = $PSVersionTable
    return ($v.Platform -ilike '*win*' -or ($null -eq $v.Platform -and $v.PSEdition -ieq 'desktop'))
}

function Test-PodeBuildCommand($cmd) {
    $path = $null

    if (Test-PodeBuildIsWindows) {
        $path = (Get-Command $cmd -ErrorAction Ignore)
    }
    else {
        $path = (which $cmd)
    }

    return (![string]::IsNullOrWhiteSpace($path))
}

function Invoke-PodeBuildInstall($name, $version) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (Test-PodeBuildIsWindows) {
        if (Test-PodeBuildCommand 'choco') {
            choco install $name --version $version -y
        }
    }
    else {
        if (Test-PodeBuildCommand 'brew') {
            brew install $name
        }
        elseif (Test-PodeBuildCommand 'apt-get') {
            sudo apt-get install $name -y
        }
        elseif (Test-PodeBuildCommand 'yum') {
            sudo yum install $name -y
        }
    }
}

function Install-PodeBuildModule($name) {
    if ($null -ne ((Get-Module -ListAvailable $name) | Where-Object { $_.Version -ieq $Versions[$name] })) {
        return
    }

    Write-Host "Installing $($name) v$($Versions[$name])"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name "$($name)" -Scope CurrentUser -RequiredVersion "$($Versions[$name])" -Force -SkipPublisherCheck
}

function Get-PodeBuildVersion {
    return (Import-PowerShellDataFile -Path './src/Pode.Web.psd1').ModuleVersion
}

function Get-PodeBuildCurrentBranch {
    $branch = git branch --show-current
    if ([string]::IsNullOrWhiteSpace($branch)) {
        $branch = git rev-parse --abbrev-ref HEAD
    }

    return $branch
}

function Test-PodeBuildDevBranch {
    $branch = Get-PodeBuildCurrentBranch
    return ($branch -ieq 'develop')
}

function Test-PodeBuildLiveBranch {
    $branch = Get-PodeBuildCurrentBranch
    return ($branch -ieq 'master')
}


<#
# Dependencies
#>

# Synopsis: Installs Chocolatey
task ChocoDeps -If (Test-PodeBuildIsWindows) {
    if (!(Test-PodeBuildCommand 'choco')) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

# Synopsis: Install dependencies for documentation
task DocsDeps ChocoDeps, {
    # install mkdocs
    if (!(Test-PodeBuildCommand 'mkdocs')) {
        Invoke-PodeBuildInstall 'mkdocs' $Versions.MkDocs
    }

    # install mkdocs-material theme
    $_installed = (pip list --format json --disable-pip-version-check | ConvertFrom-Json)
    if (($_installed | Where-Object { $_.name -ieq 'mkdocs-material' -and $_.version -ieq $Versions.MkDocsTheme } | Measure-Object).Count -eq 0) {
        pip install "mkdocs-material==$($Versions.MkDocsTheme)" --force-reinstall --disable-pip-version-check
    }

    # install mike
    if (($_installed | Where-Object { $_.name -ieq 'mike' -and $_.version -ieq $Versions.Mike } | Measure-Object).Count -eq 0) {
        pip install "mike==$($Versions.Mike)" --force-reinstall --disable-pip-version-check
    }

    # install platyps
    Install-PodeBuildModule PlatyPS
}


<#
# Building
#>

# Synopsis: Install the frontend libraries
task Build {
    yarn install --force --ignore-scripts --modules-folder pode_modules
}, MoveLibs

# Synopsis: Move the libraries to the public directory
task MoveLibs {
    $libs_path = "$($dest_path)/libs"
    if (Test-Path $libs_path) {
        Remove-Item -Path $libs_path -Recurse -Force | Out-Null
    }

    New-Item -Path $libs_path -ItemType Directory -Force | Out-Null

    # jquery
    New-Item -Path "$($libs_path)/jquery" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/jquery/dist/jquery.min.js" -Destination "$($libs_path)/jquery/" -Force
    Copy-Item -Path "$($src_path)/jquery/LICENSE.txt" -Destination "$($libs_path)/jquery/" -Force

    # jquery-ui
    New-Item -Path "$($libs_path)/jquery-ui" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/jquery-ui-dist/jquery-ui.min.js" -Destination "$($libs_path)/jquery-ui/" -Force
    Copy-Item -Path "$($src_path)/jquery-ui-dist/jquery-ui.min.css" -Destination "$($libs_path)/jquery-ui/" -Force
    Copy-Item -Path "$($src_path)/jquery-ui-dist/LICENSE.txt" -Destination "$($libs_path)/jquery-ui/" -Force

    # popper.js
    New-Item -Path "$($libs_path)/popperjs" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@popperjs/core/dist/umd/popper.min.js" -Destination "$($libs_path)/popperjs/" -Force
    Copy-Item -Path "$($src_path)/@popperjs/core/dist/umd/popper.min.js.map" -Destination "$($libs_path)/popperjs/" -Force
    Copy-Item -Path "$($src_path)/@popperjs/core/LICENSE.md" -Destination "$($libs_path)/popperjs/" -Force

    # bootstrap
    New-Item -Path "$($libs_path)/bootstrap" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/bootstrap/dist/js/bootstrap.bundle.min.js*" -Destination "$($libs_path)/bootstrap/" -Force
    Copy-Item -Path "$($src_path)/bootstrap/dist/css/bootstrap.min.css*" -Destination "$($libs_path)/bootstrap/" -Force
    Copy-Item -Path "$($src_path)/bootstrap/LICENSE" -Destination "$($libs_path)/bootstrap/" -Force

    # bs-stepper
    New-Item -Path "$($libs_path)/bs-stepper" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/bs-stepper/dist/js/bs-stepper.min.js*" -Destination "$($libs_path)/bs-stepper/" -Force
    Copy-Item -Path "$($src_path)/bs-stepper/dist/css/bs-stepper.min.css*" -Destination "$($libs_path)/bs-stepper/" -Force
    Copy-Item -Path "$($src_path)/bs-stepper/LICENSE" -Destination "$($libs_path)/bs-stepper/" -Force

    # moment
    New-Item -Path "$($libs_path)/moment" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/moment/min/moment.min.js*" -Destination "$($libs_path)/moment/" -Force
    Copy-Item -Path "$($src_path)/moment/LICENSE" -Destination "$($libs_path)/moment/" -Force

    # chart.js
    New-Item -Path "$($libs_path)/chartjs" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/chart.js/dist/chart.umd.js*" -Destination "$($libs_path)/chartjs/" -Force
    Copy-Item -Path "$($src_path)/chart.js/LICENSE.md" -Destination "$($libs_path)/chartjs/" -Force

    # kurkle (used by chart.js)
    New-Item -Path "$($libs_path)/kurkle" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@kurkle/color/dist/color.min.js*" -Destination "$($libs_path)/kurkle/" -Force
    Copy-Item -Path "$($src_path)/@kurkle/color/LICENSE.md" -Destination "$($libs_path)/kurkle/" -Force

    # mdi fonts - icons
    New-Item -Path "$($libs_path)/mdi-font/css" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@mdi/font/css/materialdesignicons.min.css*" -Destination "$($libs_path)/mdi-font/css/" -Force
    Copy-Item -Path "$($src_path)/@mdi/font/css/materialdesignicons.css.map" -Destination "$($libs_path)/mdi-font/css/" -Force
    Copy-Item -Path "$($src_path)/@mdi/font/LICENSE" -Destination "$($libs_path)/mdi-font/css/" -Force

    New-Item -Path "$($libs_path)/mdi-font/fonts" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@mdi/font/fonts/materialdesignicons-webfont*" -Destination "$($libs_path)/mdi-font/fonts/" -Force

    # highlight.js
    New-Item -Path "$($libs_path)/highlightjs" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@highlightjs/cdn-assets/highlight.min.js" -Destination "$($libs_path)/highlightjs/" -Force
    Copy-Item -Path "$($src_path)/@highlightjs/cdn-assets/LICENSE" -Destination "$($libs_path)/highlightjs/" -Force

    New-Item -Path "$($libs_path)/highlightjs/languages" -ItemType Directory -Force | Out-Null

    $langs = @(
        'bash',
        'c',
        'cpp',
        'csharp',
        'css',
        'dockerfile',
        'fsharp',
        'go',
        'http',
        'java',
        'javascript',
        'json',
        'markdown'
        'php',
        'powershell',
        'puppet',
        'python',
        'ruby',
        'sql',
        'typescript',
        'xml',
        'yaml'
    )
    $langs | ForEach-Object {
        Copy-Item -Path "$($src_path)/@highlightjs/cdn-assets/languages/$($_).min.js" -Destination "$($libs_path)/highlightjs/languages/" -Force
    }

    New-Item -Path "$($libs_path)/highlightjs/styles" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@highlightjs/cdn-assets/styles/a11y-dark.min.css" -Destination "$($libs_path)/highlightjs/styles/" -Force
    Copy-Item -Path "$($src_path)/@highlightjs/cdn-assets/styles/a11y-light.min.css" -Destination "$($libs_path)/highlightjs/styles/" -Force

    # monaco
    New-Item -Path "$($libs_path)/monaco" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/vs" -ItemType Directory -Force | Out-Null

    New-Item -Path "$($libs_path)/monaco/editor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/monaco/basic-languages" -ItemType Directory -Force | Out-Null

    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/loader.js" -Destination "$($libs_path)/monaco/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/editor/*.*" -Destination "$($libs_path)/monaco/editor/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/LICENSE" -Destination "$($libs_path)/monaco/editor/" -Force

    New-Item -Path "$($libs_path)/monaco/base/worker" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/base/worker/*.*" -Destination "$($libs_path)/monaco/base/worker/" -Force

    New-Item -Path "$($libs_path)/monaco/base/browser/ui/codicons/codicon" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/base/browser/ui/codicons/codicon/*.*" -Destination "$($libs_path)/monaco/base/browser/ui/codicons/codicon/" -Force

    $langs = @(
        'bat',
        'cpp',
        'csharp',
        'css',
        'dockerfile',
        'fsharp',
        'go',
        'html',
        'java',
        'javascript',
        'markdown',
        'mysql',
        'php',
        'powershell',
        'python',
        'ruby',
        'sql',
        'typescript',
        'xml',
        'yaml'
    )

    (Get-ChildItem -Path "$($src_path)/monaco-editor/min/vs/basic-languages" -Directory).Name | ForEach-Object {
        if ($_ -iin $langs) {
            New-Item -Path "$($libs_path)/monaco/basic-languages/$($_)/" -ItemType Directory -Force | Out-Null
            Copy-Item -Path "$($src_path)/monaco-editor/min/vs/basic-languages/$($_)/*.*" -Destination "$($libs_path)/monaco/basic-languages/$($_)/" -Force
        }
    }

    New-Item -Path "$($libs_path)/monaco/language" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/vs/language" -ItemType Directory -Force | Out-Null

    (Get-ChildItem -Path "$($src_path)/monaco-editor/min/vs/language" -Directory).Name | ForEach-Object {
        New-Item -Path "$($libs_path)/monaco/language/$($_)/" -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$($src_path)/monaco-editor/min/vs/language/$($_)/*.*" -Destination "$($libs_path)/monaco/language/$($_)/" -Force

        New-Item -Path "$($libs_path)/vs/language/$($_)/" -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$($src_path)/monaco-editor/min/vs/language/$($_)/*.*" -Destination "$($libs_path)/vs/language/$($_)/" -Force
    }

    New-Item -Path "$($libs_path)/vs/base/common/worker" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/base/common/worker/simpleWorker.nls.js" -Destination "$($libs_path)/vs/base/common/worker/" -Force

    $vs_maps_path = "$($dest_path)/min-maps/vs"
    if (Test-Path $vs_maps_path) {
        Remove-Item -Path $vs_maps_path -Recurse -Force | Out-Null
    }

    New-Item -Path "$($vs_maps_path)/editor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($vs_maps_path)/base/worker" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($vs_maps_path)/base/common/worker" -ItemType Directory -Force | Out-Null

    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/loader.js.map" -Destination $vs_maps_path -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/editor/*.*" -Destination "$($vs_maps_path)/editor/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/base/worker/*.*" -Destination "$($vs_maps_path)/base/worker/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/base/common/worker/simpleWorker.nls.js*" -Destination "$($vs_maps_path)/base/common/worker/" -Force
}


<#
# Pack
#>

# Synopsis: Package up the Module
task Pack -If (Test-PodeBuildIsWindows) Build, PowershellPack, DockerPack

# Synopsis: Package up the Module
task PowershellPack {
    $Name = 'Pode.Web'
    Copy-Item './src' "./$($Name)" -Recurse -Force
}

# Synopsis: Create docker tags
task DockerPack {
    if ($SkipDockerPack) {
        Write-Host 'Skipping docker pack...' -ForegroundColor Yellow
        return
    }

    $version = Get-PodeBuildVersion

    docker build -t badgerati/pode.web:$version -f ./Dockerfile .
    docker build -t badgerati/pode.web:latest -f ./Dockerfile .
    docker build -t badgerati/pode.web:$version-alpine -f ./alpine.dockerfile .
    docker build -t badgerati/pode.web:latest-alpine -f ./alpine.dockerfile .
    docker build -t badgerati/pode.web:$version-arm32 -f ./arm32.dockerfile .
    docker build -t badgerati/pode.web:latest-arm32 -f ./arm32.dockerfile .

    docker tag badgerati/pode.web:latest docker.pkg.github.com/badgerati/pode.web/pode.web:latest
    docker tag badgerati/pode.web:$version docker.pkg.github.com/badgerati/pode.web/pode.web:$version
    docker tag badgerati/pode.web:latest-alpine docker.pkg.github.com/badgerati/pode.web/pode.web:latest-alpine
    docker tag badgerati/pode.web:$version-alpine docker.pkg.github.com/badgerati/pode.web/pode.web:$version-alpine
    docker tag badgerati/pode.web:latest-arm32 docker.pkg.github.com/badgerati/pode.web/pode.web:latest-arm32
    docker tag badgerati/pode.web:$version-arm32 docker.pkg.github.com/badgerati/pode.web/pode.web:$version-arm32
}


<#
# Docs
#>

# Synopsis: Build and run the documentation locally
task Docs DocsDeps, DocsHelpBuild, {
    Write-Host 'Documentation available at 127:0.0.1:8000...' -ForegroundColor Yellow
    mkdocs serve --quiet --open
}

# Synopsis: Build the function help documentation
task DocsHelpBuild DocsDeps, {
    # import the local module
    Remove-Module Pode.Web -Force -ErrorAction Ignore | Out-Null
    Import-Module ./src/Pode.Web.psm1 -Force | Out-Null

    # build the function docs
    $path = './docs/Functions'
    $map = @{}

    Remove-Item -Path $path -Recurse -Force -ErrorAction Ignore | Out-Null
    New-Item -Path $path -ItemType Directory -Force | Out-Null

    (Get-Module Pode.Web).ExportedFunctions.Keys | ForEach-Object {
        $type = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path -Leaf -Path (Get-Command $_ -Module Pode.Web).ScriptBlock.File))
        New-MarkdownHelp -Command $_ -OutputFolder (Join-Path $path $type) -Force -Metadata @{ PodeType = $type } -AlphabeticParamsOrder | Out-Null
        $map[$_] = $type
    }

    # update docs to bind links to unlinked functions
    $path = Join-Path $pwd 'docs'
    Get-ChildItem -Path $path -Recurse -Filter '*.md' | ForEach-Object {
        $depth = ($_.FullName.Replace($path, [string]::Empty).trim('\/') -split '[\\/]').Length
        $updated = $false

        $content = (Get-Content -Path $_.FullName | ForEach-Object {
                $line = $_

                while ($line -imatch '\[`(?<name>[a-z]+\-podeweb[a-z]+)`\](?<char>([^(]|$))') {
                    $updated = $true
                    $name = $Matches['name']
                    $char = $Matches['char']
                    $line = ($line -ireplace "\[``$($name)``\]([^(]|$)", "[``$($name)``]($('../' * $depth)Functions/$($map[$name])/$($name))$($char)")
                }

                $line
            })

        if ($updated) {
            $content | Out-File -FilePath $_.FullName -Force -Encoding ascii
        }
    }

    # remove the module
    Remove-Module Pode.Web -Force -ErrorAction Ignore | Out-Null
}

# Synopsis: Deploy the documentation
task DocsDeploy DocsDeps, DocsHelpBuild, {
    $version = Get-PodeBuildVersion

    if (!(Test-PodeBuildDevBranch) -and !(Test-PodeBuildLiveBranch)) {
        Write-Host 'Skipping documentation deploy for non-master/dev branch...' -ForegroundColor Yellow
        return
    }

    $alias = 'latest'
    if (Test-PodeBuildDevBranch) {
        $alias = 'dev'
    }

    git fetch origin gh-pages --depth=1
    mike deploy --push --update-aliases $version $alias
}

# Synopsis: Build the Release Notes
task ReleaseNotes {
    if ([string]::IsNullOrWhiteSpace($ReleaseNoteVersion)) {
        Write-Host 'Please provide a ReleaseNoteVersion' -ForegroundColor Red
        return
    }

    # get the PRs for the ReleaseNoteVersion
    $prs = gh search prs --milestone $ReleaseNoteVersion --repo badgerati/pode.web --merged --limit 200 --json 'number,title,labels,author' | ConvertFrom-Json

    # group PRs into categories, filtering out some internal PRs
    $categories = [ordered]@{
        Features      = @()
        Enhancements  = @()
        Bugs          = @()
        Documentation = @()
    }

    $dependabot = @{}

    foreach ($pr in $prs) {
        if ($pr.labels.name -icontains 'superseded') {
            continue
        }

        $label = ($pr.labels[0].name -split ' ')[0]
        if ($label -iin @('new-release', 'internal-code')) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($label)) {
            $label = 'misc'
        }

        switch ($label.ToLowerInvariant()) {
            'feature' { $label = 'Features' }
            'enhancement' { $label = 'Enhancements' }
            'bug' { $label = 'Bugs' }
        }

        if (!$categories.Contains($label)) {
            $categories[$label] = @()
        }

        if ($pr.author.login -ilike '*dependabot*') {
            if ($pr.title -imatch 'Bump (?<name>\S+) from (?<from>[0-9\.]+) to (?<to>[0-9\.]+)') {
                if (!$dependabot.ContainsKey($Matches['name'])) {
                    $dependabot[$Matches['name']] = @{
                        Name   = $Matches['name']
                        Number = $pr.number
                        From   = [version]$Matches['from']
                        To     = [version]$Matches['to']
                    }
                }
                else {
                    $item = $dependabot[$Matches['name']]
                    if ([int]$pr.number -gt [int]$item.Number) {
                        $item.Number = $pr.number
                    }
                    if ([version]$Matches['from'] -lt $item.From) {
                        $item.From = [version]$Matches['from']
                    }
                    if ([version]$Matches['to'] -gt $item.To) {
                        $item.To = [version]$Matches['to']
                    }
                }

                continue
            }
        }

        $titles = @($pr.title)
        if ($pr.title.Contains(';')) {
            $titles = ($pr.title -split ';').Trim()
        }

        $author = $null
        if (($pr.author.login -ine 'badgerati') -and ($pr.author.login -inotlike '*dependabot*')) {
            $author = $pr.author.login
        }

        foreach ($title in $titles) {
            $str = "* #$($pr.number): $($title)"
            if (![string]::IsNullOrWhiteSpace($author)) {
                $str += " (thanks @$($author)!)"
            }

            if ($str -imatch '\s+(docs|documentation)\s+') {
                $categories['Documentation'] += $str
            }
            else {
                $categories[$label] += $str
            }
        }
    }

    # add dependabot aggregated PRs
    if ($dependabot.Count -gt 0) {
        $label = 'dependencies'
        if (!$categories.Contains($label)) {
            $categories[$label] = @()
        }

        foreach ($dep in $dependabot.Values) {
            $categories[$label] += "* #$($dep.Number): Bump $($dep.Name) from $($dep.From) to $($dep.To)"
        }
    }

    # output the release notes
    Write-Host "# v$($ReleaseNoteVersion)`n"

    $culture = (Get-Culture).TextInfo
    foreach ($category in $categories.Keys) {
        if ($categories[$category].Length -eq 0) {
            continue
        }

        Write-Host "### $($culture.ToTitleCase($category))"
        $categories[$category] | Sort-Object | ForEach-Object { Write-Host $_ }
        Write-Host ''
    }
}