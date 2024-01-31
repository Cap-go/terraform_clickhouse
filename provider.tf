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
