FROM prom/prometheus:0.19.2
MAINTAINER Tom Verelst <tom.verelst@ordina.com>

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD prometheus.yml /etc/prometheus/prometheus.yml
RUN echo "[]" >> /etc/prometheus/target-groups.json

WORKDIR /
ENTRYPOINT /entrypoint.sh
