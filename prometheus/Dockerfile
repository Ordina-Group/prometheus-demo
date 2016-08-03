FROM prom/prometheus:0.19.2

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD prometheus.yml /etc/prometheus/prometheus.yml
RUN echo "[]" >> /etc/prometheus/target-groups.json

WORKDIR /
ENTRYPOINT /entrypoint.sh
