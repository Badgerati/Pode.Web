
$dest_path = './src/Templates/Public'
$src_path = './pode_modules'


<#
# Dependency Versions
#>

$Versions = @{
    MkDocs = '1.1.2'
    MkDocsTheme = '7.1.6'
    PlatyPS = '0.14.0'
}

<#
# Helper Functions
#>

function Test-PodeBuildIsWindows
{
    $v = $PSVersionTable
    return ($v.Platform -ilike '*win*' -or ($null -eq $v.Platform -and $v.PSEdition -ieq 'desktop'))
}

function Test-PodeBuildCommand($cmd)
{
    $path = $null

    if (Test-PodeBuildIsWindows) {
        $path = (Get-Command $cmd -ErrorAction Ignore)
    }
    else {
        $path = (which $cmd)
    }

    return (![string]::IsNullOrWhiteSpace($path))
}

function Invoke-PodeBuildInstall($name, $version)
{
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

function Install-PodeBuildModule($name)
{
    if ($null -ne ((Get-Module -ListAvailable $name) | Where-Object { $_.Version -ieq $Versions[$name] })) {
        return
    }

    Write-Host "Installing $($name) v$($Versions[$name])"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name "$($name)" -Scope CurrentUser -RequiredVersion "$($Versions[$name])" -Force -SkipPublisherCheck
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

    $_installed = (pip list --format json --disable-pip-version-check | ConvertFrom-Json)
    if (($_installed | Where-Object { $_.name -ieq 'mkdocs-material' -and $_.version -ieq $Versions.MkDocsTheme } | Measure-Object).Count -eq 0) {
        pip install "mkdocs-material==$($Versions.MkDocsTheme)" --force-reinstall --disable-pip-version-check
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

    # jquery-ui
    New-Item -Path "$($libs_path)/jquery-ui" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/jquery-ui-dist/jquery-ui.min.js" -Destination "$($libs_path)/jquery-ui/" -Force
    Copy-Item -Path "$($src_path)/jquery-ui-dist/jquery-ui.min.css" -Destination "$($libs_path)/jquery-ui/" -Force

    # popper.js
    New-Item -Path "$($libs_path)/popperjs" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/popper.js/dist/umd/popper.min.js" -Destination "$($libs_path)/popperjs/" -Force
    Copy-Item -Path "$($src_path)/popper.js/dist/umd/popper.min.js.map" -Destination "$($libs_path)/popperjs/" -Force

    # bootstrap
    New-Item -Path "$($libs_path)/bootstrap" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/bootstrap/dist/js/bootstrap.bundle.min.js*" -Destination "$($libs_path)/bootstrap/" -Force
    Copy-Item -Path "$($src_path)/bootstrap/dist/css/bootstrap.min.css*" -Destination "$($libs_path)/bootstrap/" -Force

    # bs-stepper
    New-Item -Path "$($libs_path)/bs-stepper" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/bs-stepper/dist/js/bs-stepper.min.js*" -Destination "$($libs_path)/bs-stepper/" -Force
    Copy-Item -Path "$($src_path)/bs-stepper/dist/css/bs-stepper.min.css*" -Destination "$($libs_path)/bs-stepper/" -Force

    # moment
    New-Item -Path "$($libs_path)/moment" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/moment/min/moment.min.js*" -Destination "$($libs_path)/moment/" -Force

    # chart.js
    New-Item -Path "$($libs_path)/chartjs" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/chart.js/dist/chart.min.js" -Destination "$($libs_path)/chartjs/" -Force

    # mdi fonts - icons
    New-Item -Path "$($libs_path)/mdi-font/css" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@mdi/font/css/materialdesignicons.min.css*" -Destination "$($libs_path)/mdi-font/css/" -Force
    Copy-Item -Path "$($src_path)/@mdi/font/css/materialdesignicons.css.map" -Destination "$($libs_path)/mdi-font/css/" -Force

    New-Item -Path "$($libs_path)/mdi-font/fonts" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@mdi/font/fonts/materialdesignicons-webfont*" -Destination "$($libs_path)/mdi-font/fonts/" -Force

    # highlight.js
    New-Item -Path "$($libs_path)/highlightjs" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/@highlightjs/cdn-assets/highlight.min.js" -Destination "$($libs_path)/highlightjs/" -Force

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
    Copy-Item -Path "$($src_path)/@highlightjs/cdn-assets/styles/tomorrow-night-blue.min.css" -Destination "$($libs_path)/highlightjs/styles/" -Force
    Copy-Item -Path "$($src_path)/@highlightjs/cdn-assets/styles/default.min.css" -Destination "$($libs_path)/highlightjs/styles/" -Force

    # monaco
    New-Item -Path "$($libs_path)/monaco" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/vs" -ItemType Directory -Force | Out-Null

    New-Item -Path "$($libs_path)/monaco/editor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/monaco/basic-languages" -ItemType Directory -Force | Out-Null

    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/loader.js" -Destination "$($libs_path)/monaco/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/editor/*.*" -Destination "$($libs_path)/monaco/editor/" -Force

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

    $vs_maps_path = "$($dest_path)/min-maps/vs"
    if (Test-Path $vs_maps_path) {
        Remove-Item -Path $vs_maps_path -Recurse -Force | Out-Null
    }

    New-Item -Path "$($vs_maps_path)/editor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($vs_maps_path)/base/worker" -ItemType Directory -Force | Out-Null

    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/loader.js.map" -Destination $vs_maps_path -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/editor/*.*" -Destination "$($vs_maps_path)/editor/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/base/worker/*.*" -Destination "$($vs_maps_path)/base/worker/" -Force
}


<#
# Docs
#>

# Synopsis: Run the documentation locally
task Docs DocsDeps, DocsHelpBuild, {
    mkdocs serve
}

# Synopsis: Build the function help documentation
task DocsHelpBuild DocsDeps, {
    # import the local module
    Remove-Module Pode.Web -Force -ErrorAction Ignore | Out-Null
    Import-Module ./src/Pode.Web.psm1 -Force | Out-Null

    # build the function docs
    $path = './docs/Functions'
    $map =@{}

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

            while ($line -imatch '\[`(?<name>[a-z]+\-podeweb[a-z]+)`\](?<char>[^(])') {
                $updated = $true
                $name = $Matches['name']
                $char = $Matches['char']
                $line = ($line -ireplace "\[``$($name)``\][^(]", "[``$($name)``]($('../' * $depth)Functions/$($map[$name])/$($name))$($char)")
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

# Synopsis: Build the documentation
task DocsBuild DocsDeps, DocsHelpBuild, {
    mkdocs build
}
