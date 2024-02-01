
resource "random_password" "clickhouse_password" {
  length           = 64
  special          = true
  override_special = "_%@"
}

resource "local_file" "clickhouse_env" {
  filename = "${path.module}/clickhouse.env"
  content  = "CLICKHOUSE_PASSWORD=${random_password.clickhouse_password.result}"
}

resource "local_file" "clickhouse_sql" {
  filename = "${path.module}/clickhouse.sql"
  content  = data.http.clickhouse_sql.body
}

data "template_file" "data_transfer" {
  template = file("${path.module}/data_transfer.tpl")

  vars = {
    host     = var.old_clickhouse_host
    password = var.old_clickhouse_password
  }
}

resource "local_file" "clickhouse_data_transfer" {
  filename = "${path.module}/data_transfer.sql"
  content  = data.template_file.data_transfer.rendered
}

resource "hcloud_server" "clickhouse_server" {
  name        = "clickhouse-server"
  image       = "ubuntu-22.04"
  server_type = "cx51"
  location    = "fsn1"
  backups    = true
  ssh_keys    = ["martindonadieu@gmail.com", "Michal"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(pathexpand(var.private_key_path))
    host        = hcloud_server.clickhouse_server.ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/clickhouse.env"
    destination = "/root/clickhouse.env"
  }

  provisioner "file" {
    source      = "${path.module}/docker-compose.yml"
    destination = "/root/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/Caddyfile"
    destination = "/root/Caddyfile"
  }

  provisioner "file" {
    source      = "${path.module}/fail2ban/jail.local"
    destination = "/etc/fail2ban/jail.local"
  }

  provisioner "remote-exec" {
    inline = [
      "apt update && apt install -y docker.io fail2ban",
      "mkdir -p /etc/fail2ban/filter.d",
    ]
  }

  provisioner "file" {
    source      = "${local_file.clickhouse_sql.filename}"
    destination = "/root/clickhouse.sql"
  }

  provisioner "file" {
    source      = "${local_file.clickhouse_data_transfer.filename}"
    destination = "/root/data_transfer.sql"
  }

  provisioner "file" {
    source      = "${path.module}/fail2ban/clickhouse.conf"
    destination = "/etc/fail2ban/filter.d/clickhouse.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -L \"https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose",
      "cd /root && /usr/local/bin/docker-compose up -d clickhouse-master fail2ban"
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
      "cd /root && /usr/local/bin/docker-compose up -d"
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
