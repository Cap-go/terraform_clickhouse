terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
    random = {
      source  = "hashicorp/random"
    }
    http = {
      source  = "hashicorp/http"
    }
  }
}

provider "random" {
  # No configuration is needed for the random provider
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_key
}

variable "hcloud_token" {
  description = "This is the Hetzner Cloud API token"
}

variable "cloudflare_api_key" {
  description = "This is the Cloudflare API key"
}

data "http" "clickhouse_sql" {
  url = "https://raw.githubusercontent.com/Cap-go/capgo/main/supabase/clickhouse.sql"
}

variable "clickhouse_domain" {
  description = "The domain for the ClickHouse server"
  type        = string
  # You can provide a default value or leave it empty to require the variable
  # default     = "default.domain.com"
}

variable "grafana_domain" {
  description = "The domain for the Grafana server"
  type        = string
}

variable "grafana_password" {
  description = "The password for the Grafana server"
  type        = string
}

variable "supabase_access_token" {
  description = "The access token for the Supabase api"
  type        = string
}

variable "supabase_org_id" {
  description = "The organization id for the Supabase api"
  type        = string
}

variable "hetzner_ssh_keys" {
  description = "The list of SSH keys to add to the Hetzner Cloud server"
  type        = list(string)
  # You can provide a default value or leave it empty to require the variable
  # default     = "default.domain.com"
}

variable "machine_name" {
  description = "The name of the Hetzner Cloud server"
  type        = string
  
}

variable "backup_s3" {
  description = "The S3 URL with the folder to backup to"
  type        = string
}

variable "backup_s3_bucket" {
  description = "The S3 folder to backup to"
  type        = string
}

variable "backup_s3_access_key" {
  description = "The S3 access key"
  type        = string
}

variable "backup_s3_secret_access_key" {
  description = "The S3 secret access key"
  type        = string
}
