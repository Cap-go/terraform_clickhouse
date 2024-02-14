
locals {
  clickhouse_env_hash           = filemd5("${path.module}/clickhouse.env")
  docker_compose_hash           = filemd5("${path.module}/docker-compose.yml")
  terraform_vars_hash           = filemd5("${path.module}/terraform.tfvars")
  fail2ban_jail_local_hash      = filemd5("${path.module}/fail2ban-jail.local")
  fail2ban_clickhouse_conf_hash = filemd5("${path.module}/fail2ban-clickhouse.conf")
  clickhouse_sql_hash           = filemd5("${local_file.clickhouse_sql.filename}")
}

#  Generate a random password for the ClickHouse user
resource "random_password" "clickhouse_password" {
  length           = 64
  special          = false
}

data "template_file" "clickhouse_config" {
  template = file("${path.module}/clickhouse-config.xml.tpl")

  vars = {
    certificate_file = "/etc/clickhouse-server/ssl/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${var.clickhouse_domain}/${var.clickhouse_domain}.crt"
    private_key_file = "/etc/clickhouse-server/ssl/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${var.clickhouse_domain}/${var.clickhouse_domain}.key"
    s3_url_with_folder = "${var.backup_s3_url_with_folder}"
    backup_s3_access_key = "${var.backup_s3_access_key}"
    backup_s3_secret_access_key = "${var.backup_s3_secret_access_key}"
  }
}

data "template_file" "caddy_config" {
  template = file("${path.module}/Caddyfile.tpl")

  vars = {
    domain_name = var.clickhouse_domain
  }
}

resource "local_file" "clickhouse_config_xml" {
  filename = "${path.module}/clickhouse-config.xml"
  content  = data.template_file.clickhouse_config.rendered
}

resource "local_file" "caddy_config_render" {
  filename = "${path.module}/Caddyfile"
  content  = data.template_file.caddy_config.rendered
}


resource "local_file" "clickhouse_env" {
  filename = "${path.module}/clickhouse.env"
  content  = "CLICKHOUSE_PASSWORD=${random_password.clickhouse_password.result}\nCLICKHOUSE_UID=root\nCLICKHOUSE_GID=root\nS3_BACKUP_AWS_ENDPOINT=${var.backup_s3_url_no_folder}\nS3_BACKUP_ACCESS_KEY=${var.backup_s3_access_key}\nS3_BACKUP_SECRET_ACCESS_KEY=${var.backup_s3_secret_access_key}\n"
}

resource "local_file" "clickhouse_sql" {
  filename = "${path.module}/clickhouse.sql"
  content  = data.http.clickhouse_sql.response_body
}

# Create a new server
resource "hcloud_server" "clickhouse_server" {
  name        = var.machine_name
  image       = "ubuntu-22.04"
  server_type = "cx51"
  location    = "fsn1"
  backups    = true
  ssh_keys    = var.hetzner_ssh_keys

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(pathexpand(var.private_key_path))
    host        = hcloud_server.clickhouse_server.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "curl -L \"https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose",
      "sudo add-apt-repository universe -y && sudo apt update -y && sudo apt install -y fail2ban",
      "sudo mkdir -p /data",
      "sudo mkdir -p /data/clickhouse-master",
      "sudo mkdir -p /data/clickhouse-master-logs",
      "sudo chown -R root:root /data",
      "sudo chmod -R 744 /data",
    ]
  }
}

# Create a DNS record for the new server
resource "cloudflare_record" "clickhouse" {
  zone_id = var.cloudflare_zone_id
  name    = var.clickhouse_domain
  value   = hcloud_server.clickhouse_server.ipv4_address
  type    = "A"
  proxied = false
  depends_on = [hcloud_server.clickhouse_server]
}

resource "null_resource" "files_updates" {
  triggers = {
    clickhouse_env_hash           = local.clickhouse_env_hash
    docker_compose_hash           = local.docker_compose_hash
    terraform_vars_hash           = local.terraform_vars_hash
    fail2ban_jail_local_hash      = local.fail2ban_jail_local_hash
    fail2ban_clickhouse_conf_hash = local.fail2ban_clickhouse_conf_hash
    clickhouse_sql_hash           = local.clickhouse_sql_hash
  }

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
    source      = "${path.module}/s3-backup"
    destination = "/root/s3-backup"
  }

  provisioner "file" {
    source      = "${path.module}/docker-compose.yml"
    destination = "/root/docker-compose.yml"
  }

  provisioner "file" {
    source      = local_file.caddy_config_render.filename
    destination = "/root/Caddyfile"
  }

  provisioner "file" {
    source      = "${path.module}/fail2ban-clickhouse.conf"
    destination = "/etc/fail2ban/filter.d/clickhouse.conf"
  }

  provisioner "file" {
    source      = "${path.module}/fail2ban-jail.local"
    destination = "/etc/fail2ban/jail.d/jail.local"
  }

  provisioner "file" {
    source      = "${local_file.clickhouse_config_xml.filename}"
    destination = "/etc/clickhouse-server/config.xml"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root && /usr/local/bin/docker-compose down && /usr/local/bin/docker-compose up -d",
      "sudo systemctl enable fail2ban",
      "sudo systemctl start fail2ban",
    ]
  }

  depends_on = [
    hcloud_server.clickhouse_server,
  ]
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
