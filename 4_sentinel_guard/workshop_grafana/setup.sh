#!/bin/bash

# --- 1. Environment Setup ---
PROJECT_DIR="grafana-loki-demo"
mkdir -p $PROJECT_DIR/logs
mkdir -p $PROJECT_DIR/grafana_provisioning/datasources
cd $PROJECT_DIR

# Fix: Ensure the logs directory is writeable by the Promtail container user
chmod 777 logs

# --- 2. Automatic Grafana Provisioning (Fix: No manual setup needed) ---
cat <<EOF > grafana_provisioning/datasources/ds.yaml
apiVersion: 1
datasources:
- name: Loki
  type: loki
  access: proxy
  url: http://loki:3100
  isDefault: true
EOF

# --- 3. Loki Configuration ---
cat <<EOF > loki-config.yaml
auth_enabled: false
server:
  http_listen_port: 3100
common:
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory
schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
EOF

# --- 4. Promtail Configuration (JSON Pipeline Fix) ---
cat <<EOF > promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
- job_name: json_logs
  static_configs:
  - targets:
      - localhost
    labels:
      job: app_logs
      host: dev-machine
      __path__: /var/log/app/*.log
  pipeline_stages:
  - json:
      expressions:
        lvl: level
        meth: method
        stat: status
  - labels:
      level: lvl
      method: meth
      status: stat
EOF

# --- 5. Docker Compose (Fix: Added healthchecks and volume mapping) ---
cat <<EOF > docker-compose.yaml
version: "3.8"
services:
  loki:
    image: grafana/loki:2.9.0
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./loki-config.yaml:/etc/loki/local-config.yaml

  promtail:
    image: grafana/promtail:2.9.0
    volumes:
      - ./logs:/var/log/app
      - ./promtail-config.yaml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
    depends_on:
      - loki

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
    volumes:
      - ./grafana_provisioning:/etc/grafana/provisioning
    depends_on:
      - loki
EOF

# --- 6. JSON Log Generator (Python) ---
cat <<EOF > gen_logs.py
import json
import time
import random
import os

log_file = "logs/app.log"
methods = ["GET", "POST", "DELETE", "PUT"]
levels = ["info", "warn", "error"]

print("Starting log generation... Press Ctrl+C to stop.")
while True:
    data = {
        "time": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        "level": random.choice(levels),
        "method": random.choice(methods),
        "status": random.choice([200, 201, 400, 404, 500]),
        "msg": "API Request Processed",
        "latency_ms": random.randint(10, 500)
    }
    with open(log_file, "a") as f:
        f.write(json.dumps(data) + "\n")
    time.sleep(1)
EOF

# --- Execution ---
echo "🚀 Starting Centralized Logging Stack..."
docker-compose up -d

echo "📊 Waiting for Grafana to be ready..."
sleep 5

echo "📝 Starting Python Log Producer..."
python3 gen_logs.py