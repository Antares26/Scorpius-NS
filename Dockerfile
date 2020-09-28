# WITH NS 3.2.1
# FROM debian:buster

# WITH NS 3.2.2
FROM debian:stretch

ARG NS_URL='https://github.com/ENSL/NS/releases/download/v3.2.2/ns_v322_full.zip'
ARG REHLDS_URL='https://github.com/dreamstalker/rehlds/releases/download/3.7.0.698/rehlds-dist-3.7.0.698-dev.zip'

RUN sed -ri 's/^deb\s+(.+)\smain.*/deb \1 main contrib non-free/gm' /etc/apt/sources.list
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get -y install \
    wget \
    lib32gcc1 \
    lib32stdc++6 \
    libstdc++6:i386 \
    # WITH NS 3.2.1
    # libcurl3-gnutls:i386
    # WITH NS 3.2.2
    libcurl3:i386 \
    gcc-multilib \
    g++-multilib \
    unzip \
    liblz4-tool \
    # Fro env subst
    gettext-base && \
    # Install steam
    printf "\n2\n" |apt-get install -y steamcmd && \
    rm -rf /var/lib/apt/lists/*
    
RUN useradd -m -s /bin/bash steam

USER steam
RUN mkdir -p /home/steam/hlds/steamapps/
WORKDIR /home/steam/hlds
# Run app validate several times workaround HLDS bug
RUN /usr/games/steamcmd +login anonymous +force_install_dir /home/steam/hlds +app_set_config 90 mod valve +app_update 90 validate +app_update 90 +quit ||true


# HLDS bug workaround
COPY --chown=steam:steam files/*.acf /home/steam/hlds/steamapps/

# HLDS bug workaround
RUN printf "quit\nquit\n"|/usr/games/steamcmd +login anonymous +force_install_dir /home/steam/hlds +app_set_config 90 mod valve +app_update 90 validate ||true && \
    printf "quit\nquit\n"|/usr/games/steamcmd +login anonymous +force_install_dir /home/steam/hlds +app_set_config 90 mod valve +app_update 90 validate ||true && \
    printf "quit\nquit\nquit\nquit\nquit\n" |/usr/games/steamcmd +login anonymous +force_install_dir /home/steam/hlds +app_set_config 90 mod valve +app_update 90 validate ||true

# HLDS bug workaround
RUN mkdir -p ~/.steam/sdk32 && ln -s ~/.steam/steamcmd/linux32/steamclient.so ~/.steam/sdk32/steamclient.so

# NS 3.2.1
# COPY --chown=steam:steam files/ns3.1.zip ns.zip
# RUN unzip ns.zip && \
#    rm -f ns.zip

# NS 3.2.2
RUN TMP_DIR=$(mktemp -d) && \
    wget "$NS_URL" --output-document="$TMP_DIR/ns.zip" && \
    unzip "$TMP_DIR/ns.zip" && \
    rm -Rf "$TMP_DIR"

# REHLDS -- Causes server crash on game start
# RUN TMP_DIR=$(mktemp -d) && \
#    wget "$REHLDS_URL" --output-document="$TMP_DIR/rehlds.zip" && \
#    rm -f core.so demoplayer.so engine_i486.so filesystem_stdio.so hlds_linux hltv proxy.so valve/dlls/director.so && \
#    unzip "$TMP_DIR/rehlds.zip" 'bin/linux32/*' -d "$TMP_DIR" && \
#    chmod -R 755 "$TMP_DIR/bin/linux32" && \
#    cp -R "$TMP_DIR/bin/linux32/." . && \
#    rm -Rf "$TMP_DIR"
    
# COPY scripts to container
COPY --chown=steam:steam scripts/*.sh .
# Edit liblist in order to load metamod and amxmodx, instead of game library
RUN sed -ri 's/^gamedll_linux\s+.*/gamedll_linux "addons\/metamod\/dlls\/metamod.so"/gm' ns/liblist.gam

# NS bug workaround. Since NS links to a GCC which is not included in the steam-provided libstdc++:i386
RUN rm /home/steam/hlds/libstdc++*

# VAC Service
EXPOSE 26900 \
    # HLDS 
    27016 \
    # HLDS RCON
    27016/udp
    
# ENTRYPOINT ["/home/steam/hlds/start-server.sh"]
ENTRYPOINT ["/bin/bash"]
