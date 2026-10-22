ARG BASE_IMAGE
ARG LIVE_BOOTSTRAP_IMAGE=runtime
FROM ${BASE_IMAGE} AS runtime
ARG NOVA_VERSION=0.2.1-preview
COPY system/ /
COPY build/install/ /
RUN --mount=type=cache,target=/var/cache/libdnf5 \
    chmod 0755 /usr/libexec/nova-image/*.sh /usr/libexec/nova-update-helper /usr/libexec/nova-configure-flathub /usr/bin/nova-run-exe /usr/bin/nova-launch-store-app && \
    /usr/libexec/nova-image/configure-runtime.sh "${NOVA_VERSION}" && bootc container lint
LABEL org.opencontainers.image.source="https://github.com/dennics/NOVA-OS" \
      org.opencontainers.image.title="NOVA OS" \
      org.opencontainers.image.description="Fedora Kinoite based NOVA OS development preview" \
      org.opencontainers.image.version="${NOVA_VERSION}"

FROM ${LIVE_BOOTSTRAP_IMAGE} AS live
ARG NOVA_VERSION=0.2.1-preview
COPY system/ /
COPY build/install/ /
COPY installer/ /
RUN --mount=type=cache,target=/var/cache/libdnf5 \
    chmod 0755 /usr/libexec/nova-image/*.sh /usr/libexec/nova-update-helper /usr/libexec/nova-configure-flathub /usr/bin/nova-run-exe /usr/bin/nova-launch-store-app /usr/bin/nova-install /usr/local/bin/bootc && \
    install -m 0755 /usr/bin/bootc /usr/libexec/nova-bootc-real && \
    rm -f /usr/bin/bootc && ln -s /usr/local/bin/bootc /usr/bin/bootc && \
    /usr/libexec/nova-image/configure-runtime.sh "${NOVA_VERSION}" && \
    /usr/libexec/nova-image/configure-live.sh "${NOVA_VERSION}"

