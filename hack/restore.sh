#!/usr/bin/env bash
set -o errexit
set -o pipefail

task volsync:restore namespace=default rsrc=actual
task volsync:restore namespace=default rsrc=audiobookshelf
task volsync:restore namespace=default rsrc=bazarr
task volsync:restore namespace=default rsrc=home-assistant
task volsync:restore namespace=default rsrc=node-red
task volsync:restore namespace=default rsrc=open-webui
task volsync:restore namespace=default rsrc=overseerr
task volsync:restore namespace=default rsrc=plex
task volsync:restore namespace=default rsrc=radarr
task volsync:restore namespace=default rsrc=readarr
task volsync:restore namespace=default rsrc=recyclarr
task volsync:restore namespace=default rsrc=sonarr
task volsync:restore namespace=default rsrc=zigbee2mqtt
task volsync:restore namespace=default rsrc=zwave
task volsync:restore namespace=default rsrc=mealie
task volsync:restore namespace=default rsrc=pinchflat
task volsync:restore namespace=default rsrc=mealie
task volsync:restore namespace=downloads rsrc=qb
task volsync:restore namespace=downloads rsrc=sabnzbd
