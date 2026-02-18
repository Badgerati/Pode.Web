# Credential

This page details the actions available to Credential Textboxes.

## Update

To update the username and/or password values of a Credential on the page, you can use [`Update-PodeWebCredential`](../../../Functions/Actions/Update-PodeWebCredential). The `-UsernameValue` and `-PasswordValue` parameters should be a string:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCredential -Name 'Credentials'

    New-PodeWebButton -Name 'Update' -ScriptBlock {
        Update-PodeWebCredential -Name 'Credentials' -UsernameValue 'new_username' -Password 'new_password'
    }
)
```

You can omit the `-UsernameValue`/`-PasswordValue` and update other properties of the Credential, such as `-ReadOnly`, etc.

!!! note
    You can clear a Credential by supplying an empty string to either `-UsernameValue` or `-PasswordValue`.

Various other properties can be updated as well.

## Clear

You can clear the content of a Credential by using [`Clear-PodeWebCredential`](../../../Functions/Actions/Clear-PodeWebCredential), and both the username and password fields will be cleared:

```powershell
New-PodeWebContainer -NoBackground -Content @(
    New-PodeWebCredential -Name 'Credentials'

    New-PodeWebButton -Name 'Clear' -ScriptBlock {
        Clear-PodeWebCredential -Name 'Credentials'
    }
)
```
