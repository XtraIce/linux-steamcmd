#!/bin/bash
DATA_DIR=${HOME}/serverdata
SAVE_LOCATION=${HOME}/$BACKUPS_DIR
SAVE_TARGET_NAME=$SAVE_TARGET_NAME
APP_INFO=${HOME}/steam/appinfo
SERVER_DIR=${DATA_DIR}/$GAME_NAME
TARGET_WORLDSAVE=${SERVER_DIR}/$SAVED_GAME_DIR #/Pal/Saved/SaveGames
TARGET_WORLD_SETTINGS=${SERVER_DIR}/$GAME_SETTINGS_PATH #/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
TARGET_APP=$(basename "${START_SCRIPT:-${GAME_EXECUTABLE}}")
STEAM_APP=$GAME_ID #2394010
QUERY_UPDATE=${DATA_DIR}/repos/linux-steamcmd/QueryUpdateAvailable.sh
ARRCON="/usr/bin/ARRCON"


#Check if Server is running
if $(pgrep -f $TARGET_APP >/dev/null) ; then
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
	#Shutdown existing server using pkill and wait for it to stop
	echo "Shutting Down Server via pkill $TARGET_APP"
	pkill -15 -f $TARGET_APP
	echo "Waiting for $TARGET_APP to stop..."
	while $(pgrep -f $TARGET_APP >/dev/null) || $(pgrep -f $GAME_EXECUTABLE >/dev/null); do
		sleep 1
	done
fi
#Save existing world
dt=$(date '+%m_%d_%Y_%H:%M:%S');
save_dir=${SAVE_LOCATION}/${dt}
echo "Saving game_server to Backup @: ${save_dir}.."
mkdir -p "${save_dir}"/World "${save_dir}"/Config
cp -r "${TARGET_WORLDSAVE}" "${save_dir}"/World
cp -r "${TARGET_WORLD_SETTINGS}" "${save_dir}"/Config
chmod -R 777 "${save_dir}"

# Prune old backups: keep only the 10 most recent dated directories in SAVE_LOCATION
# Safety checks ensure we don't ever prune $HOME or /
if [[ -n "$BACKUPS_DIR" && -d "$SAVE_LOCATION" && "$SAVE_LOCATION" != "$HOME" && "$SAVE_LOCATION" != "/" ]]; then
  echo "Pruning old backups in $SAVE_LOCATION (keeping the 10 most recent)..."
  # Collect backup directories that match the timestamp naming pattern used above
  # Sort by modification time (newest first), then delete everything beyond the first 10
  mapfile -d '' -t backups < <(
    find "$SAVE_LOCATION" -mindepth 1 -maxdepth 1 -type d \
      -regextype posix-extended \
      -regex ".*/[0-9]{2}_[0-9]{2}_[0-9]{4}_[0-9]{2}:[0-9]{2}:[0-9]{2}$" \
      -printf '%T@ %p\0' \
    | sort -z -nr -k1,1 \
    | cut -z -d ' ' -f2-
  )
  if (( ${#backups[@]} > 10 )); then
    to_delete=( "${backups[@]:10}" )
    printf 'Deleting old backup(s):\n'
    printf '  %s\n' "${to_delete[@]}"
    printf '%s\0' "${to_delete[@]}" | xargs -0r rm -rf --
  else
    echo "No old backups to prune (found ${#backups[@]})."
  fi
else
  echo "Skipping prune: SAVE_LOCATION is not a safe directory ($SAVE_LOCATION) or BACKUPS_DIR is unset."
fi

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

