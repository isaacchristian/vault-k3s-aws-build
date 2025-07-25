variable "region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region into which to deploy the HVN"
}

variable "public_key" {
  type        = string
  default     = "vault-key.pub"
  description = "Public key to log into AWS instance"
}

variable "cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "ami_type" {
  type        = string
  default     = "ami-022bbd2ccaf21691f"
  description = "The type of AMI to use for the EC2 instances (e.g., amazon-linux-2, ubuntu-20.04)"
}