FROM debian:stable-slim

# Server and world arguments
# World sizes available: 1 (Small), 2(Medium), 3(Large)
ARG WORLD_SIZE=1
# World difficulties available: 1 (Classic), 2 (Expert), 3 (Master), 4 (Journey)
ARG WORLD_DIFFICULTY=1
# World evils available: 1 (Random), 2 (Corrupt), 3 (Crimson)
ARG WORLD_EVIL=1
ARG WORLD_NAME=Primary

ARG SERVER_NAME=TShock
ARG SERVER_IP=127.0.0.1
ARG SERVER_PORT=7777
# Forward options: y/n
ARG SERVER_FORWARD_PORT=n
ARG SERVER_PASSWORD=PASSWORD
ARG SERVER_MAX_SLOTS=16

RUN /usr/bin/apt update -qq > /dev/null 2> /dev/stderr
RUN /usr/bin/apt install -y -qq apt-utils > /dev/null 2> /dev/stderr
RUN /usr/bin/apt install -y -qq zip unzip tar wget mono-complete > /dev/null 2> /dev/stderr
# RUN /usr/bin/apt install -y -qq zip unzip tar wget expect mono-complete > /dev/null 2> /dev/stderr

RUN /usr/bin/mkdir /tmp/tshock
RUN /usr/bin/mkdir /tshock
RUN cd /tmp/tshock

RUN /usr/bin/wget -q https://github.com/Pryaxis/TShock/releases/download/v5.2.0/TShock-5.2-for-Terraria-1.4.4.9-linux-x64-Release.zip -O /tmp/tshock.zip
RUN /usr/bin/unzip /tmp/tshock.zip -d /tmp/
RUN /usr/bin/tar -xf /tmp/*.tar -C /tshock/
RUN /usr/bin/rm -rf /tmp/*

RUN cd /tshock

RUN /usr/bin/mkdir /tshock/worlds /tshock/logs /tshock/config /tshock/plugins

VOLUME [ "/tshock/worlds", "/tshock/logs", "/tshock/config", "/tshock/plugins" ]

WORKDIR /tshock
RUN cp /tshock/ServerPlugins/* /tshock/plugins
RUN rm -rf /tshock/ServerPlugins
RUN ln -s /tshock/plugins /tshock/ServerPlugins

RUN while read -r -t 0; do read -r; done

# Order: new world:world size:world difficulty:world evil:world name:choose world:players slots:port:port forwarding:password:exit command
RUN echo 'n\n'${WORLD_SIZE}'\n'${WORLD_DIFFICULTY}'\n'${WORLD_EVIL}'\n'${WORLD_NAME}'\n\n1\n'${SERVER_MAX_SLOTS}'\n'${SERVER_PORT}'\n'${SERVER_FORWARD_PORT}'\n'${SERVER_PASSWORD}'\n/off\n/off\n' \
| /tshock/TShock.Installer -configpath /tshock/config/ -worldselectpath /tshock/worlds/ -worldpath /tshock/worlds/ -logpath /tshock/logs/
ENV DOTNET_ROOT=/tshock/dotnet

RUN /usr/bin/echo /tshock/worlds/${WORLD_NAME} > /tshock/worlds/SelectedWorld.txt
RUN sed -i -e 's/"ServerPassword": "",/"ServerPassword": "'${SERVER_PASSWORD}'",/g' /tshock/config/config.json
RUN sed -i -e 's/"ServerPort": 7777,/"ServerPort": '${SERVER_PORT}',/g' /tshock/config/config.json
RUN sed -i -e 's/"MaxSlots": 8,/"MaxSlots": '${SERVER_MAX_SLOTS}',/g' /tshock/config/config.json
RUN sed -i -e 's/"ServerName": "",/"ServerName": "'${SERVER_NAME}'",/g' /tshock/config/config.json
RUN sed -i -e 's/"UseServerName": false,/"UseServerName": true,/g' /tshock/config/config.json
RUN /bin/bash -c 'echo -i -e "Setup code: $(cat /tshock/config/setup-code.txt)"'

EXPOSE 7777

ENTRYPOINT /tshock/TShock.Server -configpath /tshock/config/ -config /tshock/config/config.json -worldpath /tshock/worlds/ -logpath /tshock/logs/ -world $(cat /tshock/worlds/SelectedWorld.txt).wld
