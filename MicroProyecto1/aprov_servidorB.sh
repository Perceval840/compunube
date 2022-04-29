#!/bin/bash
echo "*** APROVISIONAMIENTO SERVIDOR_B ***"
echo "*** AGREGANDO SERVIDOR_A AL CLUSTER ***"
cat <<EOF | lxd init --preseed
config: {}
networks: []
storage_pools: []
profiles: []
cluster:
  server_name: servidorWebB
  enabled: true
  member_config:
  - entity: storage-pool
    name: local
    key: source
    value: /var/snap/lxd/common/lxd/storage-pools/local
    description: '"source" property for storage pool "local"'
  cluster_address: 192.168.90.2:8443
  cluster_certificate: |
    -----BEGIN CERTIFICATE-----
    MIICDDCCAZKgAwIBAgIQMe5TszH7TWZ2m7UBkoWdJDAKBggqhkjOPQQDAzA3MRww
    GgYDVQQKExNsaW51eGNvbnRhaW5lcnMub3JnMRcwFQYDVQQDDA5yb290QG12SGFw
    cm94eTAeFw0yMjA0MjUwMzA5MjZaFw0zMjA0MjIwMzA5MjZaMDcxHDAaBgNVBAoT
    E2xpbnV4Y29udGFpbmVycy5vcmcxFzAVBgNVBAMMDnJvb3RAbXZIYXByb3h5MHYw
    EAYHKoZIzj0CAQYFK4EEACIDYgAEmjHsq11YxWJLJZ6RVthtKbHMnNd6B+TSv+jw
    ZbJA8lPXiWbZKVsvIkJnJVLMMr5ulrljZhPRnP3QcRCgYi2QWSvo1r/NZ2BVsvVT
    qtBonUSMZmLLxHDUiHhixLWBgbkmo2MwYTAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0l
    BAwwCgYIKwYBBQUHAwEwDAYDVR0TAQH/BAIwADAsBgNVHREEJTAjggltdkhhcHJv
    eHmHBH8AAAGHEAAAAAAAAAAAAAAAAAAAAAEwCgYIKoZIzj0EAwMDaAAwZQIwSBKd
    JsvbhN+kfmz6hI2JgumkFLKFkfm6Erbg9kAWk1NOkFRSB4rld6WvU+ncsoT0AjEA
    40z5dhZx/C0jCJeMkmmH+1fGke505c9LoAp1Yxnvnup2mCaqgNW02XRd+cwSmZSZ
    -----END CERTIFICATE-----
  server_address: 192.168.90.4:8443
  cluster_password: admin
  cluster_certificate_path: ""
  cluster_token: ""
EOF

echo "*** Actualizando apt-get ***"
sudo apt-get update -y

echo "*** Upgrade apt-get ***"
sudo apt-get upgrade -y

echo "*** Instalando lxd ***"
sudo apt-get install lxd -y

sleep 20

echo "*** Logueandose en New Group ***"
sudo newgrp lxd

sleep 20

echo "*** IMPLEMENTANDO CONTENEDOR web2 ***"
sudo launch ubuntu:18.04 web2 --target servidorWebB

echo "*** Actualizando componentes del contenedor web2 ***"
sudo lxc exec web2 -- apt-get update
sudo lxc exec web2 -- apt-get install apache2 -y
sudo lxc exec web2 -- systemctl enable apache2

echo "*** Actualizando index.html de web2 ***"
sudo lxc file push shared/WebB/index.html web2/var/www/html/index.html

echo "*** Iniciando apache web2 ***"
sudo lxc exec web2 -- systemctl start apache2

echo "*** IMPLEMENTANDO CONTENEDOR web2bk (servidor backup) ***"
sudo launch ubuntu:18.04 web2bk --target servidorWebB

echo "*** Actualizando componentes del contenedor web2bk ***"
sudo lxc exec web2bk -- apt-get update
sudo lxc exec web2bk -- apt-get install apache2 -y
sudo lxc exec web2bk -- systemctl enable apache2

echo "*** Actualizando index.html de web2bk ***"
sudo lxc file push shared/WebA_BK/index.html web2bk/var/www/html/index.html

echo "*** Iniciando apache web2bk ***"
sudo lxc exec web2bk -- systemctl start apache2

echo "*** Fijando IP´s de contenedores web2 ***"
sudo lxc file push shared/WebB/01-netcfg.yaml web2/etc/netplan/01-netcfg.yaml
sudo lxc exec web2 -- sudo netplan apply

echo "*** Fijando IP´s de contenedores web2bk ***"
sudo lxc file push shared/WebB_BK/01-netcfg.yaml web2bk/etc/netplan/01-netcfg.yaml
sudo lxc exec web2bk -- sudo netplan apply
