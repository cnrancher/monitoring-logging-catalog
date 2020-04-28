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
