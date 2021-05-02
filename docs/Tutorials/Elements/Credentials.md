# Credentials

The Credentials element is a form input element, and can be added using [`New-PodeWebCredential`](../../../Functions/Elements/New-PodeWebCredential). This will automatically add a username and password input fields to your form:

```powershell
New-PodeWebCard -Content @(
    New-PodeWebForm -Name 'Example' -ScriptBlock {
        $username = $WebEvent.Data['Creds_Username']
        $password = $WebEvent.Data['Creds_Password']
    } -Content @(
        New-PodeWebCredential -Name 'Creds'
    )
)
```

Which looks like below:

![credentials](../../../images/credentials.png)
