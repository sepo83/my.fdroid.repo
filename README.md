my.fdroid.server
================

my.fdroid.server is docker-container wich combines [gplaycli](https://github.com/matlink/gplaycli) from @matlink with [fdroidserver](https://gitlab.com/fdroid/fdroidserver) from F-Droid team.
Regular updates are triggered via cron.

The docker image is based on [nginx](https://docs.linuxserver.io/images/docker-nginx)  from linuxserver.io team and on [ci-images-base](https://gitlab.com/fdroid/ci-images-base) from F-Droid team for getting android-sdk.

This repo is provided as is. Due to lack of time there might be no further development.

Remark
------
gplay stopped working for me a while ago. As alternative [apkeep](https://github.com/EFForg/apkeep) was integrated (see branch "apkeep").

Usage
-----

**Installation**

If an empty docker-volume is given, the container:
* creates the standard webserver-config (`/config/www`,`/config/nginx`
* initialises fdroid repository at `/config/fdroid` by using `fdroid init`
* copies a standard gplaycli config file at `/config/fdroid/gplaycli.conf`
* copies a examplaric apk list (for downloading firefox) to `/config/fdroid/apk_list.txt`

After container has started you have to:
* edit fdroid-repo conifg file `config.yml` (see example on [https://gitlab.com/fdroid/fdroidserver/-/blob/master/examples/config.yml])
* edit gplaycli config file `gplaycli.conf` (remark: for me only plaintext resp. mail+password  login works)
* fill `apk_list.txt` with apks
* update fdroid repo with `fdroid_update`

**apk-list.txt**

`/config/fdroid/apk_list.txt` contains a list of apks to be handled by gplaycli. Each line shall contain a single apk-id. Each line containing `#` will be ignored (poor mans commenting function).
If an apk is contained in `apk_list.txt` then it will be downloaded resp. updated. All other apk-files found in `/config/fdroid/repo` will be deleted localy and from local FDroid-Server.

**Scripts in container**

| Script name                 | Description |
| ---                         | ----        |
| `gplay_search <name>`       | Searches for apks with <name> at store. |
| `gplay_download <app-id>`   | Downloads apk with <app-id> to `/config/fdroid/repo` and appedns version to apk-filename. Remark: Unless apk is not added to `apk_list.txt`, it will be deleted with next `fdroid_update`. |
| `fdroid_update`             | Downloads apk-updates based on the apks found in `/config/fdroid/repo` and  triggers the `fdroid update` and `fdroid deploy`. |
| `fdroid_remove_apk <name>`  | Removes apks with <name> from `/config/fdroid/repo`. Wildcards might be used. Remark: Unless apk is not removed from `apk_list.txt`, it will be readded with next `fdroid_update`. |
| `fdroid_purge_apk <name>`   | Same as `fdroid_remove_apk`, but also removes apks from `/config/fdroid/archive`|



Docker
------

**Build docker:**

````
git clone <tbd>
cd my.fdroid.server
docker build -t my.fdroid.server .
````

**Environment:**


| Env                 | Default Value       | Function        |
| -----------------   | --------------      | --------------- |
| PUID                | 1000                | for UserID; also see explanation on linuxserver.io| 
| GUID                | 1000                | for GroupID; also see explanation on linuxserver.io| 
| TZ                  | Europe/Berlin       | used timezone in the Container |
| LANG                | de_DE.UTF-8         | language and coding in container |
| CRON_TIMESPEC       | 35 2 * * *          | time specification for cronjob; specifies when repo is updated using `fdroid_update` (default: nightly at 2:35am). A generator for cron time specification can be found for example here: https://crontab.guru/| 
| RUN_ON_STARTUP      | no                  | if 'yes', fdroid_update will be executed on container startup


As on most linuxserver.io based images all configuration (path in container: `/config`) is stored in a docker-volume. 

`/config/fdroid` contains fdroid-configuration as well as gplaycli configfile.

`/config/nginx` contains webserver configuration.

`/config/www` contains webserverroot. fdroid usually copies the repo files here.


