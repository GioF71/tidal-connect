#!/bin/bash

write_audio_config() {
   card_index=$1
   if test -f /etc/asound.conf; then
      truncate -s 0 /etc/asound.conf
   fi
   echo "Creating sound configuration file (card_index=$card_index)..."
   echo "defaults.pcm.card $card_index" >> /etc/asound.conf
   echo "pcm.!default {" >> /etc/asound.conf
   echo "  type plug" >> /etc/asound.conf
   echo "  slave.pcm hw" >> /etc/asound.conf
   echo "}" >> /etc/asound.conf
   echo "Sound configuration file created."
}

if [[ "${UPGRADE_LIBRARIES^^}" == "YES" ]]; then
   UPGRADE_FILE_NAME=/etc/upgrade-status.txt
   upgrade_status=NOT_UPGRADED
   if [ -f "$UPGRADE_FILE_NAME" ]; then
      upgrade_status=`cat $UPGRADE_FILE_NAME`
   fi
   echo "upgrade_status=[$upgrade_status]"
   if [[ ! "${upgrade_status}" == "yes" ]]; then
      echo "Upgrading libraries"
      apt-get update
      cat /etc/apt/sources.list
      echo 'deb http://archive.raspberrypi.org/debian/ stretch main' > /etc/apt/sources.list
      echo 'deb http://legacy.raspbian.org/raspbian stretch main contrib non-free rpi firmware' >> /etc/apt/sources.list
      echo 'deb-src http://legacy.raspbian.org/raspbian stretch main contrib non-free rpi firmware' >> /etc/apt/sources.list
      # Add [trusted=yes] to disable the GPG check temporarily for snapshot repositories
      sed -i 's/^deb /deb [trusted=yes] /' /etc/apt/sources.list
      sed -i 's/^deb-src /deb-src [trusted=yes] /' /etc/apt/sources.list
      apt-get -o Acquire::Check-Valid-Until=false update -y -q
      apt-get upgrade -y -q --allow-unauthenticated
      apt install --fix-missing --fix-broken -y -q multiarch-support git  libavformat57 libportaudio2* libflac++6v5* libavahi-common3 libavahi-client3 alsa-utils curl portaudio19-dev neovim zsh
      curl -k -O -L https://snapshot.debian.org/archive/debian-security/20190925T215334Z/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1%2Bdeb8u12_armhf.deb 
      apt install -y ./libssl1.0.0_1.0.1t-1%2Bdeb8u12_armhf.deb
      rm ./libssl1.0.0_1.0.1t-1%2Bdeb8u12_armhf.deb 
      curl -k -O -L https://snapshot.debian.org/archive/debian-security/20190913T112238Z/pool/updates/main/c/curl/libcurl3_7.38.0-4%2Bdeb8u16_armhf.deb
      apt install -y ./libcurl3_7.38.0-4%2Bdeb8u16_armhf.deb --allow-downgrades
      rm ./libcurl3_7.38.0-4%2Bdeb8u16_armhf.deb
      echo "yes" > $UPGRADE_FILE_NAME
   else
      echo "No upgrades to do."
   fi
fi

DEFAULT_FRIENDLY_NAME="Tidal connect"
DEFAULT_MODE_NAME="Audio Streamer"
DEFAULT_MQA_CODEC="false"
DEFAULT_MQA_PASSTHROUGH="false"

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

card_index=$CARD_INDEX
card_name=$CARD_NAME

if test -f /etc/asound.conf; then
   echo "BEFORE"
   cat /etc/asound.conf
fi

PLAYBACK_DEVICE=default
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
         card_number=`echo $second_word | cut -d " " -f 2`
         if [[ "${third_word}" == "${CARD_NAME}" ]]; then
            echo "Found audio device [${CARD_NAME}] as index [$card_number]"
            write_audio_config $card_number
            break
         fi
      fi
   done
elif [[ -n "${card_index}" && ! "${card_index}" == "-1" ]]; then
   # card index is set
   echo "Specified CARD_INDEX=[$card_index]"
   echo "Set card_index=[$card_index]"
   write_audio_config $card_index
else
   # leave default, so I delete asound.conf if found, as it is not needed
   echo "Using default audio ..."
   if [[ -f /etc/asound.conf ]]; then
      echo "Removing asound.conf ..."
      rm /etc/asound.conf
   fi
   echo "using sysdefault ..."
   PLAYBACK_DEVICE=sysdefault
   echo ". done."
fi

if [[ -f /etc/asound.conf ]]; then
   cat /etc/asound.conf
else
   echo "asound.conf not found, using default audio"
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