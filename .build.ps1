
$dest_path = './src/Templates/Public'
$src_path = './pode_modules'

task Build {
    yarn install --force --ignore-scripts --modules-folder pode_modules
}, MoveLibs

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
    Copy-Item -Path "$($src_path)/chart.js/dist/Chart.min.js" -Destination "$($libs_path)/chartjs/" -Force
    Copy-Item -Path "$($src_path)/chart.js/dist/Chart.min.css" -Destination "$($libs_path)/chartjs/" -Force

    # feather icons
    New-Item -Path "$($libs_path)/feather-icons" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/feather-icons/dist/feather.min.js*" -Destination "$($libs_path)/feather-icons/" -Force

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
    New-Item -Path "$($libs_path)/monaco/editor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/monaco/basic-languages" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/monaco/base/worker" -ItemType Directory -Force | Out-Null

    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/loader.js" -Destination "$($libs_path)/monaco/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/editor/*.*" -Destination "$($libs_path)/monaco/editor/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/base/worker/*.*" -Destination "$($libs_path)/monaco/base/worker/" -Force

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

    $vs_maps_path = "$($dest_path)/min-maps/vs"
    Remove-Item -Path $vs_maps_path -Recurse -Force | Out-Null
    New-Item -Path "$($vs_maps_path)/editor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($vs_maps_path)/base/worker" -ItemType Directory -Force | Out-Null

    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/loader.js.map" -Destination $vs_maps_path -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/editor/*.*" -Destination "$($vs_maps_path)/editor/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/base/worker/*.*" -Destination "$($vs_maps_path)/base/worker/" -Force
}
