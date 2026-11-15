variable "bucket" {
  type = string
}

locals {
  name = "crypto-cost-monitor"
}

variable "snowflake_iam_user_arn" {
  type = string
}

variable "snowflake_external_id" {
  type = string
}