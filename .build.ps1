
$dest_path = './src/Templates/Public'
$src_path = './pode_modules'

task Build {
    yarn install --force --ignore-scripts --modules-folder pode_modules
    Remove-Item -Path $dest_path -Recurse -Force | Out-Null
    New-Item -Path $dest_path -ItemType Directory -Force | Out-Null
}, MoveLibs

task MoveLibs {
    $libs_path = "$($dest_path)/libs"
    New-Item -Path $libs_path -ItemType Directory -Force | Out-Null

    # jquery
    Copy-Item -Path "$($src_path)/jquery/dist/jquery.min.js" -Destination $libs_path -Force

    # popper.js
    Copy-Item -Path "$($src_path)/popper.js/dist/umd/popper.min.js" -Destination $libs_path -Force
    Copy-Item -Path "$($src_path)/popper.js/dist/umd/popper.min.js.map" -Destination $libs_path -Force

    # bootstrap
    Copy-Item -Path "$($src_path)/bootstrap/dist/js/bootstrap.bundle.min.js" -Destination $libs_path -Force
    Copy-Item -Path "$($src_path)/bootstrap/dist/js/bootstrap.bundle.min.js.map" -Destination $libs_path -Force

    # bs-stepper
    Copy-Item -Path "$($src_path)/bs-stepper/dist/js/bs-stepper.min.js" -Destination $libs_path -Force
    Copy-Item -Path "$($src_path)/bs-stepper/dist/js/bs-stepper.min.js.map" -Destination $libs_path -Force

    # monaco
    New-Item -Path "$($libs_path)/monaco" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/monaco/editor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/monaco/basic-languages" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($libs_path)/monaco/base/worker" -ItemType Directory -Force | Out-Null

    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/loader.js" -Destination "$($libs_path)/monaco/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/editor/*.*" -Destination "$($libs_path)/monaco/editor/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min/vs/base/worker/*.*" -Destination "$($libs_path)/monaco/base/worker/" -Force

    (Get-ChildItem -Path "$($src_path)/monaco-editor/min/vs/basic-languages" -Directory).Name | ForEach-Object {
        New-Item -Path "$($libs_path)/monaco/basic-languages/$($_)/" -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$($src_path)/monaco-editor/min/vs/basic-languages/$($_)/*.*" -Destination "$($libs_path)/monaco/basic-languages/$($_)/" -Force
    }

    $vs_maps_path = "$($dest_path)/min-maps/vs"
    New-Item -Path "$($vs_maps_path)/editor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$($vs_maps_path)/base/worker" -ItemType Directory -Force | Out-Null

    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/loader.js.map" -Destination $vs_maps_path -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/editor/*.*" -Destination "$($vs_maps_path)/editor/" -Force
    Copy-Item -Path "$($src_path)/monaco-editor/min-maps/vs/base/worker/*.*" -Destination "$($vs_maps_path)/base/worker/" -Force
}
