# Docker

Pode.Web has a Docker image that you can use to host your server, for instructions on pulling these images you can [look here](../../Getting-Started/Installation).

The images use Pode v2.10.1 on either an Ubuntu Focal (default), Alpine, or ARM32 image.

## Images

!!! info
    The server script used below can be found in the [`examples/full.ps1`](https://github.com/Badgerati/Pode.Web/blob/develop/examples/full.ps1) directory in the repo.

### Default

The default Pode.Web image is an Ubuntu Focal image with Pode v2.10.1 and Pode.Web installed. An example of using this image in your Dockerfile could be as follows:

```dockerfile
# pull down the pode image
FROM badgerati/pode.web:latest

# or use the following for GitHub
# FROM docker.pkg.github.com/badgerati/pode.web/pode.web:latest

# copy over the local files to the container
COPY . /usr/src/app/

# expose the port
EXPOSE 8090

# run the server
CMD [ "pwsh", "-c", "cd /usr/src/app; ./full.ps1" ]
```

### Alpine

Pode.Web also has an image for Alpine, an example of using this image in your Dockerfile could be as follows:

```dockerfile
# pull down the pode image
FROM badgerati/pode.web:latest-alpine

# or use the following for GitHub
# FROM docker.pkg.github.com/badgerati/pode.web/pode.web:latest-alpine

# copy over the local files to the container
COPY . /usr/src/app/

# expose the port
EXPOSE 8090

# run the server
CMD [ "pwsh", "-c", "cd /usr/src/app; ./full.ps1" ]
```

### ARM32

Pode.Web also has an image for ARM32, meaning you can run Pode.Web on Raspberry Pis. An example of using this image in your Dockerfile could be as follows:

```dockerfile
# pull down the pode image
FROM badgerati/pode.web:latest-arm32

# or use the following for GitHub
# FROM docker.pkg.github.com/badgerati/pode.web/pode.web:latest-arm32

# copy over the local files to the container
COPY . /usr/src/app/

# expose the port
EXPOSE 8090

# run the server
CMD [ "pwsh", "-c", "cd /usr/src/app; ./full.ps1" ]
```

## Build and Run

To build and run the above Dockerfiles, you can use the following commands:

```bash
docker build -t pode.web/example .
docker run -p 8090:8090 -d pode.web/example
```

Now try navigating to `http://localhost:8090` (or calling `curl http://localhost:8090`) and you should be greeted with a Pode.Web home page.

!!! warning
    The ARM32 images will likely only work on Raspberry Pis, or an Operating System that supports ARM.
