# supg - Semtech UDP Packet Generator
# Multi-stage: builder compila, runtime solo ejecuta
# Imagen base para la compilación

FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ca-certificates file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

# pre-build.sh prepara Crypto++ con los archivos CMake necesarios
# Se usa -p y build dir "bin" como en scripts/build.sh original
RUN bash scripts/pre-build.sh \
 && mkdir -p bin && cd bin \
 && cmake -DBUILD_STATIC=OFF -DBUILD_TESTING=OFF -DUSE_INTERMEDIATE_OBJECTS_TARGET=OFF -DDISABLE_ASM=ON -DDISABLE_SSSE3=ON \
    -DDISABLE_SSE4=ON -DDISABLE_CLMUL=ON -DDISABLE_SHA=ON -DDISABLE_AVX=ON -DDISABLE_AVX2=ON -DDISABLE_ARM_NEON=ON \
    -DDISABLE_ARM_PMULL=ON -DDISABLE_ARM_SHA=ON -DDISABLE_ALTIVEC=ON -DDISABLE_POWER7=ON -DDISABLE_POWER8=ON \
    -DDISABLE_POWER9=ON .. \
 && cmake --build . -- -j$(nproc) \
 && ls -lh supg && file supg && ldd supg | head -n 20

# ---------- runtime ----------
FROM ubuntu:24.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive
# libstdc++/libgcc ya vienen en ubuntu base, solo aseguramos ca-certs para nada más
RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 libgcc-s1 libc6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/bin/supg /usr/local/bin/supg
# libcryptopp compilada localmente (shared, BUILD_STATIC=OFF)
COPY --from=builder /src/bin/modules/cryptopp/libcryptopp.so* /usr/local/lib/
RUN ldconfig && ldd /usr/local/bin/supg | head -n 20

# Config por defecto para docker: host = nombre del servicio gateway-bridge
COPY supg.docker.toml /etc/supg/supg.toml

WORKDIR /etc/supg
ENTRYPOINT ["/usr/local/bin/supg", "--config", "/etc/supg/supg.toml"]
