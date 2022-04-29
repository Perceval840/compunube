#!/bin/bash

echo "****** APROVISIONANDO BALANCEADOR ******"
sudo snap install lxd --channel=4.0/stable 

echo "****** CREANDO GRUPO ******"
newgrp lxd

echo "****** CONFIGURANDO CLUSTER ******"
cat <<EOF | lxd init --preseed

config:
  core.https_address: 192.168.90.2:8443
  core.trust_password: admin
networks:
- config:
    bridge.mode: fan
    fan.underlay_subnet: auto
  description: ""
  name: lxdfan0
  type: ""
storage_pools:
- config: {}
  description: ""
  name: local
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdfan0
      type: nic
    root:
      path: /
      pool: local
      type: disk
  name: default
cluster:
  server_name: mvHaproxy
  enabled: true
  member_config: []
  cluster_address: ""
  cluster_certificate: ""
  server_address: ""
  cluster_password: ""
  cluster_certificate_path: ""
  cluster_token: ""
EOF

echo "*** ACTUALIZANDO apt-get ***"
sudo apt-get update -y
sudo apt-get upgrade -y

echo "*** APROVISIONANDO CONTENEDOR ***"

echo "*** Implementando contenedor haproxy"
sudo lxc launch ubuntu:18.04 haproxy

sleep 10

echo "*** ACTUALIZANDO HAPROXY EN EL CONTENEDOR ***"
sudo lxc exec haproxy -- apt-get update
sudo lxc exec haproxy -- apt-get install haproxy -y

echo "*** ACTUALIZANDO CONFIGURACIÓN DEL BALANCEADOR DE CARGA ***"
sudo lxc file push shared/haproxy.cfg haproxy/etc/haproxy/haproxy.cfg

echo "*** REINICIANDO HAPROXY ***"
sudo lxc exec haproxy -- sudo systemctl restart haproxy

echo "*** FORWARDING DE PUERTOS PARA VISUALIZAR EN NAVEGADOR HOST ***"
sudo lxc config device add haproxy http proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80

echo "*** ACTUALIZANDO MENSAJE DE ERRORES ***"
sudo lxc file push shared/WebErrores/index.html haproxy/etc/haproxy/errors/503.http
