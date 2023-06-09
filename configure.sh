#!/bin/bash

# error codes
# 1 cannot specify both index and name

set -ex

ENV_FILE=.env
chmod 755 bin/entrypoint.sh

while getopts n:i:f:m:c:p:t: flag
do
    case "${flag}" in
        n) card_name=${OPTARG};;
        i) card_index=${OPTARG};;
        f) friendly_name=${OPTARG};;
        m) model_name=${OPTARG};;
        c) mqa_codec=${OPTARG};;
        p) mqa_passthrough=${OPTARG};;
        t) sleep_time_sec=${OPTARG};;
    esac
done

if [[ -n "${card_index}" && -n "${card_name}" ]]; then
    echo "Cannot specify both index and name for audio card"
    exit 1
fi

echo "card_index=[$card_index]"
echo "card_name=[$card_name]"

if test -f $ENV_FILE; then
    truncate -s 0 $ENV_FILE
fi

if test -f $ENV_FILE; then
    truncate -s 0 $ENV_FILE
fi

if [[ -n ${friendly_name} ]]; then
    echo "FRIENDLY_NAME=${friendly_name}" >> $ENV_FILE
fi

if [[ -n ${model_name} ]]; then
    echo "MODEL_NAME=${model_name}" >> $ENV_FILE
fi

if [[ -n ${mqa_codec} ]]; then
    echo "MQA_CODEC=${mqa_codec}" >> $ENV_FILE
fi

if [[ -n ${mqa_passthrough} ]]; then
    echo "MQA_PASSTHROUGH=${mqa_passthrough}" >> $ENV_FILE
fi

if [[ -n ${sleep_time_sec} ]]; then
    echo "SLEEP_TIME_SEC=${sleep_time_sec}" >> $ENV_FILE
fi

if [[ -n "${card_name}" ]]; then
    echo "CARD_NAME=${card_name}" >> $ENV_FILE
elif [[ -n "${card_index}" ]]; then
    echo "CARD_INDEX=${card_index}" >> $ENV_FILE
    echo "CARD_NAME=NOT_SET" >> $ENV_FILE
fi
