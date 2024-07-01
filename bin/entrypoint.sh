#!/bin/bash

echo "Tidal Connect - https://github.com/GioF71/tidal-connect.git - entrypoint.sh version 0.1.8"

mkdir -p /config

source /common.sh

# run configuration
configure

PLAYBACK_DEVICE=`get_playback_device`
echo "PLAYBACK_DEVICE=[${PLAYBACK_DEVICE}]"

friendly_name=`load_key_value $KEY_FRIENDLY_NAME`
model_name=`load_key_value $KEY_MODEL_NAME`
mqa_codec=`load_key_value $KEY_MQA_CODEC`
mqa_passthrough=`load_key_value $KEY_MQA_PASSTHROUGH`

if [[ -z "${DISABLE_CONTROL_APP}" ]] || [[ $DISABLE_CONTROL_APP -eq 0 ]]; then
   echo "Starting Speaker Application in Background (TMUX)"
   /usr/bin/tmux new-session -d -s speaker_controller_application '/app/ifi-tidal-release/bin/speaker_controller_application'

   echo "Sleeping for a while ($SLEEP_TIME_SEC seconds)..."
   sleep $SLEEP_TIME_SEC
fi

echo "ENABLE_GENERATED_TONE=[${ENABLE_GENERATED_TONE}]"
tone_enabled=1
if [[ -n "${ENABLE_GENERATED_TONE}" ]] && [[ "${ENABLE_GENERATED_TONE^^}" == "NO" || "${ENABLE_GENERATED_TONE^^}" == "N" ]]; then
   tone_enabled=0
elif [[ -n "${ENABLE_GENERATED_TONE}" ]] && [[ "${ENABLE_GENERATED_TONE^^}" != "YES" && "${ENABLE_GENERATED_TONE^^}" != "Y" ]]; then
   echo "Invalid ENABLE_GENERATED_TONE=[$ENABLE_GENERATED_TONE]"
   exit 1
else
   echo "Generated tone is enabled"
fi

executable_path=/app/ifi-tidal-release/bin/tidal_connect_application
certificate_path=/app/ifi-tidal-release/id_certificate/IfiAudio_ZenStream.dat

if [[ -n "${CERTIFICATE_PATH}" ]]; then
   certificate_path=${CERTIFICATE_PATH}
fi
echo "certificate_path=[${certificate_path}]"

COMMAND_LINE="${executable_path} \
         --tc-certificate-path ${certificate_path} \
         --playback-device ${PLAYBACK_DEVICE} \
         -f \"${friendly_name}\" \
         --model-name \"${model_name}\" \
         --codec-mpegh true \
         --codec-mqa ${mqa_codec} \
         --disable-app-security false \
         --disable-web-security false \
         --enable-mqa-passthrough ${mqa_passthrough} \
         --log-level ${LOG_LEVEL} \
         --enable-websocket-log \"0\""

if [[ -n "${CLIENT_ID}" ]]; then
   COMMAND_LINE="${COMMAND_LINE} --clientid \"${CLIENT_ID}\""
fi

echo "COMMAND_LINE=${COMMAND_LINE}"

while true
do
   tone_skipped=0
   if [[ $tone_enabled -eq 1 ]]; then
      echo "Trying a short tone @ 48kHz ..."
      tone_played=0
      if aplay -D $PLAYBACK_DEVICE /assets/audio/short-low-tone-48k.wav; then
         echo "Success with 48 kHz tone."
         tone_played=1
      else
         echo "Failed with 48 kHz tone, trying 44.1 kHz ..."
         if aplay -D $PLAYBACK_DEVICE /assets/audio/short-low-tone-44k.wav; then
            echo "Success with 44.1 kHz tone."
            tone_played=1
         fi
      fi
      echo "tone_played=[$tone_played]"
   else
      tone_skipped=1
      echo "tone_skipped=[$tone_skipped]"
   fi
   if [[ $tone_played -eq 1 || $tone_skipped -eq 1 ]]; then
      echo "Starting TIDAL Connect ..."
      eval "${COMMAND_LINE}"
      echo "TIDAL Connect Container Stopped."
   else
      echo "Device locked/invalid, won't start the application ..."
   fi
   if [ $RESTART_ON_FAIL -eq 1 ]; then
      echo "Sleeping $RESTART_WAIT_SEC seconds before restarting ..."
      sleep $RESTART_WAIT_SEC
   else
      echo "RESTART_ON_FAIL=$RESTART_ON_FAIL, exiting."
      break
   fi
done