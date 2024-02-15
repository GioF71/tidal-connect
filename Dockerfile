FROM edgecrush3r/tidal-connect:latest

RUN mkdir -p /assets
COPY assets/curl-armv7 /assets/
RUN mv curl-armv7 /usr/bin/curl
RUN chmod +x /usr/bin/curl

ENTRYPOINT ["/entrypoint.sh"]