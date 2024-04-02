FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

#ENV TZ="Europe/Berlin"
#ENV LANG="de_DE.UTF-8"

ENV FDROID_DIR="/config/fdroid"
ENV CRON_TIMESPEC="35 2 * * *"
ENV RUN_ON_STARTUP="No"

ENV APKEEP_STORE="apk-pure"
ENV APKEEP_USERNAME=""
ENV APKEEP_PASSWORD=""

RUN echo "Building..."

# install dependencies
RUN apt update && \
    apt upgrade -y && \
    apt install -y \	
	nano cron \
	build-essential pkg-config libssl-dev \ 
	aapt apksigner  \
	python3-pip rsync git unzip && \
    apt autoclean && apt autoremove -y && apt clean 
	
#install apkeep
ENV PATH ${PATH}:/root/.cargo/bin
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
RUN cargo install --git https://github.com/EFForg/apkeep.git 

ENV PATH ${PATH}:/fdroidserver

#install fdroidserver
RUN git clone --depth 1 https://gitlab.com/fdroid/fdroidserver.git \
     && export PATH="$PATH:$PWD/fdroidserver" \
     && pip3 install -e fdroidserver

#workaround: fdroidserver/update.py log which file is processed to INFO
ADD fdroidserver_update.patch /
RUN patch -u -b /fdroidserver/fdroidserver/update.py  -i fdroidserver_update.patch

#workaround: fdroidserver/update.py dont synch archive back to repo
ADD fdroidserver_update2.patch /
RUN patch -u -b /fdroidserver/fdroidserver/update.py  -i fdroidserver_update2.patch

WORKDIR $FDROID_DIR
ADD fdroid_update /usr/bin/fdroid_update
ADD fdroid_remove_apk /usr/bin/
ADD fdroid_purge_apk /usr/bin/
ADD example_apk_list.txt /
#add a script that configures and starts cronjob
ADD 95_myfdroidserver /etc/cont-init.d/

VOLUME /config
