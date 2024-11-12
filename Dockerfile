FROM ubuntu:xenial

RUN apt-get update

RUN apt-get -y install make automake libtool pkg-config libaio-dev git libmysqlclient-dev libssl-dev libpq-dev ca-certificates mysql-client

RUN git clone https://github.com/akopytov/sysbench.git sysbench

WORKDIR sysbench
RUN ./autogen.sh
RUN ./configure --with-mysql --with-pgsql
RUN make -j
RUN make install

WORKDIR /root
RUN rm -rf sysbench

# Download and install RDS CA bundle from https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
ADD \
  --checksum=sha256:390fdc813e2e58ec5a0def8ce6422b83d75032899167052ab981d8e1b3b14ff2 \
  --chmod=0644 \
  https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
  /tmp/ca-certificates/aws-rds-global-bundle.crt
RUN \
  cd /tmp/ && \
  csplit --quiet --prefix rds-ca-cert- --suffix-format=%02d.crt --elide-empty-files /tmp/ca-certificates/aws-rds-global-bundle.crt '/-----BEGIN CERTIFICATE-----/' '{*}' && \
  mv rds-ca-cert-* /usr/local/share/ca-certificates/ && \
  update-ca-certificates --fresh --verbose

ENTRYPOINT sysbench
