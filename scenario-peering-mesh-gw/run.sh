#!/usr/bin/env bash

set -euo pipefail

rm -rf /tmp/consul-dc1
rm -rf /tmp/consul-dc2

echo "Starting Consul"
consul agent -dev -log-level=trace -config-file config_dc1.hcl 1>./logs/dc1.log &
consul agent -dev -log-level=trace -config-file config_dc2.hcl 1>./logs/dc2.log &
# http-echo-server 3005 &

echo "Sleeping for 10 seconds"
sleep 10

# Enable Control Plane Traffic
consul config write mesh.hcl

echo "Starting Gateways"
consul connect envoy -gateway mesh -expose-servers -register -- -l critical &

# For the mesh gateway to have outputbound connectivity, the peering must be an outbound connection
# for the cluster.
echo "Establishing Peering"
CONSUL_HTTP_ADDR=localhost:9500 consul peering generate-token -name cluster-01 > before_peering_token.txt
consul peering establish -name cluster-02 -peering-token "$(cat before_peering_token.txt)"

# consul config write peering-config.hcl

# CONSUL_HTTP_ADDR=localhost:9500 consul services register static-client.hcl
# CONSUL_HTTP_ADDR=localhost:9500 consul services register static-client-sidecar-proxy.hcl
# CONSUL_HTTP_ADDR=localhost:9500 consul config write static-server-service-defaults.hcl

# consul services register static-server.hcl
# consul services register static-server-sidecar-proxy.hcl
# CONSUL_HTTP_ADDR=localhost:9500 consul connect envoy -sidecar-for static-client -address '{{ GetInterfaceIP "$NETWORK_INTERFACE" }}:19001' -admin-bind localhost:19004 -- -l critical &
# consul connect envoy -sidecar-for static-server -address '{{ GetInterfaceIP "$NETWORK_INTERFACE" }}:8446' -admin-bind localhost:19005 -- -l critical &

# Cleanup
# pkill node consul envoy
