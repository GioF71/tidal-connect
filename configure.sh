#!/bin/bash

# error codes
# 1 cannot specify both index and name

set -e

ENV_FILE=.env
chmod 755 bin/entrypoint.sh

while getopts n:i:d:s:f:m:c:p:r:o:a:t:d: flag
do
    case "${flag}" in
        n) card_name=${OPTARG};;
        i) card_index=${OPTARG};;
        d) card_device=${OPTARG};;
        s) card_format=${OPTARG};;
        f) friendly_name=${OPTARG};;
        m) model_name=${OPTARG};;
        c) mqa_codec=${OPTARG};;
        p) mqa_passthrough=${OPTARG};;
        r) asound_file_prefix=${OPTARG};;
        o) force_playback_device=${OPTARG};;
        a) created_asound_card_name=${OPTARG};;
        t) sleep_time_sec=${OPTARG};;
        d) dns_server_list=${OPTARG};;

    esac
done

if [[ -n "${card_index}" && -n "${card_name}" ]]; then
    echo "Cannot specify both index and name for audio card"
    exit 1
fi

echo "card_index=[$card_index]"
echo "card_name=[$card_name]"
echo "card_device=[$card_device]"
echo "card_format=[$card_format]"
echo "asound_file_prefix=[$asound_file_prefix]"
echo "force_playback_device=[$force_playback_device]"
echo "created_asound_card_name=[$created_asound_card_name]"

if test -f $ENV_FILE; then
    truncate -s 0 $ENV_FILE
fi

if test -f $ENV_FILE; then
    truncate -s 0 $ENV_FILE
fi

if [[ -n ${friendly_name} ]]; then
    echo "Setting FRIENDLY_NAME to [$friendly_name]"
    echo "FRIENDLY_NAME=${friendly_name}" >> $ENV_FILE
else
    echo "FRIENDLY_NAME not specified"
fi

if [[ -n ${model_name} ]]; then
    echo "Setting MODEL_NAME to [$model_name]"
    echo "MODEL_NAME=${model_name}" >> $ENV_FILE
else
    echo "MODEL_NAME not specified"
fi

if [[ -n ${mqa_codec} ]]; then
    echo "Setting MQA_CODEC to [$mqa_codec]"
    echo "MQA_CODEC=${mqa_codec}" >> $ENV_FILE
else
    echo "MQA_CODEC not specified"
fi

if [[ -n ${mqa_passthrough} ]]; then
    echo "Setting MQA_PASSTHROUGH to [$mqa_passthrough]"
    echo "MQA_PASSTHROUGH=${mqa_passthrough}" >> $ENV_FILE
else
    echo "MQA_PASSTHROUGH not specified"
fi

if [[ -n ${sleep_time_sec} ]]; then
    echo "Setting SLEEP_TIME_SEC to [$sleep_time_sec]"
    echo "SLEEP_TIME_SEC=${sleep_time_sec}" >> $ENV_FILE
else
    echo "SLEEP_TIME_SEC not specified"
fi

if [[ -n ${dns_server_list} ]]; then
    echo "Setting DNS_SERVER_LIST to [$sleep_time_sec]"
    echo "DNS_SERVER_LIST=${dns_server_list}" >> $ENV_FILE
else
    echo "DNS_SERVER_LIST not specified"
fi

if [[ -n "${card_name}" ]]; then
    echo "Setting CARD_NAME to [$card_name]"
    echo "CARD_NAME=${card_name}" >> $ENV_FILE
elif [[ -n "${card_index}" ]]; then
    echo "Setting CARD_INDEX to [$card_index]"
    echo "CARD_INDEX=${card_index}" >> $ENV_FILE
    echo "CARD_NAME=NOT_SET" >> $ENV_FILE
fi

if [[ -n "${card_device}" ]]; then
    echo "Setting CARD_DEVICE to [$card_device]"
    echo "CARD_DEVICE=${card_device}" >> $ENV_FILE
fi

if [[ -n "${card_format}" ]]; then
    echo "Setting CARD_FORMAT to [$card_format]"
    echo "CARD_FORMAT=${card_format}" >> $ENV_FILE
fi

if [[ -n "${asound_file_prefix}" ]]; then
    echo "Setting ASOUND_FILE_PREFIX to [$asound_file_prefix]"
    echo "ASOUND_FILE_PREFIX=${asound_file_prefix}" >> $ENV_FILE
fi

if [[ -n "${force_playback_device}" ]]; then
    echo "Setting FORCE_PLAYBACK_DEVICE to [$force_playback_device]"
    echo "FORCE_PLAYBACK_DEVICE=${force_playback_device}" >> $ENV_FILE
fi

if [[ -n "${created_asound_card_name}" ]]; then
    echo "Setting CREATED_ASOUND_CARD_NAME to [$created_asound_card_name]"
    echo "CREATED_ASOUND_CARD_NAME=${created_asound_card_name}" >> $ENV_FILE
fi

echo -e "\nFinal .env file:\n"
cat .env

