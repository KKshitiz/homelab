terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc01"
    }
  }
}


provider "proxmox" {
  pm_api_url = "http://192.168.29.197:8006/api2/json"
  pm_api_token_id = "terraform@pam!terraform-token"
  pm_api_token_secret = "a488d6fa-2da3-44db-9708-bfd154cc0179"
  pm_tls_insecure = true  # Set to false in production
}
