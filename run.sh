#!/bin/sh

set -e

# Format log output
log() {
  echo "$(date -Isec) $@"
}

# Input environment variables:
# - NFS_SERVER: hostname of the NFS server (required)
# - NFS_PATH: path of the NFS share on the NFS server (required)
# - INTERVAL: interval in seconds for refreshing data (default 15 sec)
[[ -z "$NFS_SERVER" ]] && echo "Error: variable NFS_SERVER not set" && exit 1
[[ -z "$NFS_PATH" ]] && echo "Error: variable NFS_PATH not set" && exit 1
INTERVAL=${INTERVAL:-15}

# Configure Caddy to serve metrics on :9867/metrics
metrics_dir=/srv/http
metrics_file=metrics.prom
mkdir -p "$metrics_dir"
cat <<EOF >/root/Caddyfile
:9867 {
        root * "$metrics_dir"
        file_server
        rewrite /metrics "/$metrics_file"
}
EOF
caddy start --config /root/Caddyfile

# Collect data and write metrics to metrics file
while true; do
  log "Collecting data"
  # Note: -P is necessary to avoid breaking long entries into multiple lines
  result=$(df -P -B1 2>/dev/null | awk "\$1 == \"$NFS_SERVER:$NFS_PATH\"" | head -n 1)
  log "Found: $result"
  size=$(echo "$result" | awk '{print $2}')
  used=$(echo "$result" | awk '{print $3}')
  available=$(echo "$result" | awk '{print $4}')
  log "Writing metrics"
  cat <<EOF >"$metrics_dir/$metrics_file"
# HELP nfs_size_bytes Total size of the NFS share
# TYPE nfs_size_bytes gauge
nfs_size_bytes{nfs_server="$NFS_SERVER", nfs_path="$NFS_PATH"} $size
# HELP nfs_used_bytes Space on the NFS share that is currently used
# TYPE nfs_used_bytes gauge
nfs_used_bytes{nfs_server="$NFS_SERVER", nfs_path="$NFS_PATH"} $used
# HELP nfs_available_bytes Space on the NFS share that is available to ordinary users
# TYPE nfs_available_bytes gauge
nfs_available_bytes{nfs_server="$NFS_SERVER", nfs_path="$NFS_PATH"} $available
EOF
  sleep "$INTERVAL"
done
