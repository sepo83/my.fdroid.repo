FROM registry.gitlab.com/fdroid/ci-images-base as fdroid-ci-image

RUN  touch /root/.android/repositories.cfg \
	&& echo y | $ANDROID_HOME/tools/bin/sdkmanager "platform-tools" "platforms;android-29" \
        && echo y | $ANDROID_HOME/tools/bin/sdkmanager "build-tools;29.0.3" \
        && echo y | $ANDROID_HOME/tools/bin/sdkmanager "platform-tools" "platforms;android-30" \
        && echo y | $ANDROID_HOME/tools/bin/sdkmanager "build-tools;30.0.3" \
        && echo y | $ANDROID_HOME/tools/bin/sdkmanager --update


FROM ghcr.io/linuxserver/nginx

ENV TZ="Europe/Berlin"
ENV LANG="de_DE.UTF-8"

ENV FDROID_DIR="/config/fdroid"
ENV CRON_TIMESPEC="35 2 * * *"
ENV RUN_ON_STARTUP="No"

#install apks 
RUN apk update && apk add  \
        py3-pip \
        libxml2-dev libxslt-dev py3-matplotlib py3-cryptography py3-bcrypt py3-pynacl py3-yaml py3-lxml \
        rsync \
        openjdk10-jdk \
        patch && \
    rm -rf /var/cache/apk/*

#get android sdk
ENV ANDROID_HOME="/opt/android-sdk-linux"
COPY --from=fdroid-ci-image /opt/android-sdk ${ANDROID_HOME}

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:/fdroidserver:/gplaycli:/usr/lib/jvm/java-10-openjdk/bin

ENV JAVA_OPTS='-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee'

#install fdroidserver
RUN git clone --depth 1 https://gitlab.com/fdroid/fdroidserver.git \
     && export PATH="$PATH:$PWD/fdroidserver" \
     && pip3 install -e fdroidserver 

#install gplaycli
RUN git clone --depth 1 https://github.com/matlink/gplaycli.git \
     && export PATH="$PATH:$PWD/gplaycli" \
     && pip3 install -e gplaycli

#workaround for BAD AUTHENTICATION error when using plaintext password
RUN pip3 install --upgrade urllib3==1.24.2

#workaround for "Unexpected end-group tag" error
#Remark: patch-example: diff -u gplaycli.py_old gplaycli.py > gplaycli.patch
#Remark: the $(python3...) cmd gives the path to /usr/lib/pythonX.X/site-packages
ADD gpapi.patch /
RUN patch -u -b $(python3 -c "import site;print([p for p in site.getsitepackages() if 'site-package' in p][0])")/gpapi/googleplay.py  -i gpapi.patch

#workaround for bug: not updating apks, when version tag is appended to apk filename
ADD gplaycli.patch /
RUN patch -u -b /gplaycli/gplaycli/gplaycli.py  -i gplaycli.patch

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
ADD gplay_search /usr/bin/gplay_search
ADD gplay_download /usr/bin/gplay_download
ADD example_apk_list.txt /
#add a script that configures and starts cronjob
ADD 95_myfdroidserver /etc/cont-init.d/
