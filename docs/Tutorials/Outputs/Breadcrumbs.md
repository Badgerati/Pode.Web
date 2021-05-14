# Breadcrumbs

This page details the available output actions available to Breadcrumbs.

## Out

To create/update the breacrumbs that appear at the top of the page, you can use [`Out-PodeWebBreadcrumb`](../../../Functions/Outputs/Out-PodeWebBreadcrumb). This works in a similar fashion to [`Set-PodeWebBreadcrumb`](../../../Functions/Layouts/Set-PodeWebBreadcrumb), and also uses [`New-PodeWebBreadcrumbItem`](../../../Functions/Layouts/New-PodeWebBreadcrumbItem) as well:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebButton -Name 'Show Breadcrumbs' -ScriptBlock {
        Out-PodeWebBreadcrumb -Items @(
            New-PodeWebBreadcrumbItem -Name 'Main' -Url '/pages/PageName'
            New-PodeWebBreadcrumbItem -Name 'SubPage1' -Url '/pages/PageName?value=stuff1'
            New-PodeWebBreadcrumbItem -Name 'SubPage2' -Url '/pages/PageName?value=stuff2' -Active
        )
    }
)
```
