#!/bin/bash

# https://superuser.com/questions/1727148/check-if-steam-game-requires-an-update-via-command-line
# by Mag Roader
# modified for Linux bash

#@ECHO OFF
CURLCMD=/usr/bin/curl
STEAMCMD=$HOME/steamcmd/steamcmd.sh
RETVALUE=-1
exit=0

if [[ "$1" == "" ]]; then
	exit=1
	echo "ERROR: Please provide Steam App ID as first parameter"

else
	APPID="$1"
	echo "App ID: ${APPID}"
fi

if [[ !$exit && "$2" == "" ]]; then
	exit=1
	echo "ERROR: Please provide app directory as second parameter - likely within  steamapp/common"
else
	APP_INSTALL_DIR="$2"
fi

if [[ !$exit && ! -d "${APP_INSTALL_DIR}" ]]; then
	exit=1
	echo "ERROR: Install directory not found: ${APP_INSTALL_DIR}"
else
	echo "App Dir: ${APP_INSTALL_DIR}"
fi

if [[ !$exit ]]; then
	if command -v ${STEAMCMD} &> /dev/null; then
		APPINFO_DIR=/home/steam/Steam/appinfo
		APPINFO_FILE="${APPINFO_DIR}/${APPID}"
		echo "APPINFO_FILE : ${APPINFO_FILE} "
		APPINFO_FILE_NEW="${APPINFO_FILE}-new"
		echo "APPINFO_FILE_NEW : ${APPINFO_FILE_NEW}"

		if ! [ -d ${APPINFO_DIR} ]; then
			mkdir ${APPINFO_DIR}
		fi

		echo "Checking for needed updates for game id ${APPID}"
	else
		echo "${STEAMCMD} could not be found"
		exit=1
	fi
fi

cmd="${CURLCMD} https://api.steamcmd.net/v1/info/${APPID} --silent --fail --output ${APPINFO_FILE_NEW}"
echo "$cmd"
if [[ !$exit ]]; then 
	if !($cmd) then
		echo "Error getting app info for game"
		exit=1
	else
		NEEDS_UPDATE=true
	fi
fi

if [[ !$exit && -f "${APPINFO_FILE}" && "cmp --silent ${APPINFO_FILE} ${APPINFO_FILE_NEW}" ]]; then
	NEEDS_UPDATE=false
fi

if [[ ${NEEDS_UPDATE} != false ]]; then
	echo "Update required, installing to ${APP_INSTALL_DIR}"
	cmd="${STEAMCMD} +force_install_dir ${APP_INSTALL_DIR} +login anonymous +app_update ${APPID} validate +quit"
	if !($cmd) then
		echo "Error updating app via steamcmd"
		exit=1
	else
		mv "${APPINFO_FILE_NEW}" "${APPINFO_FILE}"
		echo "Version out-of-date"
		RETVALUE=1
	fi
else
	echo "Version up-to-date"
	rm -f ${APPINFO_FILE_NEW}
	RETVALUE=0
fi

exit 0
