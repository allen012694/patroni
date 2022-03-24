FROM postgres:12

ARG MASTER_PG_HOST
ARG REPLICA_PG_HOST
# ARG ETCD_HOSTS
ARG CONSUL_HOST

ENV PGHOME=/home/postgres
ENV PGDATA=$PGHOME/data
ENV PGCONFIG=$PGHOME/config

# prepare python
RUN apt-get update && apt-get install -y python3-pip python3-psycopg2 python3-dev g++ curl gosu && \
  ln -sf /usr/bin/python3 /usr/bin/python && \
  python3 -m pip install --upgrade pip setuptools && \
  python3 -m pip install pyyaml python-dateutil pytz requests python-consul click tzlocal prettytable psutil cdiff kazoo

# # prepare patroni
# RUN cd /tmp && curl -OL https://github.com/zalando/patroni/archive/v${PATRONI_VERSION}.tar.gz && \
#   tar -xzf v${PATRONI_VERSION}.tar.gz && \
#   mv patroni-${PATRONI_VERSION}/patroni /patroni && \
#   mv patroni-${PATRONI_VERSION}/patroni.py / && \
#   mv patroni-${PATRONI_VERSION}/patronictl.py / && \
#   ln -s /patronictl.py /usr/local/bin/patronictl && \
#   rm -rf /tmp/patroni-* /tmp/*.tar.gz  && \
#   rm -rf /root/.cache /usr/lib/python3*/__pycache && \
#   apt-get remove -y g++ curl python3-dev && apt-get autoremove -y && apt-get purge && cd ..



# prepare patroni
RUN python3 -m pip install psycopg2-binary python-etcd wheel patroni
COPY patroni.yml /config/
# adjust patroni config
RUN sed -i 's|\$MASTER_PG_HOST|'${MASTER_PG_HOST}'|g' /config/patroni.yml && \
    sed -i 's|\$REPLICA_PG_HOST|'${REPLICA_PG_HOST}'|g' /config/patroni.yml && \
    sed -i 's|\$CONSUL_HOST|'${CONSUL_HOST}'|g' /config/patroni.yml && \
    sed -i 's|\$PGCONFIG|'${PGCONFIG}'|g' /config/patroni.yml && \
    sed -i 's|\$PGDATA|'${PGDATA}'|g' /config/patroni.yml
# sed -i s/\$ETCD_HOSTS/${ETCD_HOSTS}/g /config/patroni.yml

# init some dir
RUN mkdir -p ${PGHOME} ${PGDATA} ${PGCONFIG} && \
  chown -R postgres:postgres ${PGHOME} ${PGDATA} && \
  chmod -R 777 ${PGHOME} ${PGDATA}

USER postgres

ENTRYPOINT ["patroni", "/config/patroni.yml"]
