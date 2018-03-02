#!/bin/bash

default_gw="$(netstat -rn | grep -e '^0.0.0.0' | awk '{print $2}')"

ssh_host_ip=${ssh_host_ip:-$default_gw}
ssh_host_port=${ssh_host_port:-22}

echo "ssh_host_ip: ${ssh_host_ip}"
echo "ssh_host_port: ${ssh_host_port}"

sed -i -e 's@^#%include /etc/torrc.d/@%include /etc/torrc.d/@' /etc/tor/torrc

mkdir -p /etc/torrc.d

cat <<EOF > /etc/torrc.d/ssh
SocksPort 0
SafeLogging 1

HiddenServiceDir /var/lib/tor/ssh/

HiddenServiceVersion 3
HiddenServicePort 22 ${ssh_host_ip}:${ssh_host_port}
EOF

for port in "${OTHER_PORTS}" ; do
  cat <<EOF >> /etc/torrc.d/ssh
HiddenServicePort $port ${ssh_host_ip}:$port
EOF
done

echo "Configuration:"
grep -v -e '^#\|^$' /etc/tor/torrc /etc/torrc.d/*

echo 'Onion Hostname:'
grep . /var/lib/tor/*/hostname

chown -R tor /var/lib/tor
chmod 1777 /var/lib/tor
exec su tor -c "exec tor $@"
