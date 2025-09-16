#!/bin/bash
# Broadcast maintenance messages to the game server via ARRCON
ARRCON="/usr/bin/ARRCON"
TARGET_APP=$(basename "${START_SCRIPT:-${GAME_EXECUTABLE}}")

if $BROADCAST_MAINTENANCE; then
    # Broadcast sequence
    if $(pgrep -f $TARGET_APP >/dev/null) ; then
        echo "${RCON_BROADCAST_CMD} Server_will_be_shutdown_in_30_mins" | $ARRCON -S game_server && \
        echo "${RCON_BROADCAST_CMD} for_scheduled_maintanence_" | $ARRCON -S game_server
        if [ $? -eq 0 ]; then
            sleep 20m
            echo "${RCON_BROADCAST_CMD} Server_will_be_shutdown_in_10_mins" | $ARRCON -S game_server && \
            echo "${RCON_BROADCAST_CMD} for_scheduled_maintanence" | $ARRCON -S game_server
            sleep 9m 30s
            echo "${RCON_BROADCAST_CMD} SERVER_IS_SHUTTING_DOWN" | $ARRCON -S game_server
            echo "${RCON_BROADCAST_CMD} Est_restart_time_<_2MIN" | $ARRCON -S game_server
            echo "${RCON_BROADCAST_CMD} DRINK_SOME_WATER" | $ARRCON -S game_server
            sleep 10
            echo "${RCON_BROADCAST_CMD} Save" | $ARRCON -S game_server
        else
            echo "$RCON Failed. Shutting down now."
        fi
    fi
else
    echo "Broadcast maintenance messages disabled. Proceeding without broadcast."
fi
