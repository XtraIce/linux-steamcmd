#!/bin/bash
DATA_DIR=$HOME/serverdata
SAVE_LOCATION=$HOME/$BACKUPS_DIR
SAVE_TARGET_NAME=$SAVE_TARGET_NAME
APP_INFO=$HOME/steam/appinfo
SERVER_DIR=${DATA_DIR}/$GAME_NAME
TARGET_WORLDSAVE=${SERVER_DIR}/$!SAVEDGAME#/Pal/Saved/SaveGames
TARGET_WORLD_SETTINGS=${SERVER_DIR}/$GAME_SETTINGS_PATH #/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
TARGET_APP=$APP_NAME#PalServer_Linux
STEAM_APP=$GAME_ID#2394010
QUERY_UPDATE=${DATA_DIR}/repos/linux-steamcmd/QueryUpdateAvailable.sh
ARRCON="/usr/bin/ARRCON"


#Check if Server is running
if $(pgrep $TARGET_APP >/dev/null) ; then
	#Broadcast that the server will be going down soon.
	echo "Broadcast Server_will_be_shutdown_in_30_mins" | $ARRCON -S game_server && echo "Broadcast for_scheduled_maintanence_-Red" | ARRCON -S game_server
	if [ $? -eq 0 ]; then
		sleep 20m
		echo "Broadcast Server_will_be_shutdown_in_10_mins" |$ARRCON -S game_server && echo "Broadcast for_scheduled_maintanence" | ARRCON -S game_server
		sleep 9m 30s
		echo "Broadcast SERVER_IS_SHUTTING_DOWN" | $ARRCON -S game_server
		echo "Broadcast Est_restart_time_<_2MIN" | $ARRCON -S game_server
		echo "Broadcast DRINK_SOME_WATER" | $ARRCON -S game_server
		sleep 10
		echo "Save" | $ARRCON -S game_server
	else
		echo "$RCON Failed. Shutting down now."
	fi
	#Shutdown existing server
	echo "Shutting Down Server..."
	pkill -15 $TARGET_APP #sigterm
fi
#Save existing world
dt=$(date '+%m_%d_%Y_%H:%M:%S');
save_dir=${SAVE_LOCATION}/${dt}
echo "Saving game_server to Backup @: ${save_dir}.."
mkdir -p "${save_dir}"/World "${save_dir}"/Config
cp -r "${TARGET_WORLDSAVE}" "${save_dir}"/World
cp "${TARGET_WORLD_SETTINGS}" "${save_dir}"/Config
#Update Server
echo "Checking for game_server updates..."
ret=$("$QUERY_UPDATE" "$STEAM_APP" "$SERVER_DIR")
echo "ret = $ret"
if [[ $ret == 1 ]]; then
	echo "Game Updated. Restoring Backed Up Save"
	rm -rf "$TARGET_WORLDSAVE"
	cp -rf "$save_dir/World/SaveGames" "$TARGET_WORLDSAVE/.."
else 
	echo "Game version is latest"
fi
echo "Updates Done! Server may now restart."
