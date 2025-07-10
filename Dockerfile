# RcloneBrowser Dockerfile (multi‑arch)
FROM jlesage/baseimage‑gui:alpine‑3.12‑glibc

# Build arguments
ARG RCLONE_VERSION=current
ARG ARCH=amd64
ARG TARGETPLATFORM
# Permite usar luego TARGETPLATFORM si es necesario (ej: lógicas condicionales)
ENV ARCH=${ARCH}

WORKDIR /tmp

# Instalación de dependencias y rclone precompilado
RUN apk --no-cache add \
      ca-certificates \
      fuse \
      wget \
      qt5-qtbase \
      qt5-qtbase-x11 \
      libstdc++ \
      libgcc \
      dbus \
      xterm && \
    cd /tmp && \
    wget -q http://downloads.rclone.org/rclone-${RCLONE_VERSION}-linux-${ARCH}.zip && \
    unzip rclone-${RCLONE_VERSION}-linux-${ARCH}.zip && \
    mv rclone-*-linux-${ARCH}/rclone /usr/bin && \
    rm -rf /tmp/rclone* && \
    apk add --no-cache --virtual=build-deps \
      build-base \
      cmake \
      make \
      gcc \
      git \
      qt5-qtbase \
      qt5-qtmultimedia-dev \
      qt5-qttools-dev

# Compila RcloneBrowser desde el repositorio
RUN git clone https://github.com/kapitainsky/RcloneBrowser.git /tmp/RcloneBrowser && \
    mkdir /tmp/RcloneBrowser/build && \
    cd /tmp/RcloneBrowser/build && \
    cmake .. && \
    cmake --build . && \
    cp build/rclone-browser /usr/bin && \
    apk del --purge build-deps && \
    rm -rf /tmp/*

# Configuración de ventana
RUN sed-patch 's/<application type="normal">/<application type="normal" title="Rclone Browser">/' \
      /etc/xdg/openbox/rc.xml

# Generación de icono de la app
RUN APP_ICON_URL=https://github.com/rclone/rclone/raw/master/graphics/logo/logo_symbol/logo_symbol_color_512px.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Archivos adicionales
COPY rootfs/ /
COPY VERSION /

# Variables de entorno
ENV APP_NAME="RcloneBrowser" \
    S6_KILL_GRACETIME=8000

# Directorios montables
VOLUME ["/config"]
VOLUME ["/media"]

# Metadata
LABEL org.label-schema.name="rclonebrowser" \
      org.label-schema.description="Docker container for RcloneBrowser" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/romancin/rclonebrowser-docker" \
      org.label-schema.schema-version="1.0"
