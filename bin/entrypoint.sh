#!/bin/bash

echo "Tidal Connect - https://github.com/GioF71/tidal-connect.git - entrypoint.sh version 0.1.1"

ASOUND_CONF_SIMPLE_FILE=asound.conf
ASOUND_CONF_FILE=/etc/$ASOUND_CONF_SIMPLE_FILE

ASOUND_CONF_EXISTS=0
ASOUND_CONF_WRITABLE=1

DEFAULT_FRIENDLY_NAME="Tidal connect"
DEFAULT_MODE_NAME="Audio Streamer"
DEFAULT_MQA_CODEC="false"
DEFAULT_MQA_PASSTHROUGH="false"

write_audio_config() {
   if [[ $ASOUND_CONF_EXISTS -eq 0 ]] || [[ $ASOUND_CONF_WRITABLE -eq 1 ]]; then
      if test -f "$ASOUND_CONF_FILE"; then
         truncate -s 0 "$ASOUND_CONF_FILE"
      fi
      echo "Creating sound configuration file (card_index=$CARD_INDEX)..."
      echo "pcm.!default {" >> /etc/asound.conf
      echo "  type plug" >> /etc/asound.conf
      echo "  slave.pcm {" >> /etc/asound.conf
      echo "    type hw" >> /etc/asound.conf
      echo "    card ${CARD_INDEX}" >> /etc/asound.conf
      if [[ -n "${CARD_DEVICE}" ]]; then
         echo "    device $CARD_DEVICE" >> /etc/asound.conf
      fi
      if [[ -n "${CARD_FORMAT}" ]]; then
         echo "    format $CARD_FORMAT" >> /etc/asound.conf
      fi
      echo "  }" >> /etc/asound.conf
      echo "}" >> /etc/asound.conf
      echo "Sound configuration file created."
   else
      echo "Cannot create file [$ASOUND_CONF_FILE]: Exists [$ASOUND_CONF_EXISTS] Writable [$ASOUND_CONF_WRITABLE]"
   fi
}

if [[ -z "${FRIENDLY_NAME}" ]]; then
   FRIENDLY_NAME="${DEFAULT_FRIENDLY_NAME}"
fi

if [[ -z "${MODEL_NAME}" ]]; then
   MODEL_NAME="${DEFAULT_MODE_NAME}"
fi

if [[ -z "${MQA_CODEC}" ]]; then
   MQA_CODEC="${DEFAULT_MQA_CODEC}"
fi

if [[ -z "${MQA_PASSTHROUGH}" ]]; then
   MQA_PASSTHROUGH="${DEFAULT_MQA_PASSTHROUGH}"
fi

echo "FRIENDLY_NAME=$FRIENDLY_NAME"
echo "MODEL_NAME=$MODEL_NAME"
echo "MQA_CODEC=$MQA_CODEC"
echo "MQA_PASSTHROUGH=$MQA_PASSTHROUGH"
echo "CARD_NAME=$CARD_NAME"
echo "CARD_INDEX=$CARD_INDEX"
echo "CARD_DEVICE=$CARD_DEVICE"

PLAYBACK_DEVICE=default

## see if there is a user-provided asound.conf file
USER_CONFIG_DIR=/userconfig
if [ -f "$USER_CONFIG_DIR/$ASOUND_CONF_SIMPLE_FILE" ]; then
   echo "File [$ASOUND_CONF_SIMPLE_FILE] has been provided, copying to [$ASOUND_CONF_FILE] ..."
   cp $USER_CONFIG_DIR/$ASOUND_CONF_SIMPLE_FILE /etc/asound.conf
   # make it read-only
   chmod -w $ASOUND_CONF_FILE
   ASOUND_CONF_EXISTS=1
   ASOUND_CONF_WRITABLE=0
   # set PLAYBACK_DEVICE to [custom] if not set
   if [[ -z "${FORCE_PLAYBACK_DEVICE}" ]]; then
      echo "FORCE_PLAYBACK_DEVICE empty, setting to [custom]"
      FORCE_PLAYBACK_DEVICE=custom
   else  
      echo "FORCE_PLAYBACK_DEVICE is already set to [${FORCE_PLAYBACK_DEVICE}], leaving as-is"
   fi
