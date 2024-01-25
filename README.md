# tidal-connect

A simple script used to configure a docker-compose stack for Tidal Connect.

## Disclaimers

### Contents

This repository does not contain the Tidal Connect software. There is only a docker-compose.yaml file, a configurator script, and a modified entrypoint which is just used for selecting the desired audio output more easily and reliably.   

### Credit

All the hard work has been done by the owner of the repository mentioned in the [References](#References) section and in the other repositories from which this one has been forked. I am just trying to provide a way to run their container more easily in certain environments (where the index of your audio device is not the same on every restart).  

### No support from Tidal

This solution is not and will probably never be supported by Tidal. It might stop working at any time.  
If you need to have a supported solution, look at Tidal Connect enabled products. A cheap one is the ubiquitous Wiim Mini/Pro/Pro+/Amp. Another option are Google Chromecast/Chromecast Audio devices. Also, if you use Apple devices, you can already stream to AirPlay-enabled devices.   
Even your current TV might already be used as an endpoint for Tidal via the embedded Chromecast functionality, or via AirPlay.  
Alternatively, if you are not scared of some DIY, you might want to create an upnp/dlna renderer, maybe with upmpdcli (you might use my [docker image for upmpdcli](https://github.com/GioF71/upmpdcli-docker)) and mpd (you might use my [docker image for mpd](https://github.com/GioF71/mpd-alsa-docker)), and then use some Android app like BubbleUpnp or mConnect Lite (this one is also on iOS/iPadOS), connect those apps to Tidal and then stream to your upnp/dlna renderer.  
Starting late November 2023, BubbleUpnp supports hires flac, see [this post on Reddit](https://www.reddit.com/r/TIdaL/comments/184gcsq/bubbleupnp_android_app_now_supports_hires_flac/). This is something that, from what I know, is not supported by this Tidal Connect application, and will probably never be.  
Another solution might be my [Tidal Plugin for Upmpdcli](https://github.com/GioF71/upmpdcli-docker/discussions/281) but again, there will be no support from Tidal. This solution works well with Tidal HiFi or with HiFi+ with MQA DACs, but currently does not support native HiRes flac.  

## References

This entirely relies on [this](https://github.com/TonyTromp/tidal-connect-docker) repository from [GitHub user TonyTrump](https://github.com/TonyTromp). A big thank you to the author for the great work.  
It will also use [his docker image](https://hub.docker.com/r/edgecrush3r/tidal-connect).  

## Why

I created this repository because it was very inconvenient for me to figure out the string to put for the PLAYBACK_DEVICE variable. I even failed for one of my DAC, I don't know honestly why, but as far as I understand, the `ifi-pa-devs-get` for some reason refuses to see the device. The most relevant issue I found about this issue is [this](https://github.com/TonyTromp/tidal-connect-docker/issues/23), but it does not seems to have an easy solution.   
Additionally, even if you can specify the correct string for your DAC, I found that the resulting configuration would be error-prone as the string reports both the device name and the device index. AFAIK the index can change across restarts, so outside of a known and controlled setup (which is probably represented by the Ifi devices) this situation can an will lead to errors or unwanted configurations.  
Keep in mind that the audio device index can also be changed because one time the (usb) device is powered on during boot, and another time it isn't.  
This is my experience, unless I am missing something obvious. If so, I will be glad to be corrected.  
The work in this repository consists in slightly altering the container startup phase (the `entrypoint.sh` file), in such a way that a custom `/etc/asound.conf` is created with (hopefully) the correct device index, regardless of the order of the audio devices, which can vary across restarts. The underlying application then always uses the `default` audio device.  

## Requirements

You will need a single-board computer (or anyway, a computer) with an armhf architecture (arm64 should work as well), running `docker` and `docker-compose`.  
A Raspberry Pi 3/4 will work. If you plan to use a usb dac and hi-res audio, consider at least using a Pi 3b+ or, even better, a Pi 4b.   
I am also running this on as Asus Tinkerboard. With this hardware, my suggestion is to not allow it to scale down the cpu frequency too much, or you might experience every kind of crackling noises along with what will remain of your music. In my experience, I am having good result if I set the minimum frequency at least about 600MHz, but, of course, YMMV.  

## Usage

### Install Docker

Docker is a prerequisite. On debian and derived distributions (this includes Raspberry Pi OS, DietPi, Moode Audio, Volumio), we can install the necessary packages using the following commands:

```text
sudo apt-get update
sudo apt-get install docker.io docker-compose
sudo usermod -a -G docker $USER
```

The last command adds the current user to the docker group. This is not mandatory; if you choose to skip this step, you might need to execute docker-compose commands by prepending `sudo`.  

### Clone the repository

You need to clone the repository. Make sure that `git` is installed using the following command on debian and derived distributions (again, this includes Raspberry Pi OS, DietPi, Moode Audio, Volumio):

```
sudo apt-get update
sudo apt-get install -y git
```

Move to the your home directory and clone the repository using the commands:

```
cd
git clone https://github.com/GioF71/tidal-connect.git
```

### Update the repository

If you just downloaded the repository, you can skip this step.  
If you previously cloned the repository, it might have been updated in the meantime. Move to the directory and pull the changes:

```
cd $HOME/tidal-connect
git pull
```

### Configure

From the repository directory, just run the `configure.sh` bash script, specifying the following parameters:

PARAM|DESCRIPTION
:---|:---
-n|Sound card name (e.g. DAC), if not specified and also card index isn't, `sysdefault` is used.
-i|Sound card index, not recommended: if not specified and also card name isn't, `sysdefault` is used.
-d|Sound card device, optional
-f|Friendly name, defaults to `TIDAL connect`
-m|Model name, defaults to `Audio Streamer`
-s|Card format, optional (`S32_LE`, `S16_LE`, etc)
-c|MQA Codec, defaults to `false`
-p|MQA Passthrough, defaults to `false`
-t|Sleep time in seconds be, defaults to `3`
-d|DNS Server list, defaults to `8.8.8.8 8.8.4.4` (Google's DNS servers)

I recommend to use the `-n` parameter instead of `-i`, because the index of the devices might change across restarts.  
If you already used the `configure.sh` command and you are experiencing issues (because of the card has changed its index), you can run the command again. In the latest version, the card index is calculated during the container startup phase and hopefully there will not be any need to use `configure.sh` again unless you change the audio device you want to use.

#### Example

Configure for sound card named "DAC", using friendly name "Aune S6 USB DAC" and model name "Asus Tinkerboard":

```text
cd $HOME/tidal-connect
bash configure.sh -n DAC -f "Aune S6 USB DAC" -m "Asus Tinkerboard"
```

If no error is reported, you will find a new (or updated) `.env` file.  
If you find a spurious `.asound.conf` file there, it probably was generated by a previous version of the `configure.sh` script, and you can safely delete it.  
So now you can run the `docker-compose.yaml` as usual:

```text
cd $HOME/tidal-connect
docker-compose up -d
```

## Environment Variables

The container can be entirely configured using the environment variables listed on the following table:

VARIABLE|DESCRIPTION
:---|:---
CARD_NAME|Alsa name of the audio card. Example for xmos dac might be `DAC` while e.g. it is `D10` for a Topping D10
CARD_INDEX|Alsa index of the audio card
CARD_DEVICE|Audio device, optional
CARD_FORMAT|Audio format, optional (`S32_LE`, `S16_LE`, etc)
FRIENDLY_NAME|Friendly name of the device, will be shown on Tidal Apps. Defaults to `TIDAL connect`.
MODEL_NAME|Model name of the device. Defaults to `Audio Streamer`.
MQA_CODEC|Can't comment a lot on this, defaults to `false`.
MQA_PASSTHROUGH|Can't comment a lot on this, defaults to `false`.
SLEEP_TIME_SEC|Sleep time before starting the real app, after starting tmux. Defaults to `3`.
RESTART_ON_FAIL|Enables auto restart (see issue [#16](https://github.com/GioF71/tidal-connect/issues/16)), defaults to `1` (which means restart is enabled).
RESTART_WAIT_SEC|Wait time in seconds before trying restart (see RESTART_ON_FAIL), defaults to 30.
DNS_SERVER_LIST|The DNS serves to be used, defaults to `8.8.8.8 8.8.4.4` (Google's DNS servers).

Please not that if both CARD_NAME and CARD_INDEX are specified, only CARD_NAME will be considered.  
Also, if both CARD_NAME and CARD_INDEX are not specified, `sysdefault` (the system default audio device) will be used.  

## Installation on Moode Audio or Volumio

It is possible to use this solution for easy installation of Tidal Connect on [Moode Audio](https://moodeaudio.org/) and [Volumio](https://volumio.com/).  
It is required to have a ssh connection to the Moode/Volumio audio box. In order to enable ssh on Volumio, refer to [this](https://developers.volumio.com/SSH%20Connection) page.  
Those two platforms do not ship docker out of the box (unsurprisingly), so docker installation is required. See [Docker Installation](#install-docker) earlier in this page.  

### Configure Audio

If you have just installed docker with the previous commands, it is probably a good idea to logoff your current ssh session, then log back in. Otherwise, just open a ssh connection to your box.  
We need to configure the audio output you want to use for Tidal Connect.  
If your device only has one output, or if that output is also configured as the default output, no configuration might be needed other than the Friendly and Model name.  

#### Single audio device

On one of my boxes, I have a Hifiberry Dac+ Pro Hat, so when I use the command:

```text
cat /proc/asound/cards
```

I get:

```text
pi@moode-living:~/git/tidal-connect $ cat /proc/asound/cards
 0 [sndrpihifiberry]: HifiberryDacp - snd_rpi_hifiberry_dacplus
                      snd_rpi_hifiberry_dacplus
```

Great, the operating system has just disabled the onboard audio and set the Hifiberry HAT as the default card.  
So let's configure Tidal Connect:

```text
cd $HOME/tidal-connect
./configure.sh -f "Living Aux1" -m "Raspberry Pi"
```

We are not specifying anything (not the card index and neither the name) because there is only one output available.  
Replace the first and second strings to your liking. Once configured, start the service as usual:

```text
cd $HOME/tidal-connect
docker-compose up -d
```

#### Multiple audio devices

On another one of my boxes, I have an usb dac connected, so when I use the command:

```text
cat /proc/asound/cards
```

I get:

```text
moode@moode:~ $ cat /proc/asound/cards
 0 [b1             ]: bcm2835_hdmi - bcm2835 HDMI 1
                      bcm2835 HDMI 1
 1 [Headphones     ]: bcm2835_headpho - bcm2835 Headphones
                      bcm2835 Headphones
 2 [X20            ]: USB-Audio - XMOS USB Audio 2.0
                      XMOS XMOS USB Audio 2.0 at usb-0000:01:00.0-1.2, high speed
```

So in this setup, the operating system has not disabled the onboard audio. Even if you have configured Moode so that is will use the USB DAC, this might not be enough for Tidal Connect to automatically select that card.  
The safest way (at least IMO) is to use the string that identifies the dac as card name:
So let's configure Tidal Connect:

```text
cd $HOME/tidal-connect
./configure.sh -n "X20" -f "Desktop" -m "Raspberry Pi"
```

Replace the second and third strings to your liking. Once configured, start the service as usual:

```text
cd $HOME/tidal-connect
docker-compose up -d
```

### Caveat

#### Hardware changes

Remember that, should you change something to your Moode/Volumio setup, maybe replacing the audio-hat with an USB DAC, you will most likely need to reconfigure Tidal Connect accordingly.  

#### Volumio integration

Please be aware that this solution will not be completely equivalent to the built-in premium feature of Volumio. That solution (probably) allows the attached (touch) display to show the currently playing song, while this solution for sure does not allow that or any other related features.

#### Mandatory IPV6 support

Tidal connect won't work if your system does not support ipv6. See [this](https://github.com/GioF71/tidal-connect/issues/21) issue.  
Afaik, there is no solution or workaround available other than, somehow, enabling ipv6.

#### DietPi

On DietPi (which I am running on my Asus Tinkerboard), you might need to enable avahi-daemon, if this is not enabled yet.  
You might find the following on the logs:

```text
[tisoc] [error] [avahiImpl.cpp:358] avahi_client_new() FAILED: Daemon not running
```

This can be fixed by installing the avahi-daemon. It is not installed by default on DietPi, so we can installing it with this command:  

```text
sudo apt-get install avahi-daemon
```

An already started tidal-connect container should start working immediately, at least that is what happened with my setup.

## Change History

Date|Comment
:---|:---
2024-01-25|Revert latest change, see ([#78](https://github.com/GioF71/tidal-connect/issues/78))
2024-01-24|Always create sysdefault in asound.conf and log device names, see [#76](https://github.com/GioF71/tidal-connect/issues/76)
2024-01-23|Add support for optional card device (`CARD_DEVICE`) and format (`CARD_FORMAT`), see [#72](https://github.com/GioF71/tidal-connect/issues/72)
2023-09-12|Clarify how to install on Volumio, see issue [#29](https://github.com/GioF71/tidal-connect/issues/29)
2023-09-04|Allow default audio card selection, see issue [#22](https://github.com/GioF71/tidal-connect/issues/22)
2023-07-18|Allow user-specified dns server(s), see issue [#13](https://github.com/GioF71/tidal-connect/issues/13)
2023-07-07|Fixed asound.conf generation from card index, see issue [#2](https://github.com/GioF71/tidal-connect/issues/2)
2023-06-02|First unfolding seems to be working
2023-06-02|Some effort to avoid resampling
2023-06-02|MQA passthrough defaults to `false`
2023-06-01|Using hardware mode
2023-06-01|Resolve device name at container startup 
2023-05-29|First working version
