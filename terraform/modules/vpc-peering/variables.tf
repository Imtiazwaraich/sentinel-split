variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id_requester" {
  description = "ID of the requester VPC"
  type        = string
}

variable "vpc_id_accepter" {
  description = "ID of the accepter VPC"
  type        = string
}

variable "requester_vpc_cidr" {
  description = "CIDR block of the requester VPC"
  type        = string
}

variable "accepter_vpc_cidr" {
  description = "CIDR block of the accepter VPC"
  type        = string
}

variable "requester_route_table_ids" {
  description = "List of route table IDs in the requester VPC"
  type        = list(string)
}

variable "accepter_route_table_ids" {
  description = "List of route table IDs in the accepter VPC"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