else
   echo "File [$ASOUND_CONF_SIMPLE_FILE] has not been provided"
   if [ -f "$ASOUND_CONF_FILE" ]; then
      echo "File $ASOUND_CONF_FILE exists."
      ASOUND_CONF_EXISTS=1
   else
      echo "File $ASOUND_CONF_FILE does not exists."
   fi
   if [ $ASOUND_CONF_EXISTS -eq 1 ]; then
      # check if file is writable
      if [ -w "$ASOUND_CONF_FILE" ]; then
         echo "File $ASOUND_CONF_FILE is writable"
         ASOUND_CONF_WRITABLE=1 
      else
         echo "File $ASOUND_CONF_FILE is NOT writable"
         ASOUND_CONF_WRITABLE=0
      fi
   fi
fi

card_index=$CARD_INDEX
card_name=$CARD_NAME

# dump current asound.conf if it exists
if [ $ASOUND_CONF_EXISTS -eq 1 ]; then
   echo "Current $ASOUND_CONF_FILE:"
   cat $ASOUND_CONF_FILE
fi

if [[ $ASOUND_CONF_EXISTS -eq 0 ]] || [[ $ASOUND_CONF_WRITABLE -eq 1 ]]; then
   if [[ -z "${card_index}" || "${card_index}" == "-1" ]] && [[ -n "${card_name}" ]]; then
      # card name is set
      echo "Specified CARD_NAME=[$card_name]"
      aplay -l | sed 1d | \
      while read i
      do
         first_word=`echo $i | cut -d " " -f 1`
         if [[ "${first_word}" == "card" ]]; then
            second_word=`echo $i | cut -d ":" -f 1`
            third_word=`echo $i | cut -d " " -f 3`
            curr_ndx=`echo $second_word | cut -d " " -f 2`
            if [[ "${third_word}" == "${CARD_NAME}" ]]; then
               echo "Found audio device [${CARD_NAME}] as index [$curr_ndx]"
               CARD_INDEX=$curr_ndx
               write_audio_config
               #break
            else
               echo "Skipping audio device [${third_word}] at index [$curr_ndx]"
            fi
         fi
      done
   elif [[ -n "${card_index}" && ! "${card_index}" == "-1" ]]; then
      # card index is set
      echo "Specified CARD_INDEX=[$card_index]"
      echo "Set card_index=[$card_index]"
      write_audio_config
   else
      echo "using sysdefault ..."
      PLAYBACK_DEVICE=sysdefault
   fi
else
   echo "File [$ASOUND_CONF_FILE] cannot be modified."
   if [[ -n "${FORCE_PLAYBACK_DEVICE}" ]]; then
      echo "Setting playback device to [$FORCE_PLAYBACK_DEVICE] ..."
      PLAYBACK_DEVICE=$FORCE_PLAYBACK_DEVICE
   fi
fi

if [[ -f "$ASOUND_CONF_FILE" ]]; then
   cat $ASOUND_CONF_FILE
else
   echo "File [$ASOUND_CONF_FILE] not found, will use default audio"
fi

echo "PLAYBACK_DEVICE=[${PLAYBACK_DEVICE}]"

echo "Starting Speaker Application in Background (TMUX)"
/usr/bin/tmux new-session -d -s speaker_controller_application '/app/ifi-tidal-release/bin/speaker_controller_application'

echo "Sleeping for a while ($SLEEP_TIME_SEC seconds)..."
sleep $SLEEP_TIME_SEC

while true
do
   echo "Starting TIDAL Connect ..."
   /app/ifi-tidal-release/bin/tidal_connect_application \
      --tc-certificate-path "/app/ifi-tidal-release/id_certificate/IfiAudio_ZenStream.dat" \
      --playback-device ${PLAYBACK_DEVICE} \
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

   if [ $RESTART_ON_FAIL -eq 1 ]; then
      echo "Sleeping $RESTART_WAIT_SEC seconds before restarting ..."
      sleep $RESTART_WAIT_SEC
   else
      echo "RESTART_ON_FAIL=$RESTART_ON_FAIL, exiting."
      break
   fi
done