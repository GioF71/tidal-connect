#!/bin/bash

echo "Tidal Connect - https://github.com/GioF71/tidal-connect.git - common.sh version 0.1.6"

# some constants
ASOUND_CONF_SIMPLE_FILE=asound.conf
ASOUND_CONF_FILE=/etc/$ASOUND_CONF_SIMPLE_FILE
USER_CONFIG_DIR=/userconfig

KEY_PLAYBACK_DEVICE=playback_device
KEY_FORCE_PLAYBACK_DEVICE=force_playback_device
KEY_ASOUND_CONF_EXISTS=asound_conf_exists
KEY_ASOUND_CONF_WRITABLE=asound_conf_writable

KEY_FRIENDLY_NAME=friendly_name
KEY_MODEL_NAME=model_name
KEY_MQA_CODEC=mqa_codec
KEY_MQA_PASSTHROUGH=mqa_passthrough

save_key_value() {
    V_KEY=$1
    V_VALUE=$2
    echo "${V_VALUE}" > /config/$V_KEY
}

load_key_value() {
    V_KEY=$1
    if [ -f /config/$V_KEY ]; then
        cat /config/$V_KEY
    fi
}

save_playback_device() {
    save_key_value $KEY_PLAYBACK_DEVICE $1
}

get_playback_device() {
    load_key_value $KEY_PLAYBACK_DEVICE
}

save_asound_conf_exists() {
    save_key_value $KEY_ASOUND_CONF_EXISTS $1
}

get_asound_conf_exists() {
    load_key_value $KEY_ASOUND_CONF_EXISTS
}

save_asound_conf_writable() {
    save_key_value $KEY_ASOUND_CONF_WRITABLE $1
}

get_asound_conf_writable() {
    load_key_value $KEY_ASOUND_CONF_WRITABLE
}

dump_asound() {
    # dump current asound.conf if it exists
    asound_conf_exists=`get_asound_conf_exists`
    if [ $asound_conf_exists -eq 1 ]; then
        echo "Current $ASOUND_CONF_FILE:"
        cat $ASOUND_CONF_FILE
    fi
}

dump_final_asound() {
    if [[ -f "$ASOUND_CONF_FILE" ]]; then
        cat $ASOUND_CONF_FILE
    else
        echo "File [$ASOUND_CONF_FILE] not found."
    fi
}

display_variables() {
    echo "FRIENDLY_NAME=$FRIENDLY_NAME"
    echo "MODEL_NAME=$MODEL_NAME"
    echo "MQA_CODEC=$MQA_CODEC"
    echo "MQA_PASSTHROUGH=$MQA_PASSTHROUGH"
    echo "CARD_NAME=$CARD_NAME"
    echo "CARD_INDEX=$CARD_INDEX"
    echo "CARD_DEVICE=$CARD_DEVICE"
    echo "CARD_FORMAT=$CARD_FORMAT"
    echo "CREATED_ASOUND_CARD_NAME=$CREATED_ASOUND_CARD_NAME"
    echo "ENABLE_SOFTVOLUME=$ENABLE_SOFTVOLUME"
    echo "ENABLE_GENERATED_TONE=$ENABLE_GENERATED_TONE"
    echo "ASOUND_FILE_PREFIX=$ASOUND_FILE_PREFIX"
    echo "FORCE_PLAYBACK_DEVICE=$FORCE_PLAYBACK_DEVICE"
    echo "SLEEP_TIME_SEC=$SLEEP_TIME_SEC"
    echo "RESTART_ON_FAIL=$RESTART_ON_FAIL"
    echo "RESTART_WAIT_SEC=$RESTART_WAIT_SEC"
    echo "CLIENT_ID=$CLIENT_ID"
    echo "LOG_LEVEL=$LOG_LEVEL"
}

set_defaults() {
    # we initially assume that asound.conf does not exist
    save_asound_conf_exists 0
    # we initially assume that asound.conf is writable
    save_asound_conf_writable 1
    DEFAULT_FRIENDLY_NAME="Tidal connect"
    DEFAULT_MODE_NAME="Audio Streamer"
    DEFAULT_MQA_CODEC="false"
    DEFAULT_MQA_PASSTHROUGH="false"
    if [[ -z "${FRIENDLY_NAME}" ]]; then
        FRIENDLY_NAME="${DEFAULT_FRIENDLY_NAME}"
    fi
    save_key_value $KEY_FRIENDLY_NAME "${FRIENDLY_NAME}"
    if [[ -z "${MODEL_NAME}" ]]; then
        MODEL_NAME="${DEFAULT_MODE_NAME}"
    fi
    save_key_value $KEY_MODEL_NAME "${MODEL_NAME}"
    if [[ -z "${MQA_CODEC}" ]]; then
        MQA_CODEC="${DEFAULT_MQA_CODEC}"
    fi
    save_key_value $KEY_MQA_CODEC $MQA_CODEC
    if [[ -z "${MQA_PASSTHROUGH}" ]]; then
        MQA_PASSTHROUGH="${DEFAULT_MQA_PASSTHROUGH}"
    fi
    save_key_value $KEY_MQA_PASSTHROUGH $MQA_PASSTHROUGH
    PLAYBACK_DEVICE=default
    save_playback_device $PLAYBACK_DEVICE
    if [[ -n "${FORCE_PLAYBACK_DEVICE}" ]]; then
        save_key_value $KEY_FORCE_PLAYBACK_DEVICE $FORCE_PLAYBACK_DEVICE
    fi
}

