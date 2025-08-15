# =============================================================================
# PostgreSQL Docker Image
# =============================================================================
# Multi-stage build for PostgreSQL from source with Hungarian locale support
# Base: Alpine Linux 3.22

# =============================================================================
# Build Stage
# =============================================================================
FROM alpine:3.22 AS builder

RUN apk add --no-cache \
    bison build-base flex icu-dev linux-headers openssl-dev perl pkgconfig readline-dev wget zlib-dev

COPY . /usr/src/postgresql
WORKDIR /usr/src/postgresql

RUN ./configure \
        --prefix=/usr/local/pgsql \
        --with-openssl \
        --with-icu \
        --with-readline \
    && make -j$(nproc) \
    && make install \
    && make -C contrib -j$(nproc) \
    && make -C contrib install

# =============================================================================
# Runtime Stage
# =============================================================================
FROM alpine:3.22

RUN apk add --no-cache \
    bash icu icu-libs libc6-compat musl-locales musl-locales-lang openssl readline su-exec zlib

ENV LANG=hu_HU.UTF-8 \
    LC_ALL=hu_HU.UTF-8 \
    PATH=/usr/local/pgsql/bin:$PATH \
    PGDATA=/var/lib/postgresql/data

RUN addgroup -S postgres \
    && adduser -D -S -G postgres -h /var/lib/postgresql -s /bin/bash postgres

COPY --from=builder /usr/local/pgsql /usr/local/pgsql
COPY ci/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN mkdir -p /var/lib/postgresql/data /docker-entrypoint-initdb.d && \
    chown -R postgres:postgres /var/lib/postgresql && \
    chmod 700 /var/lib/postgresql/data && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

USER postgres

EXPOSE 5432

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]