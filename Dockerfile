FROM postgres:14

COPY instantclient_19_14/ /opt/oracle/instantclient/
COPY oracle_fdw-2.4.0/ /tmp/oracle_fdw/
COPY pg_cron.sh /docker-entrypoint-initdb.d/

RUN apt-get update && \
    apt-get install -y --no-install-recommends make gcc libaio1 postgresql-server-dev-14 postgresql-14-cron && \
    echo "/opt/oracle/instantclient" > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig && \
    cd /tmp/oracle_fdw && \
    export ORACLE_HOME="/opt/oracle/instantclient" && \
    make && \
    make install && \
    apt-get autoremove -y --purge make gcc postgresql-server-dev-14 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*