write_audio_config() {
    card_index=$1
    echo "Entering write_audio_config with card_index=[$card_index] ..."
    asound_conf_exists=`get_asound_conf_exists`
    asound_conf_writable=`get_asound_conf_writable`
    if [[ $asound_conf_exists -eq 0 ]] || [[ $asound_conf_writable -eq 1 ]]; then
        if test -f "$ASOUND_CONF_FILE"; then
            truncate -s 0 "$ASOUND_CONF_FILE"
        fi
        echo "Creating sound configuration file (card_index=[$card_index], softvol=[$ENABLE_SOFTVOLUME]) ..."
        enable_soft_volume=0
        if [[ "${ENABLE_SOFTVOLUME^^}" == "YES" || "${ENABLE_SOFTVOLUME^^}" == "Y" ]]; then
            # check there is no Master already
            check_master=`amixer -c $card_index controls | grep \'Master\'`
            if [[ -z "${check_master}" ]]; then
                echo "Ok to enable softvolume, as no 'Master' control exists for the device at index [$card_index]"
                enable_soft_volume=1
            else
                echo "check_master=[${check_master}]"
                echo "Cannot enable softvolume, a 'Master' control already exists for the device at index [$card_index]"
            fi
        elif [[ -n "${ENABLE_SOFTVOLUME}" ]] && [[ "${ENABLE_SOFTVOLUME^^}" != "NO" && "${ENABLE_SOFTVOLUME^^}" != "N" ]]; then
            echo "Invalid ENABLE_SOFTVOLUME=[${ENABLE_SOFTVOLUME}]"
            exit 1
        fi
        if [[ $enable_soft_volume -eq 0 ]]; then
            echo "Building asound.conf without softvolume ..."
            if [[ -n "${CREATED_ASOUND_CARD_NAME}" ]]; then
                echo "pcm.$CREATED_ASOUND_CARD_NAME {" >> /etc/asound.conf
                save_playback_device $CREATED_ASOUND_CARD_NAME
            else
                echo "pcm.!default {" >> /etc/asound.conf
                save_playback_device default
            fi
            echo "  type plug" >> /etc/asound.conf
            echo "  slave.pcm {" >> /etc/asound.conf
            echo "    type hw" >> /etc/asound.conf
            echo "    card ${card_index}" >> /etc/asound.conf
            if [[ -n "${CARD_DEVICE}" ]]; then
                echo "    device $CARD_DEVICE" >> /etc/asound.conf
            fi
            if [[ -n "${CARD_FORMAT}" ]]; then
                echo "    format $CARD_FORMAT" >> /etc/asound.conf
            fi
            echo "  }" >> /etc/asound.conf
            echo "}" >> /etc/asound.conf
        elif [[ $enable_soft_volume -eq 1 ]]; then
            echo "Building asound.conf with softvolume ..."
            # create plug device first
            echo "pcm.tidal-audio-device {" >> /etc/asound.conf
            echo "  type plug" >> /etc/asound.conf
            echo "  slave.pcm {" >> /etc/asound.conf
            echo "    type hw" >> /etc/asound.conf
            echo "    card ${card_index}" >> /etc/asound.conf
            if [[ -n "${CARD_DEVICE}" ]]; then
                echo "    device $CARD_DEVICE" >> /etc/asound.conf
            fi
            if [[ -n "${CARD_FORMAT}" ]]; then
                echo "    format $CARD_FORMAT" >> /etc/asound.conf
            fi
            echo "  }" >> /etc/asound.conf
            echo "}" >> /etc/asound.conf
            # add softvol device
            echo "pcm.tidal-softvol {" >> /etc/asound.conf
            echo "  type softvol" >> /etc/asound.conf
            echo "  slave {" >> /etc/asound.conf
            echo "    pcm \"tidal-audio-device\"" >> /etc/asound.conf
            echo "  }" >> /etc/asound.conf
            echo "  control {" >> /etc/asound.conf
            echo "    name \"Master\"" >> /etc/asound.conf
            echo "    card 0" >> /etc/asound.conf
            echo "  }" >> /etc/asound.conf
            echo "}" >> /etc/asound.conf
            save_playback_device tidal-softvol
            echo "Setting PLAYBACK_DEVICE=[tidal-softvol]"
        else
            echo "Invalid ENABLE_SOFTVOLUME=${ENABLE_SOFTVOLUME}"
        fi
        echo "Sound configuration file created"
    else
        echo "Cannot create file [$ASOUND_CONF_FILE]: Exists [$asound_conf_exists] Writable [$asound_conf_writable]"
    fi
    echo "Completed write_audio_config"
}

