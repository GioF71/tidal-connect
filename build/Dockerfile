FROM debian:bookworm-slim

RUN apt-get update

RUN apt-get install -y ca-certificates
RUN apt-get install -y libportaudio-ocaml
RUN apt-get install -y libavahi-client3
RUN apt-get install -y alsa-utils
RUN apt-get install -y libssl-dev
RUN apt-get install -y libcurl4
RUN apt-get install -y libavformat-dev

# we might create a smaller image by:
# - removing apt cache
# - using multistage build with the scratch image
# - copying contents from the base image to the scratch image
# 
# but this would result in slower build times, so at the moment,
# I believe it's not worth it. YMMV

ENTRYPOINT ["/entrypoint.sh"]
