variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (used for resource naming and tagging)"
  type        = string
  default     = "imtiaz-sentinel"
}

variable "gateway_vpc_cidr" {
  description = "CIDR block for Gateway VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "backend_vpc_cidr" {
  description = "CIDR block for Backend VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gateway_cluster_name" {
  description = "Name of the Gateway EKS cluster"
  type        = string
  default     = "imtiaz-gateway"
}

variable "backend_cluster_name" {
  description = "Name of the Backend EKS cluster"
  type        = string
  default     = "imtiaz-backend"
}

variable "eks_version" {
  description = "Kubernetes version for EKS clusters"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of nodes in each cluster"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in each cluster"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in each cluster"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "Sentinel-Split"
    ManagedBy = "Terraform"
  }
}
