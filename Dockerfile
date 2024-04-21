# syntax=docker/dockerfile:1.4
FROM node:21-alpine3.18
LABEL maintainer="Mike Glenn <mglenn@ilude.com>"

# Install necessary packages
RUN apk --no-cache add \
    bash \
    curl \  
    tor

# Configure Tor
RUN echo "SocksPort 127.0.0.1:9050" >> /etc/tor/torrc && \
    echo "HTTPTunnelPort 9080" >> /etc/tor/torrc 

# Expose Tor SOCKS proxy port
EXPOSE 9050 9080

HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
    CMD curl --silent -x socks5h://127.0.0.1:9050 'https://check.torproject.org/api/ip' | grep -qm1 -E '"IsTor"\s*:\s*true'


COPY --chmod=755 <<-"EOF" /usr/local/bin/docker-entrypoint.sh
#!/bin/bash
set -e
if [ -v DOCKER_ENTRYPOINT_DEBUG ] && [ "$DOCKER_ENTRYPOINT_DEBUG" == 1 ]; then
  set -x
  set -o xtrace
fi

# Start Tor in the background
tor  &
sleep 5

# Wait until Tor has connected to the SOCKS proxy
until curl --silent -x socks5h://127.0.0.1:9050 'https://check.torproject.org/api/ip' | grep -qm1 -E '"IsTor"\s*:\s*true'; do
    echo "Waiting for Tor to connect to the SOCKS proxy..."
    sleep 2
done

curl --silent -x socks5h://127.0.0.1:9050 'https://check.torproject.org/api/ip'
echo ""
echo "Tor is connected for user $(whoami)!"

exec "$@"
EOF

VOLUME ["/var/lib/tor"]

RUN echo "alias l='ls -lhA --color=auto --group-directories-first'" >> /etc/profile

RUN mkdir -p /app 
RUN chown -R node /app
WORKDIR /app

USER node

COPY --chown=node ./app/package.json ./
RUN npm install 

COPY --chown=node ./app ./

# Set environment variables for Node.js to use Tor SOCKS proxy
ENV SOCKS_PROXY=127.0.0.1:9050
ENV HTTP_PROXY=127.0.0.1:9080
ENV HTTPS_PROXY=127.0.0.1:9080
ENV NO_PROXY=localhost,127.0.0.1

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
CMD [ "npm", "run", "start" ]
