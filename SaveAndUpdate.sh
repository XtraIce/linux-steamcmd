#!/bin/bash
#DATA_DIR=$HOME/serverdata
SAVE_LOCATION=$HOME/PalWorldBackups
APP_INFO=$HOME/steam/appinfo
SERVER_DIR=${DATA_DIR}/palworld
TARGET_WORLDSAVE=${SERVER_DIR}/Pal/Saved/SaveGames
TARGET_WORLD_SETTINGS=${SERVER_DIR}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
TARGET_APP=PalServer_Linux
STEAM_APP=2394010
QUERY_UPDATE=${DATA_DIR}/repos/linux-steamcmd/QueryUpdateAvailable.sh
ARRCON="/usr/bin/ARRCON"


#Check if Server is running
if $(pgrep PalServer-Linux >/dev/null) ; then
	#Broadcast that the server will be going down soon.
	echo "Broadcast Server_will_be_shutdown_in_30_mins" | $ARRCON -S palworld && echo "Broadcast for_scheduled_maintanence_-Red" | ARRCON -S palworld
	if [ $? -eq 0 ]; then
		sleep 20m
		echo "Broadcast Server_will_be_shutdown_in_10_mins" |$ARRCON -S palworld && echo "Broadcast for_scheduled_maintanence" | ARRCON -S palworld
		sleep 9m 30s
		echo "Broadcast SERVER_IS_SHUTTING_DOWN" | $ARRCON -S palworld
		echo "Broadcast Est_restart_time_<_2MIN" | $ARRCON -S palworld
		echo "Broadcast DRINK_SOME_WATER" | $ARRCON -S palworld
		sleep 10
		echo "Save" | $ARRCON -S palworld
	else
		echo "$RCON Failed. Shutting down now."
	fi
	#Shutdown existing server
	echo "Shutting Down Server..."
	pkill -15 PalServer-Linux #sigterm
fi
#Save existing world
dt=$(date '+%m_%d_%Y_%H:%M:%S');
save_dir=${SAVE_LOCATION}/${dt}
echo "Saving PalWorld to Backup @: ${save_dir}.."
mkdir -p "${save_dir}"/World "${save_dir}"/Config
cp -r "${TARGET_WORLDSAVE}" "${save_dir}"/World
cp "${TARGET_WORLD_SETTINGS}" "${save_dir}"/Config
#Update Server
echo "Checking for server updates..."
ret=$("$QUERY_UPDATE" "$STEAM_APP" "$SERVER_DIR")
echo "ret = $ret"
if [[ $ret == 1 ]]; then
	echo "Game Updated. Restoring Backed Up Save"
	rm -rf "$TARGET"
	cp -rf "$save_dir/World/SaveGames" "$TARGET/.."
else 
	echo "Game version is latest"
fi
echo "Updates Done! Server may now restart."
