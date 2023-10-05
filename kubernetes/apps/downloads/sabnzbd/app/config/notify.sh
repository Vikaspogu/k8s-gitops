#!/usr/bin/env bash

echo "**** check for nzb-notify ****"
FILE=/config/scripts/requirements.txt
if [ -f "$FILE" ]; then
    echo "nzb-notify already downloaded"
else
    echo "**** get nzb-notify lastest version ****"
    cd /config/
    mkdir scripts
    cd scripts
    curl https://codeload.github.com/caronc/nzb-notify/zip/master -o nzb-notify-master.zip

    echo "**** check for and installing unzip ****"
    if ! command -v unzip &> /dev/null
    then
        echo "unzip could not be found"
        apt-get update
        apt-get -y install zip
    fi

    echo "**** unzip contents ****"
    unzip -o -d . nzb-notify-master.zip

    echo "**** cleanup ****"
    mv nzb-notify-master/* ./
    rm -r nzb-notify-master
    rm nzb-notify-master.zip
fi

echo "**** installing nzb-notify requirements ****"
pip install -r /config/scripts/requirements.txt

echo "**** done ****"
exit
