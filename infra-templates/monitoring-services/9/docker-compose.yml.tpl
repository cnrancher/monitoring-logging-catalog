version: '2'
services:
  cadvisor:
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.global: 'true'
    tty: true
    image: {{  .Values.CADVISOR_IMAGES }}
    privileged: true
    environment:
        - CADVISOR_PORT={{  .Values.CADVISOR_PORT }}
    stdin_open: true
    volumes:
    - "/:/rootfs:ro"
    - "/var/run:/var/run:rw"
    - "/sys:/sys:ro"
    - "/var/lib/docker/:/var/lib/docker:ro"
    command: {{  .Values.CADVISOR_ARG }}
    network_mode: bridge
    ports:
    - {{  .Values.CADVISOR_PORT }}:{{  .Values.CADVISOR_PORT }}

  node-exporter:
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.global: 'true'
    tty: true
    image: {{  .Values.NODE_EXPORTER_IMAGES }}
    stdin_open: true
    command: --web.listen-address=":{{  .Values.NODE_EXPORTER_PORT }}"
    network_mode: host

  rancher-health-exporter:
    tty: true
    labels:
      io.rancher.container.pull_image: always
      io.rancher.container.create_agent: 'true'
      io.rancher.container.agent.role: environment
    image: {{  .Values.RANCHER_HEALTH_EXPORTER_IMAGES }}
    ports:
    - {{  .Values.RANCHER_HEALTH_EXPORTER_PORT }}:9173

  black-box:
    tty: true
    labels:
      io.rancher.container.pull_image: always
      io.rancher.container.create_agent: 'true'
      io.rancher.container.agent.role: environment
      io.rancher.scheduler.global: 'true'
      io.rancher.sidekicks: black-box-config
    image: {{  .Values.RANCHER_BLACK_BOX_IMAGES }}
    command: --config.file=/config/blackbox.yaml
    ports:
    - {{  .Values.RANCHER_BLACK_BOX_PORT }}:9115
    volumes_from:
      - black-box-config

  black-box-config:
    labels:
      io.rancher.scheduler.global: 'true'
    image: {{  .Values.RANCHER_BLACK_BOX_CONFIG_IMAGES }}
    stdin_open: true
    network_mode: none
    environment:
       RANCHER_BLACK_BOX_CONFIG_CONTENT: ${RANCHER_BLACK_BOX_CONFIG_CONTENT}
    volumes:
    - black-box-config:/config
    tty: true
    command:
    - /bin/sh
    - -c
    - printf %s "${RANCHER_BLACK_BOX_CONFIG_CONTENT}" > /config/blackbox.yaml
    labels:
      io.rancher.container.pull_image: always
      io.rancher.container.start_once: 'true'