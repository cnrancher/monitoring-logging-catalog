version: '2'
services:
  monitoring-manager:
    tty: true
    stdin_open: true
    image: {{ .Values.IMAGES_REGISTRY }}/monlog/monitoring-manager:v0.0.11
    volumes:
      - prometheus-config:/etc/prometheus
      - prometheus-rule:/etc/prometheus-rules
      - prometheus-datas:/prometheus
      - alertmanager-config:/etc/alertmanager
    environment:
      CATTLE_URL: "http://{{  .Values.RANCHER_SERVER_IP }}:{{  .Values.RANCHER_SERVER_PORT }}"
      CATTLE_ACCESS_KEY: {{  .Values.CATTLE_ACCESS_KEY }}
      CATTLE_SECRET_KEY:  {{  .Values.CATTLE_SECRET_KEY }}
      CADVISOR_PORT:  {{  .Values.CADVISOR_PORT }}
      NODE_EXPORTER_PORT: {{  .Values.NODE_EXPORTER_PORT }}
      RANCHER_EXPORTRT_PORT: {{  .Values.RANCHER_EXPORTER_PORT }}
    ports:
      - {{ .Values.MANAGER_PORT  }}:8888/tcp
    labels:
      io.rancher.monlog.affinity: monitoring-manager
    {{- if eq .Values.IMAGES_PULL_POLICY "always" }}
      io.rancher.container.pull_image: always
    {{- end }}
      io.rancher.scheduler.affinity:container_label_soft: io.rancher.monlog.affinity=prometheus,io.rancher.monlog.affinity=alertmanager

  prometheus-data:
    tty: true
    stdin_open: true
    image: {{ .Values.IMAGES_REGISTRY }}/monlog/prom-init:v0.0.1
    volumes:
      - prometheus-config:/etc/prometheus
      - prometheus-rule:/etc/prometheus-rules
      - prometheus-datas:/prometheus
    network_mode: none
    command: chmod -R 777 /prometheus /etc/prometheus /etc/prometheus-rules
    labels:
    {{- if eq .Values.IMAGES_PULL_POLICY "always" }}
      io.rancher.container.pull_image: always
    {{- end }}
      io.rancher.container.start_once: true

  prometheus:
    tty: true
    stdin_open: true
    image: {{ .Values.IMAGES_REGISTRY }}/prom/prometheus:v2.1.0
    command: --config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle --storage.tsdb.path=/prometheus
    network_mode: host
    ports:
      - 9090:9090
    labels:
      io.rancher.sidekicks: prometheus-data
      io.rancher.container.dns: 'true'
      io.rancher.monlog.affinity: prometheus
    {{- if eq .Values.IMAGES_PULL_POLICY "always" }}
      io.rancher.container.pull_image: always
    {{- end }}
      io.rancher.scheduler.affinity:container_label: io.rancher.monlog.affinity=monitoring-manager
    volumes_from:
      - prometheus-data
    extra_hosts:
      - "rancher-server:{{  .Values.RANCHER_SERVER_IP }}"
    links:
    - alertmanager:alertmanager
    - monitoring-manager:monitoring-manager

  alertmanager-data:
    tty: true
    stdin_open: true
    image: {{ .Values.IMAGES_REGISTRY }}/monlog/alertmanager-init:v0.0.1
    volumes:
      - alertmanager-config:/etc/alertmanager
      - alertmanager-template:/etc/alertmanager-templates
      - alertmanager-data:/alertmanager
    network_mode: none
    command: chmod 777 /alertmanager
    labels:
      io.rancher.container.start_once: true
    {{- if eq .Values.IMAGES_PULL_POLICY "always" }}
      io.rancher.container.pull_image: always
    {{- end }}

  alertmanager:
    tty: true
    stdin_open: true
    image: {{ .Values.IMAGES_REGISTRY }}/monlog/alertmanager:v0.14.0
    command:  --config.file=/etc/alertmanager/config.yml --storage.path=/alertmanager
    network_mode: host
    labels:
      io.rancher.sidekicks: alertmanager-data
    {{- if eq .Values.IMAGES_PULL_POLICY "always" }}
      io.rancher.container.pull_image: always
    {{- end }}
      io.rancher.monlog.affinity: alertmanager
      io.rancher.scheduler.affinity:container_label: io.rancher.monlog.affinity=monitoring-manager
    volumes_from:
      - alertmanager-data
    links:
    - monitoring-manager:monitoring-manager

  graf-db:
    tty: true
    stdin_open: true
    image: {{ .Values.IMAGES_REGISTRY }}/cnrancher/grafana-db:v0.0.9
    command: ls -all /var/lib/grafana
    volumes:
      - grafana-datas:/var/lib/grafana
    network_mode: none
    labels:
      io.rancher.container.start_once: true
    {{- if eq .Values.IMAGES_PULL_POLICY "always" }}
      io.rancher.container.pull_image: always
    {{- end }}

  graf-plugins:
    tty: true
    stdin_open: true
    image: {{ .Values.IMAGES_REGISTRY }}/maiwj/grafana-plugins:1.0.1
    volumes:
      - grafana-datas:/var/lib/grafana
    labels:
      io.rancher.container.start_once: true
    {{- if eq .Values.IMAGES_PULL_POLICY "always" }}
      io.rancher.container.pull_image: always
    {{- end }}
    network_mode: none
    environment:
      {{- if .Values.GRAFANA_CONTAINER_USER }}
      GRAFANA_CONTAINER_USER: {{ .Values.GRAFANA_CONTAINER_USER }}
      {{- end }}

  grafana:
    environment:
      {{- if .Values.GRAFANA_PLUGINS }}
      GF_INSTALL_PLUGINS: {{ .Values.GRAFANA_PLUGINS }}
      {{- end }}
      GF_USERS_DEFAULT_THEME: light
    tty: true
    stdin_open: true
    user: {{ .Values.GRAFANA_CONTAINER_USER }}
    image: {{ .Values.IMAGES_REGISTRY }}/grafana/grafana:6.5.2
    {{- if .Values.GRAFANA_MAP_PORT }}
    ports:
      - {{ .Values.GRAFANA_MAP_PORT }}:3000
    {{- end }}
    labels:
      io.rancher.sidekicks: graf-db, graf-plugins
    {{- if eq .Values.IMAGES_PULL_POLICY "always" }}
      io.rancher.container.pull_image: always
    {{- end }}
    volumes_from:
      - graf-db
      - graf-plugins
    links:
      - prometheus:prometheus
