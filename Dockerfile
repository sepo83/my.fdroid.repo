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
RUN  apt update && \
#    apt upgrade -y && \
    apt install -y \	
	nano cron \
	cargo pkg-config libssl-dev \
	#build-essential  \ 
#	fdroidserver \
#	openjdk-17-jre aapt apksigner  \
	python3-pip rsync git unzip software-properties-common && \
    apt autoclean && apt autoremove -y && apt clean 

#install fdroid from ppa
RUN add-apt-repository ppa:fdroid/fdroidserver && \
    apt update && \
    apt install -y fdroidserver  

#workaround: fdroidserver/update.py log which file is processed to INFO
ADD fdroidserver_update.patch /
RUN patch -u -b $(dpkg -L fdroidserver | grep "fdroidserver/update.py")  -i fdroidserver_update.patch && \
	rm fdroidserver_update.patch

#workaround: fdroidserver/update.py dont synch archive back to repo
ADD fdroidserver_update2.patch /
RUN patch -u -b $(dpkg -L fdroidserver | grep "fdroidserver/update.py")  -i fdroidserver_update2.patch && \
	rm fdroidserver_update2.patch
	
#install apkeep
#ENV PATH ${PATH}:/root/.cargo/bin
#RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
RUN cargo install --git https://github.com/EFForg/apkeep.git 


WORKDIR $FDROID_DIR
ADD fdroid_update /usr/bin/fdroid_update
ADD fdroid_remove_apk /usr/bin/
ADD fdroid_purge_apk /usr/bin/
ADD example_apk_list.txt /
#add a script that configures and starts cronjob
ADD 95_myfdroidserver /etc/cont-init.d/

VOLUME /config
