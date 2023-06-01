#!/bin/bash

write_audio_config() {
   card_index=$1
   if test -f /etc/asound.conf; then
      truncate -s 0 /etc/asound.conf
   fi
   echo "Creating sound configuration file (card_index=$card_index)..."
   echo "defaults.pcm.card $card_index" >> /etc/asound.conf
   echo "defaults.ctl.card $card_index" >> /etc/asound.conf
   echo "Sound configuration file created."
}

echo "FRIENDLY_NAME=$FRIENDLY_NAME"
echo "MQA_CODEC=$MQA_CODEC"
echo "MODEL_NAME=$MODEL_NAME"
echo "MQA_PASSTHROUGH=$MQA_PASSTHROUGH"
echo "CARD_NAME=$CARD_NAME"
echo "CARD_INDEX=$CARD_INDEX"

card_index=$CARD_INDEX
card_name=$CARD_NAME

if test -f /etc/asound.conf; then
   echo "BEFORE"
   cat /etc/asound.conf
fi

if [[ "${card_index}" == "-1" && -n "${card_name}" ]]; then
   aplay -l | sed 1d | \
   while read i
   do
      first_word=`echo $i | cut -d " " -f 1`
      if [[ "${first_word}" == "card" ]]; then
         second_word=`echo $i | cut -d ":" -f 1`
         third_word=`echo $i | cut -d " " -f 3`
         #echo "second_word=$second_word"
         #echo "third_word=$third_word"
         card_number=`echo $second_word | cut -d " " -f 2`
         if [[ "${third_word}" == "${CARD_NAME}" ]]; then
            echo "Found audio device [${CARD_NAME}] as index [$card_number]"
            write_audio_config $card_number
            break
         fi
      fi
   done
elif [[ -z "${card_index}" ]]; then
    echo "Set default card_index=[$DEFAULT_CARD_INDEX]"
    write_audio_config $DEFAULT_CARD_INDEX
fi

cat /etc/asound.conf

echo "Starting Speaker Application in Background (TMUX)"
/usr/bin/tmux new-session -d -s speaker_controller_application '/app/ifi-tidal-release/bin/speaker_controller_application'

echo "Sleeping for a while ($SLEEP_TIME_SEC seconds)..."
sleep $SLEEP_TIME_SEC

echo "Starting TIDAL Connect ..."
/app/ifi-tidal-release/bin/tidal_connect_application \
   --tc-certificate-path "/app/ifi-tidal-release/id_certificate/IfiAudio_ZenStream.dat" \
   --playback-device "sysdefault" \
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
