variable "bucket_name" {
  description = "Globally unique name for the S3 bucket."
  type        = string

  validation {
    condition = (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name)) &&
      !strcontains(var.bucket_name, "..")
    )
    error_message = "bucket_name must be 3-63 characters, use lowercase letters, digits, dots, or hyphens, and start/end with a letter or digit."
  }
}

variable "force_destroy" {
  description = "Whether Terraform may delete a bucket that contains objects. Keep false for production buckets."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the bucket."
  type        = map(string)
  default     = {}
}