#
# RcloneBrowser Dockerfile - Fixed version for ARM64
#

# Builder stage
FROM --platform=$BUILDPLATFORM alpine:3.20 AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    cmake \
    git \
    qt5-qtbase-dev \
    qt5-qtmultimedia-dev \
    qt5-qttools-dev \
    wget \
    unzip \
    patch

# Clone and patch RcloneBrowser
WORKDIR /build
RUN git clone https://github.com/kapitainsky/RcloneBrowser.git && \
    cd RcloneBrowser && \
    # Patch para las APIs obsoletas
    sed -i 's/QString::SkipEmptyParts/Qt::SkipEmptyParts/g' src/main_window.cpp && \
    sed -i 's/player->start(stream, QProcess::ReadOnly);/player->start(stream, QStringList(), QProcess::ReadOnly);/g' src/main_window.cpp

# Build with disabled warnings-as-errors
RUN mkdir rclonebrowser-build && cd rclonebrowser-build && \
    cmake ../RcloneBrowser -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-declarations" && \
    cmake --build . --parallel $(nproc)

# Download rclone binary for ARM64
RUN wget -q https://downloads.rclone.org/rclone-current-linux-arm64.zip && \
    unzip rclone-current-linux-arm64.zip && \
    mv rclone-*-linux-arm64/rclone /usr/local/bin/rclone

# Runtime image
FROM jlesage/baseimage-gui:alpine-3.20-v4

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    fuse3 \
    qt5-qtbase \
    qt5-qtbase-x11 \
    libstdc++ \
    libgcc \
    dbus \
    xterm

# Copy built artifacts
COPY --from=builder /build/rclonebrowser-build/build/rclone-browser /usr/bin/
COPY --from=builder /usr/local/bin/rclone /usr/bin/

# Configure GUI
RUN sed-patch 's/<application type="normal">/<application type="normal" title="Rclone Browser">/' \
    /etc/xdg/openbox/rc.xml && \
    APP_ICON_URL=https://github.com/rclone/rclone/raw/master/graphics/logo/logo_symbol/logo_symbol_color_512px.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files
COPY rootfs/ /
COPY VERSION /

# Environment
ENV APP_NAME="RcloneBrowser" \
    S6_KILL_GRACETIME=8000

VOLUME ["/config", "/media"]

LABEL org.label-schema.name="rclonebrowser-arm64" \
      org.label-schema.description="RcloneBrowser for ARM64"
