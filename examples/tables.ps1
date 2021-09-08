Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Web.psm1 -Force

Start-PodeServer -Threads 2 {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of templates, and set a login page
    Use-PodeWebTemplates -Title 'Tables' -Theme Dark

    # set the home page controls
    $card1 = New-PodeWebTable `
        -Name 'Empty Table' `
        -ScriptBlock {} `
        -AsCard `
        -Columns @(
            Initialize-PodeWebTableColumn -Key 'Name'
            Initialize-PodeWebTableColumn -Key 'ID'
            Initialize-PodeWebTableColumn -Key 'WorkingSet' -Name 'Memory'
            Initialize-PodeWebTableColumn -Key 'CPU'
        )

    Set-PodeWebHomePage -Layouts $card1 -Title 'Tables'
}