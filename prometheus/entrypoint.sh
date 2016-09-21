/bin/prometheus \
  -config.file=/etc/prometheus/prometheus.yml \
  -storage.local.path=/prometheus \
  -web.console.libraries=/etc/prometheus/console_libraries \
  -web.console.templates=/etc/prometheus/consoles \
  -alertmanager.url=http://alertmanager:9093
