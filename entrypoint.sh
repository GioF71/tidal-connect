#!/bin/bash

echo "Starting Speaker Application in Background (TMUX)"
/usr/bin/tmux new-session -d -s speaker_controller_application '/app/ifi-tidal-release/bin/speaker_controller_application'

echo "Starting TIDAL Connect.."
/app/ifi-tidal-release/bin/tidal_connect_application \
   --tc-certificate-path "/app/ifi-tidal-release/id_certificate/IfiAudio_ZenStream.dat" \
   --playback-device "${PLAYBACK_DEVICE}" \
   -f "${FRIENDLY_NAME}" \
   --codec-mpegh true \
   --codec-mqa ${MQA_CODEC} \
   --model-name "${MODEL_NAME}" \
   --disable-app-security false \
   --disable-web-security false \
   --enable-mqa-passthrough ${MQA_PASSTHROUGH} \
   --log-level 3 \
   --enable-websocket-log "0"

echo "TIDAL Connect Container Stopped."
