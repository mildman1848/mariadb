# syntax=docker/dockerfile:1

ARG LSIO_BASE_VERSION=3.24
FROM ghcr.io/linuxserver/baseimage-alpine:${LSIO_BASE_VERSION}

ARG LSIO_BASE_VERSION
ARG BUILD_DATE
ARG APP_VERSION=11.8.8
ARG IMAGE_REVISION=mldm2
ARG VERSION=11.8.8-mldm2
ARG VCS_REF

LABEL build_version="Mildman1848 MariaDB version:- ${VERSION} Upstream:- ${APP_VERSION} Revision:- ${IMAGE_REVISION} Build-date:- ${BUILD_DATE}" \
      maintainer="Mildman1848" \
      org.opencontainers.image.title="mariadb" \
      org.opencontainers.image.description="MariaDB packaged in a LinuxServer.io-style s6 container" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="Mildman1848" \
      org.opencontainers.image.base.name="ghcr.io/linuxserver/baseimage-alpine:${LSIO_BASE_VERSION}" \
      org.opencontainers.image.source="https://github.com/mildman1848/mariadb" \
      org.opencontainers.image.url="https://github.com/mildman1848/mariadb" \
      org.opencontainers.image.licenses="GPL-2.0-only"

ENV APP_NAME="mariadb" \
    APP_VERSION="${APP_VERSION}" \
    IMAGE_REVISION="${IMAGE_REVISION}" \
    VERSION="${VERSION}" \
    MYSQL_DIR="/config/databases" \
    MYSQL_DATABASE="app" \
    MYSQL_USER="app"

RUN \
  echo "**** install MariaDB runtime packages ****" && \
  apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    mariadb \
    mariadb-client \
    mariadb-server-utils \
    shadow \
    tzdata && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/*

COPY root/ /

EXPOSE 3306
VOLUME ["/config"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD /usr/local/bin/healthcheck || exit 1
