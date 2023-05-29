#!/bin/bash

set -e

CONFIG_DIRECTORY=$HOME/.config/tidal-connect
mkdir -p $CONFIG_DIRECTORY
cp entrypoint.sh $CONFIG_DIRECTORY/
chmod 755 $CONFIG_DIRECTORY/entrypoint.sh

chmod 755 entrypoint.sh

DEFAULT_CARD_INDEX=0
DEFAULT_MQA_CODEC=false
DEFAULT_MQA_PASSTHROUGH=true

while getopts n:i:f:m:c:p: flag
do
    case "${flag}" in
        n) card_name=${OPTARG};;
        i) card_index=${OPTARG};;
        f) friendly_name=${OPTARG};;
        m) model_name=${OPTARG};;
        c) mqa_codec=${OPTARG};;
        p) mqa_passthrough=${OPTARG};;
    esac
done

echo "card_index=[$card_index]"
echo "card_name=[$card_name]"

if test -f .env; then
    truncate -s 0 .env
fi

if [[ -n ${friendly_name} ]]; then
    echo "FRIENDLY_NAME=${friendly_name}" >> .env
fi

if [[ -n ${model_name} ]]; then
    echo "MODEL_NAME=${model_name}" >> .env
fi

if [[ -n ${mqa_codec} ]]; then
    echo "MQA_CODEC=${mqa_codec}" >> .env
fi

if [[ -n ${mqa_passthrough} ]]; then
    echo "MQA_PASSTHROUGH=${mqa_passthrough}" >> .env
fi

if [[ -z "${card_index}" && -n "${card_name}" ]]; then
    echo "TODO find card_index for card_name [$card_name}]"
    max_cards=100
    for i in {0..10}
    do
        card_directory="/proc/asound/card$i"
        echo "Directory for index [$i] is [$card_directory]";
        if [ -d "$card_directory" ]; then
            echo "Directory [$card_directory] exists"
            curr_name=`cat $card_directory/id`
            echo "Card at index [$i] is [$curr_name]"
            if [ "$curr_name" == "$card_name" ]; then
                echo "Card [$card_name] found at index [$i]"
                card_index=$i
                break
            else
                echo "No card match at index [$i] for [$card_name]."
            fi
        else
            echo "No card at index [$i], bailing out."
            break
        fi
    done
elif [[ -z "${card_index}" ]]; then
    card_index=$DEFAULT_CARD_INDEX
fi

if test -f .asound.conf; then
    truncate -s 0 .asound.conf
fi

echo "defaults.pcm.card $card_index" >> ./.asound.conf
echo "defaults.ctl.card $card_index" >> ./.asound.conf
