FROM alpine:3.8 as scratch

FROM scratch as build
LABEL author Eugene Medvedev <jidckii@gmail.com>

ARG MAKEFLAGS="-j4"
ENV NGINX_VERSION=1.13.9        \
    NGINX_RTMP_VERSION=1.2.1    \
    FFMPEG_VERSION=4.0.2

# Install dependencies.
RUN apk add --update \
  tzdata \
# Build dependencies.
  binutils \
  build-base \
  ca-certificates \
  gcc \
  libc-dev \
  libgcc \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev \
# FFmpeg dependencies.
  nasm \
  yasm-dev \
  lame-dev \
  libogg-dev \
  x264-dev \
  libvpx-dev \
  libvorbis-dev \
  x265-dev \
  freetype-dev \
  libass-dev \
  libwebp-dev \
  rtmpdump-dev \
  libtheora-dev \
  opus-dev \
  # from edge/testing
  && echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
  && apk add --update fdk-aac-dev 

# Get nginx source.
RUN cd /tmp && \
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/opt/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/opt/nginx/nginx.conf \
  --error-log-path=/opt/nginx/logs/error.log \
  --http-log-path=/opt/nginx/logs/access.log \
  --with-debug && \
  cd /tmp/nginx-${NGINX_VERSION} \
  # Compile nginx
  && make "${MAKEFLAGS}" \
  && make install

# Get FFmpeg source.
RUN cd /tmp/ && \
  wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz \
# Compile ffmpeg.
  && cd /tmp/ffmpeg-${FFMPEG_VERSION} \
  && ./configure \
  --disable-ffplay \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-librtmp \
  --enable-postproc \
  --enable-avresample \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  && make "${MAKEFLAGS}" \
  && make install \
  && make distclean

# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

EXPOSE 1935
EXPOSE 80

RUN mkdir -p /opt/data && mkdir /www

# Add NGINX config and static files.
ADD nginx.conf /opt/nginx/nginx.conf
ADD static /www/static

CMD ["/opt/nginx/sbin/nginx"]
