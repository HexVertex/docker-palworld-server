FROM steamcmd/steamcmd:latest

ENV USER=steam \
    APP_ID=2394010
RUN apt-get update && apt-get -y install curl && \
    useradd -ms /bin/bash steam && \
    mkdir /data                 && \
    chmod -R 777 /data          && \
    chmod -R 777 /root          && \
    mkdir -p /home/${USER}/.steam/sdk64/ && \
    steamcmd +login anonymous +app_update 1007 +quit && \
    cp ~/Steam/steamapps/common/Steamworks\ SDK\ Redist/linux64/steamclient.so /home/${USER}/.steam/sdk64/ && \
    chown -R ${USER}:${USER} /home/${USER}
USER steam
WORKDIR /home/steam
COPY --chown=steam:steam --chmod=755 ./*.sh .

USER root
ENTRYPOINT [ "/bin/sh", "entrypoint.sh" ]
CMD [ "./startup.sh" ]
VOLUME [ "/data" ]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "./healthcheck.sh" ]