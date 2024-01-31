
resource "random_password" "clickhouse_password" {
  length           = 64
  special          = true
  override_special = "_%@"
}


resource "hcloud_server" "clickhouse_server" {
  name        = "clickhouse-server"
  image       = "ubuntu-22.04"
  server_type = "cx51"
  location    = "fsn1"
  ssh_keys    = ["martindonadieu@gmail.com", "Michal"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(pathexpand(var.private_key_path))
    host        = hcloud_server.clickhouse_server.ipv4_address
  }
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/root/docker-compose.yml"
  }

  provisioner "file" {
    source      = "Caddyfile"
    destination = "/root/Caddyfile"
  }

  provisioner "file" {
    source      = "fail2ban/jail.local"
    destination = "/etc/fail2ban/jail.local"
  }

  provisioner "remote-exec" {
    inline = [
      "apt update && apt install -y docker.io fail2ban",
      "mkdir -p /etc/fail2ban/filter.d",
    ]
  }

  provisioner "file" {
    source      = "fail2ban/clickhouse.conf"
    destination = "/etc/fail2ban/filter.d/clickhouse.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -L \"https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose",
      "mkdir -p /data/clickhouse01 /data/clickhouse02 /data/clickhouse03",
      "cd /root && /usr/local/bin/docker-compose up -d clickhouse-master clickhouse-replica1 clickhouse-replica2 fail2ban"
    ]
  }
}

resource "cloudflare_record" "clickhouse" {
  zone_id = var.cloudflare_zone_id
  name    = "clickhouse2.capgo.app"
  value   = hcloud_server.clickhouse_server.ipv4_address
  type    = "A"
  proxied = true
  depends_on = [hcloud_server.clickhouse_server]
}

resource "null_resource" "start_caddy" {
  # Depends on the Cloudflare DNS record to ensure it's created first
  depends_on = [cloudflare_record.clickhouse]

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {

    # Start Caddy container
    inline = [
      "cd /root && /usr/local/bin/docker-compose up -d caddy"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(pathexpand(var.private_key_path))
      host        = hcloud_server.clickhouse_server.ipv4_address
    }
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id"
}

variable "private_key_path" {
  description = "The path to the private SSH key to use for the connection"
  type        = string
  default     = "~/.ssh/id_rsa"
  # You can set a default value or leave it empty and provide the value when running Terraform
  # default = "/path/to/your/private/key"
}

output "clickhouse_server_ip" {
  value = hcloud_server.clickhouse_server.ipv4_address
}

output "clickhouse_password" {
  value     = random_password.clickhouse_password.result
  sensitive = true
}
