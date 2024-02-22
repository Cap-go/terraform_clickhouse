{
    # Global options block
    acme_ca "https://acme-v02.api.letsencrypt.org/directory"
}

${domain_name} {
  reverse_proxy clickhouse-master:8123
}

${domain_name_grafana} {
  reverse_proxy clickhouse-master:8081
}
