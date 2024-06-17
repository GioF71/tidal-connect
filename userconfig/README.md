# Samples

The files you find here are sample `asound.conf` configuration files with the hardware configurations I have run tidal-connect on, or that user have tested successfully.  
Choose one that matches your hardware (if any), or create a new one. Follow the naming style <ASOUND_FILE_PREFIX>.asound.conf, then set ASOUND_FILE_PREFIX to the relevant prefix.  
Example, in order to select a file name `topping-d10-softvol.asound.conf`, set ASOUND_FILE_PREFIX to `topping-d10-softvol`.  

## HDMI output on Raspberry Pi

I have added three presets, `hdmi-rpi`, `hdmi-rpi-44` and `hdmi-rpi-48`.  
The  `hdmi-rpi` and `hdmi-rpi-44` worked for me on my Sony tv, however I had to limit audio quality to 16bit/44.1kHz, otherwise this would fail when trying to stream hi-res content.  
Enable one of these presets by setting (e.g. for the 44.1kHz variant):

`ASOUND_FILE_PREFIX=hdmi-rpi-44`

to your `.env` file. Do not set `CARD_NAME` or `CARD_INDEX` when specifying an asound file.
