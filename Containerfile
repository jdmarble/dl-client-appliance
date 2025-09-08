FROM docker.io/library/caddy:2-builder AS caddy-builder
RUN xcaddy build --with github.com/caddy-dns/cloudflare

FROM quay.io/fedora/fedora-bootc:42

# Configure package manager before installing packages.
COPY /etc/dnf /etc/dnf

# Install packages in an early layer because this is mostly stable.
# cockpit: Remote management web UI
# nfs-utils: To mount the media share over NFS
RUN dnf install \
    cockpit \
    nfs-utils \
    && dnf clean all \
    && rm -rf /var/cache/yum

# Automatically update quadlet managed container images.
# Enable Caddy for reverse proxy.
# Disable SSH daemon to reduce attack surface.
# Enable Cockpit for remote management and to increase attack surface.
RUN systemctl enable podman-auto-update.timer \
    && systemctl disable sshd.service \
    && systemctl mask sshd.service \
    && systemctl enable cockpit.socket

# Can not use the caddy system package because it does not include the Cloudflare DNS plugin.
COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy

# Copy system configuration later because this is where most changes will be made.
COPY /etc/ /etc/
COPY /usr/ /usr/

RUN systemctl enable caddy.service

# https://docs.fedoraproject.org/en-US/bootc/building-containers/#_linting
RUN bootc container lint
