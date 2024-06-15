FROM badgerati/pode:2.10.1-alpine
LABEL maintainer="Matthew Kelly (Badgerati)"
RUN mkdir -p /usr/local/share/powershell/Modules/Pode.Web
COPY ./src/ /usr/local/share/powershell/Modules/Pode.Web