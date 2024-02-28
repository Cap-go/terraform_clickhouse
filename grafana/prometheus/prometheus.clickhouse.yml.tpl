  - job_name: clickhouse
    scheme: https
    metrics_path: "/metrics"
    static_configs:
      - targets: ["__CLICKHOUSE_DOMAIN__"]
