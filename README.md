# tidal-connect

A simple script used to configure a docker-compose stack for Tidal Connect.

## References

This entirely relies on [this](https://github.com/TonyTromp/tidal-connect-docker) repository. A big thank to the author for its great work.  
It will also use [these](https://hub.docker.com/r/edgecrush3r/tidal-connect) docker images.  
I only built this script because it was very inconvenient for me to figure out the string to put for the PLAYBACK_DEVICE variable. I even failed for one of my DAC, I don't know honestly why.  
So what this script does is create a custom asound.conf and mount it to the docker-compose.yaml file as `/etc/asound.conf`, so that the container always uses the `sysdefault` audio device.  

## Usage

From the repository directory, just run the `configure.sh` bash script, specifying the following parameters:

PARAM|DESCRIPTION
:---|:---
-i|Sound card index. If not specified and also card name isn't, it defaults to `0`
-n|Sound card name (e.g. DAC), used if card index is not specified
-f|Friendly name, defaults to `Tidal-Connect`
-m|Model name, defaults to `SBC`
-c|MQA Codec, defaults to `false`
-p|MQA Passthrough, defaults to `true`

### Example

Configure for sound card named "DAC", using friendly name "Aune S6 USB DAC" and model name "Asus Tinkerboard":

```text
./configure.sh -n DAC -f "Aune S6 USB DAC" -m "Asus Tinkerboard"
```

If no error is reported, you can run the `docker-compose.yaml` as usual:

```text
docker-compose up -d
```
