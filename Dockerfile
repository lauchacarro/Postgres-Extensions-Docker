# Base image for PostgreSQL
ARG PG_MAJOR=17
FROM postgres:$PG_MAJOR

# Metadata
LABEL maintainer="Lautaro Carro <hello@lautarocarro.com>" \
      description="PostgreSQL with PostGIS and PGVector extensions" \
      org.opencontainers.image.source="https://github.com/lauchacarro/Postgres-Extensions-Docker"

# Environment variables
ENV POSTGIS_MAJOR=3 \
    POSTGIS_VERSION=3.5.1+dfsg-1.pgdg110+1 \
    PGVECTOR_REPO=/tmp/pgvector

# Update system and install common dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        postgresql-server-dev-$PG_MAJOR && \
    rm -rf /var/lib/apt/lists/*

# --- Install PostGIS ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
        postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts && \
    rm -rf /var/lib/apt/lists/*

# --- Install PGVector ---
RUN git clone https://github.com/pgvector/pgvector.git $PGVECTOR_REPO && \
    cd $PGVECTOR_REPO && \
    make clean && \
    make OPTFLAGS="" && \
    make install && \
    # Cleanup PGVector installation files
    rm -rf $PGVECTOR_REPO && \
    apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Prepare init scripts for extensions
RUN mkdir -p /docker-entrypoint-initdb.d

# Copy initialization scripts
COPY ./scripts/init-postgis.sh /docker-entrypoint-initdb.d/10_init_postgis.sh
COPY ./scripts/init-pgvector.sh /docker-entrypoint-initdb.d/20_init_pgvector.sh
COPY ./scripts/update-extensions.sh /usr/local/bin

# Custom permissions
RUN chmod +x /docker-entrypoint-initdb.d/*.sh /usr/local/bin/update-extensions.sh

# Expose PostgreSQL default port
EXPOSE 5432

CMD ["postgres"]
