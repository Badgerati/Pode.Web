FROM badgerati/pode:2.8.0-arm32
LABEL maintainer="Matthew Kelly (Badgerati)"
RUN mkdir -p /usr/local/share/powershell/Modules/Pode.Web
COPY ./src/ /usr/local/share/powershell/Modules/Pode.Web