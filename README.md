# tidal-connect

A simple script used to configure a docker-compose stack for Tidal Connect.

## Disclaimer

All the hard work has been done by the people who own the repositories mentioned [here](#References). I am just trying to provide a way to run their container more easily in certain environments (where the index of your audio device is not the same on every restart).  

## References

This entirely relies on [this](https://github.com/TonyTromp/tidal-connect-docker) repository. A big thank you to the author for its great work.  
It will also use [these](https://hub.docker.com/r/edgecrush3r/tidal-connect) docker images.  

## Why

I created this repository because it was very inconvenient for me to figure out the string to put for the PLAYBACK_DEVICE variable. I even failed for one of my DAC, I don't know honestly why.  
And, in any case, I found that the resulting  configuration would be error-prone as the string reports both the device name and the device index. AFAIK the index can change across restarts, so outside of a known and controlled setup (which is probably represented by the Ifi devices) this situation can an will lead to errors or unwanted configurations.  
Keep in mind that the audio device index can also be changed because one time the (usb) device is powered on during boot, and another time it isn't.  
This is my experience, unless I am missing something obvious. If so, I will be glad to be corrected.  
The work in this repository consists in slightly altering the container startup phase (the `entrypoint.sh` file), in such a way that a custom `/etc/asound.conf` is created with (hopefully) the correct device index, regardless of the order of the audio devices, which can vary across restarts. The underlying application then always uses the `sysdefault` audio device.  

## Requirements

You will need a single-board computer (or anyway, a computer) with an armhf architecture (arm64 should work as well), running `docker` and `docker-compose`.  
A Raspberry Pi 3/4 will work. I am also running this on as Asus Tinkerboard. With this hardware, my suggestion is to not allow it to scale down the cpu frequency too much, or you might experience every kind of crackling noises along with what will remain of your music.  

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
-t|Sleep time in seconds be, defaults to `3`

I recommend to use the `-n` parameter instead of `-i`, because the index of the devices might change across restarts.  
If you already used the `configure.sh` command and you are experiencing issues (because of the card has changed its index), you can run the command again. In the latest version, the card index is calculated during the container startup phase and hopefully there will not be any need to use `configure.sh` again unless you change the audio device you want to use.

### Example

Configure for sound card named "DAC", using friendly name "Aune S6 USB DAC" and model name "Asus Tinkerboard":

```text
bash configure.sh -n DAC -f "Aune S6 USB DAC" -m "Asus Tinkerboard"
```

If no error is reported, you will find new (or updated) `.env` files.  
If you find a spurious `.asound.conf` file there, it probably was generate with a previous version of the `configure.sh` script, and you can safely delete it.  
So now you can run the `docker-compose.yaml` as usual:

```text
docker-compose up -d
```
