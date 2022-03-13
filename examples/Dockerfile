FROM badgerati/pode.web:test
COPY . /usr/src/app/
EXPOSE 8090
CMD [ "pwsh", "-c", "cd /usr/src/app; ./full.ps1" ]
