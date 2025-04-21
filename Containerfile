FROM quay.io/centos-bootc/centos-bootc:stream9

COPY /etc/dnf /etc/dnf

RUN dnf install \
      nfs-utils \
    && dnf clean all \
    && rm -rf /var/cache/yum

# Automatically update quadlet managed container images.
RUN systemctl enable podman-auto-update.timer


COPY /etc/ /etc/
COPY /usr/ /usr/
