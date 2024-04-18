variable "cloudflare_email" {
  type = string
}

variable "cloudflare_api_key" {
  type      = string
  sensitive = true
}

variable "cloudflare_account_id" {
  type = string
}

variable "ntfy" {
  type = object({
    url      = string
    username = string
    password = string
  })

  sensitive = true
}

variable "github" {
  type = object({
    auth = object({
      token = string
    })
  })
}