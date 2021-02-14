FROM registry.gitlab.com/fdroid/ci-images-base as fdroid-ci-image

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
        patch

#get android sdk
ENV ANDROID_HOME="/opt/android-sdk-linux"
COPY --from=fdroid-ci-image /opt/android-sdk ${ANDROID_HOME}

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:/fdroidserver:/gplaycli:/usr/lib/jvm/java-10-openjdk/bin

ENV JAVA_OPTS='-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee'

RUN mkdir /root/.android \
	&& touch /root/.android/repositories.cfg \
	&& echo y | $ANDROID_HOME/tools/bin/sdkmanager "platform-tools" "platforms;android-30" \
	&& echo y | $ANDROID_HOME/tools/bin/sdkmanager "build-tools;30.0.3" \
	&& echo y | $ANDROID_HOME/tools/bin/sdkmanager --update

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
ADD gpapi.patch /
RUN patch -u -b /usr/lib/python3.8/site-packages/gpapi/googleplay.py  -i gpapi.patch

#workaround for bug: not updating apks, when version tag is appended to apk filename
ADD gplaycli.patch /
RUN patch -u -b /gplaycli/gplaycli/gplaycli.py  -i gplaycli.patch

WORKDIR $FDROID_DIR
ADD fdroid_update /usr/bin/fdroid_update
ADD fdroid_remove_apk /usr/bin/
ADD fdroid_purge_apk /usr/bin/
ADD gplay_search /usr/bin/gplay_search
ADD gplay_download /usr/bin/gplay_download
#add a script that configures and starts cronjob
ADD 95_myfdroidserver /etc/cont-init.d/
