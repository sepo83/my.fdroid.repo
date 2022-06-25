my.fdroid.server
================

my.fdroid.server is docker-container wich combines [apkeep](https://github.com/EFForg/apkeep.git) from @EFForg with [fdroidserver](https://gitlab.com/fdroid/fdroidserver) from F-Droid team.
Regular updates are triggered via cron. Repository can be published via separate container; e.g. [nginx](https://github.com/linuxserver/docker-nginx.git) from linuxserver.io

The docker image is based on [baseimage-ubuntu](https://github.com/linuxserver/docker-baseimage-ubuntu.git)  from linuxserver.io team.

This repo is provided as is. Due to lack of time there might be no further development.

Usage
-----

**Installation**

If an empty docker-volume is given, the container:
* initialises fdroid repository at `/config/fdroid` by using `fdroid init`
* copies a examplaric apk list (for downloading firefox) to `/config/fdroid/apk_list.txt`

After container has started you have to:
* edit fdroid-repo conifg file `config.yml` (see example on [https://gitlab.com/fdroid/fdroidserver/-/blob/master/examples/config.yml])
* fill `apk_list.txt` with apks
* update fdroid repo with `fdroid_update`

**apk-list.txt**

`/config/fdroid/apk_list.txt` contains a list of apks to be handled by gplaycli. Each line shall contain a single apk-id. Each line containing `#` will be ignored (poor mans commenting function).
If an apk is contained in `apk_list.txt` then it will be downloaded resp. updated. All other apk-files found in `/config/fdroid/repo` will be deleted localy and from local FDroid-Server.

**Scripts in container**

| Script name                 | Description |
| ---                         | ----        |
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
| APKEEP_STORE        | apk-pure            | the store used by apkeep to download apk (see -d option on apkeep); can be google-play, apk-pure, f-droid, huawei-app-gallery)
| APKEEP_USERNAME     |                     | username for google-account; needed for APKEEP_STORE=google_play (see -u option on apkeep)
| APKEEP_PASSWORD     |                     | password for google-account; needed for APKEEP_STORE=google_play (see -p option on apkeep); an app-specific password might be used


As on most linuxserver.io based images all configuration (path in container: `/config`) is stored in a docker-volume. 

`/config/fdroid` contains fdroid-configuration as well as gplaycli configfile.

Troubleshooting
------

* if fdroid update fails, try to delete the metadata and tmp folder (resp. some bofus files there)
