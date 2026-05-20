# Azure

If you want to run Pode.Web in the Azure environment, your only option is to use Azure Container Apps.

## Azure Functions

Pode.Web is a stateful/interactive framework. Because it relies on a running server component and because startup performance is quite prohibitive, it cannot run in stateless mode in Azure Functions.

## Azure Container Apps

Using Azure Container Apps is very similar to using Docker to host Pode.Web. You can even automate the Docker Image build process within a github workflow so that you commit and an image is built and pushed to Azure ready to go. To get started, all you really need is a working dockerfile in your github repo. You can even have the build process pull extra modules from the PSGallery, like AzBobbyTables in this example:

```
# pull down the pode image
FROM badgerati/pode.web:latest

# or use the following for GitHub
# FROM docker.pkg.github.com/badgerati/pode.web/pode.web:latest

# copy over the local files to the container
COPY . /usr/src/app/

# expose the port
EXPOSE 80

# run the server
RUN pwsh -c "Install-Module AzBobbyTables -Force"
CMD [ "pwsh", "-c", "cd /usr/src/app; ./server.ps1" ]
```

Then you just need to create a deployment workflow from the Azure Container Apps Deployment Center. In Container Apps, you can do things like set ENV variables for your secrets.

But be warned, cold starts for PowerShell in Azure (even this Container App) are quite slow: around 30s. This solution with Azure Container Apps will need to either be always running or tolerant towards these cold starts.