check_provided_asound() {
    ## see if there is a user-provided asound.conf file
    select_asound_file="$USER_CONFIG_DIR/$ASOUND_CONF_SIMPLE_FILE"
    if [[ -n "${ASOUND_FILE_PREFIX}" ]]; then
        select_asound_file="$USER_CONFIG_DIR/$ASOUND_FILE_PREFIX.$ASOUND_CONF_SIMPLE_FILE"
    fi
    if [ -f "$select_asound_file" ]; then
        echo "File [$select_asound_file] has been provided, copying to [$ASOUND_CONF_FILE] ..."
        cp $select_asound_file /etc/asound.conf
        # make it read-only
        chmod -w $ASOUND_CONF_FILE
        save_asound_conf_exists 1
        save_asound_conf_writable 0
        # set PLAYBACK_DEVICE to [custom] if not set
        force_playback_device=`load_key_value $KEY_FORCE_PLAYBACK_DEVICE`
        if [[ -z "${force_playback_device}" ]]; then
            echo "FORCE_PLAYBACK_DEVICE empty, setting to [custom]"
            save_key_value $KEY_FORCE_PLAYBACK_DEVICE custom
        else  
            echo "FORCE_PLAYBACK_DEVICE is already set to [$force_playback_device], leaving as-is"
        fi
    else
        echo "File [$ASOUND_CONF_SIMPLE_FILE] has not been provided"
        if [ -f "$ASOUND_CONF_FILE" ]; then
            echo "File $ASOUND_CONF_FILE exists."
            #ASOUND_CONF_EXISTS=1
            save_asound_conf_exists 1
        else
            echo "File $ASOUND_CONF_FILE does not exist."
        fi
        asound_conf_exists=`get_asound_conf_exists`
        if [ $asound_conf_exists -eq 1 ]; then
            # check if file is writable
            if [ -w "$ASOUND_CONF_FILE" ]; then
                echo "File $ASOUND_CONF_FILE is writable"
                save_asound_conf_writable 1
            else
                echo "File $ASOUND_CONF_FILE is NOT writable"
                save_asound_conf_writable 0
            fi
        fi
    fi
}

write_asound_if_needed() {
    echo "Entering write_asound_if_needed ..."
    card_index=$CARD_INDEX
    card_name=$CARD_NAME
    asound_conf_exists=`get_asound_conf_exists`
    asound_conf_writable=`get_asound_conf_writable`
    if [[ $asound_conf_exists -eq 0 ]] || [[ $asound_conf_writable -eq 1 ]]; then
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
                            write_audio_config $curr_ndx
                            break
                        else
                            echo "Skipping audio device [${third_word}] at index [$curr_ndx]"
                        fi
                    fi
                done
        elif [[ -n "${card_index}" && ! "${card_index}" == "-1" ]]; then
            # card index is set
            echo "Specified CARD_INDEX=[$card_index]"
            echo "Set card_index=[$card_index]"
            write_audio_config $card_index
        else
            echo "using sysdefault ..."
            save_playback_device sysdefault
        fi
    else
        echo "File [$ASOUND_CONF_FILE] cannot be modified."
    fi
    echo "Completed write_asound_if_needed."
}

enforce_playback_device_if_requested() {
    #echo "Entering enforce_playback_device_if_requested ..."
    force_playback_device=`load_key_value $KEY_FORCE_PLAYBACK_DEVICE`
    if [[ -n "${force_playback_device}" ]]; then
        echo "Setting playback device to [$force_playback_device] ..."
        save_playback_device $force_playback_device
    fi
    #echo "Completed enforce_playback_device_if_requested, PLAYBACK_DEVICE=[$pd_enf_ref]"
}

configure() {
    set_defaults
    display_variables
    check_provided_asound
    dump_asound
    write_asound_if_needed
    dump_final_asound
    enforce_playback_device_if_requested
}
