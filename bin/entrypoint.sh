#!/bin/bash

echo "Tidal Connect - https://github.com/GioF71/tidal-connect.git - entrypoint.sh version 0.2.0"

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
    tmux_available=0
    control_app_available=0
    if [ -f /usr/bin/tmux ]; then
        tmux_available=1
    fi
    if [ -f /app/ifi-tidal-release/bin/speaker_controller_application ]; then
        control_app_available=1
    fi

    if [ $tmux_available -eq 1 ] && [ $control_app_available -eq 1 ]; then
        echo "Starting Speaker Application in Background (TMUX)"
        /usr/bin/tmux new-session -d -s speaker_controller_application '/app/ifi-tidal-release/bin/speaker_controller_application'
        echo "Sleeping for a while ($SLEEP_TIME_SEC seconds) ..."
        sleep $SLEEP_TIME_SEC
    else
        if [ $tmux_available -eq 0 ]; then
            echo "The tmux binary is not available."
        fi
        if [ $control_app_available -eq 0 ]; then
            echo "The Control application is not available."
        fi
        echo "The Control application or the tmux binary are not available, so we cannot start the control application."
    fi
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

if [ -f "/assets/custom/bin/tidal_connect" ]; then
    echo "User provided tidal_connect app found."
    # copy
    mkdir -p /app/bin
    cp /assets/custom/bin/tidal_connect /app/bin
    # change permissions
    chmod +x /app/bin/tidal_connect
    # adopt this version
    executable_path=/app/bin/tidal_connect
    if [ -f "/assets/custom/bin/tidal_connect.dat" ]; then
        echo "User provided tidal_connect.dat file found."
        mkdir -p /app/bin
        cp /assets/custom/bin/tidal_connect.dat /app/bin
        certificate_path=/app/bin/tidal_connect.dat
    else
        echo "An user provided tidal_connect.dat file was not found."
    fi
else
    echo "An user provided tidal_connect app was not found."
    # is there the fallback application in the image?
    if [ ! -f "$executable_path" ]; then
        echo "Cannot find fallback executable [$executable_path], this is a fatal error!"
        exit 1
    fi
fi

# is there a custom certificate?
if [ -f "/assets/custom/certificate/tcon.crt" ]; then
    echo "User provided tcon.crt found."
    mkdir -p /app/cert
    cp /assets/custom/certificate/tcon.crt /app/cert
    chown root:root /app/cert/tcon.crt
    certificate_path=/app/cert/tcon.crt
else
    echo "An user provided tcon.crt was not found."
fi

# has the certificate path been explicitly set? if so, we use that value
if [[ -n "${CERTIFICATE_PATH}" ]]; then
   certificate_path=${CERTIFICATE_PATH}
fi
echo "certificate_path=[${certificate_path}]"

if test -d /assets/custom/lib; then
    lib_cnt=`find /assets/custom/lib -type f | grep -v ".placeholder" | wc -l`
    echo "Lib count in /assets/custom/lib: $lib_cnt"
    if [ $lib_cnt -eq 0 ]; then
        echo "No custom libraries to inject to /usr/lib/ ..."
    else
        echo "Some custom libraries to inject to /usr/lib/ ..."
        for lib_name in /assets/custom/lib/*; do
            echo "Found library path [$lib_name], injecting to /usr/lib/ ..."
            cp $lib_name /usr/lib/
        done
    fi
else
    echo "Custom lib directory not found."
fi

if test -d /assets/custom/lib-arm-linux-gnueabihf; then
    lib_cnt=`find /assets/custom/lib-arm-linux-gnueabihf -type f | grep -v ".placeholder" | wc -l`
    echo "Lib count in /assets/custom/lib-arm-linux-gnueabihf: $lib_cnt"
    if [ $lib_cnt -eq 0 ]; then
        echo "No custom libraries to inject to /lib/arm-linux-gnueabihf/ ..."
    else
        echo "Some custom libraries to inject to /lib/arm-linux-gnueabihf/ ..."
        for lib_name in /assets/custom/lib-arm-linux-gnueabihf/*; do
            echo "Found library [$lib_name], injecting to /lib/arm-linux-gnueabihf/..."
            cp $lib_name /lib/arm-linux-gnueabihf/
        done
    fi
else
    echo "Custom arm-linux-gnueabihf directory not found."
fi

disable_app_security=false
disable_web_security=true

if [[ -n "${DISABLE_APP_SECURITY}" ]]; then
    if [[ "${DISABLE_APP_SECURITY}" == "false" ]] || [[ "${DISABLE_APP_SECURITY}" == "true" ]]; then
        disable_app_security=${DISABLE_APP_SECURITY}
        echo "DISABLE_APP_SECURITY=[${DISABLE_APP_SECURITY}]"
    else
        echo "Invalid value for DISABLE_APP_SECURITY=[${DISABLE_APP_SECURITY}]"
        exit 1
    fi
fi

if [[ -n "${DISABLE_WEB_SECURITY}" ]]; then
    if [[ "${DISABLE_WEB_SECURITY}" == "false" ]] || [[ "${DISABLE_WEB_SECURITY}" == "true" ]]; then
        disable_web_security=${DISABLE_WEB_SECURITY}
        echo "DISABLE_WEB_SECURITY=[${DISABLE_WEB_SECURITY}]"
    else
        echo "Invalid value for DISABLE_WEB_SECURITY=[${DISABLE_WEB_SECURITY}]"
        exit 1
    fi
fi

COMMAND_LINE="${executable_path} \
         --tc-certificate-path ${certificate_path} \
         --playback-device ${PLAYBACK_DEVICE} \
         -f \"${friendly_name}\" \
         --model-name \"${model_name}\" \
         --codec-mpegh true \
         --codec-mqa ${mqa_codec} \
         --disable-app-security ${disable_app_security} \
         --disable-web-security ${disable_web_security} \
         --enable-mqa-passthrough ${mqa_passthrough} \
         --log-level ${LOG_LEVEL} \
         --enable-websocket-log \"0\""

if [[ -n "${CLIENT_ID}" ]]; then
    echo "Using user provided CLIENT_ID [${CLIENT_ID}]"
    COMMAND_LINE="${COMMAND_LINE} --clientid \"${CLIENT_ID}\""
else
    echo "User did not provide a CLIENT_ID."
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