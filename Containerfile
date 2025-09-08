FROM ghcr.io/jdmarble/bootc-base:latest

# Enable Caddy to reverse proxy the Transmission web interface
RUN systemctl enable caddy.service

# Copy system configuration later because this is where most changes will be made.
COPY /usr/ /usr/

# https://docs.fedoraproject.org/en-US/bootc/building-containers/#_linting
RUN bootc container lint --fatal-warnings
