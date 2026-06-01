ARG ALPINE=3.20

FROM alpine:${ALPINE} AS build
RUN apk add --no-cache \
      alpine-sdk linux-headers git cmake gperf \
      zlib-dev zlib-static openssl-dev openssl-libs-static
WORKDIR /src
# Build from the in-repo source (the `td` submodule must be checked out:
# `git submodule update --init --recursive`, or CI's submodules: recursive).
COPY . .
ARG JOBS=4
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_EXE_LINKER_FLAGS="-static" \
          -DCMAKE_INSTALL_PREFIX=/out .. && \
    cmake --build . --target install -j"${JOBS}"

FROM alpine:${ALPINE}
RUN apk add --no-cache ca-certificates wget && \
    addgroup -S tba && adduser -S -G tba tba && \
    mkdir -p /var/lib/telegram-bot-api && chown tba:tba /var/lib/telegram-bot-api
COPY --from=build /out/bin/telegram-bot-api /usr/local/bin/telegram-bot-api
USER tba
EXPOSE 8081
# api-id/api-hash/dir/http-port are passed by `command:`; TG_PROXY via env.
ENTRYPOINT ["/usr/local/bin/telegram-bot-api"]
