output "gateway_vpc_id" {
  description = "ID of the Gateway VPC"
  value       = module.vpc_gateway.vpc_id
}

output "backend_vpc_id" {
  description = "ID of the Backend VPC"
  value       = module.vpc_backend.vpc_id
}

output "gateway_cluster_endpoint" {
  description = "Endpoint for Gateway EKS cluster"
  value       = module.eks_gateway.cluster_endpoint
  sensitive   = true
}

output "backend_cluster_endpoint" {
  description = "Endpoint for Backend EKS cluster"
  value       = module.eks_backend.cluster_endpoint
  sensitive   = true
}

output "gateway_cluster_name" {
  description = "Name of the Gateway EKS cluster"
  value       = module.eks_gateway.cluster_name
}

output "backend_cluster_name" {
  description = "Name of the Backend EKS cluster"
  value       = module.eks_backend.cluster_name
}

output "configure_kubectl_gateway" {
  description = "Command to configure kubectl for Gateway cluster"
  value       = "aws eks update-kubeconfig --name eks-${module.eks_gateway.cluster_name} --region ${var.aws_region}"
}

output "configure_kubectl_backend" {
  description = "Command to configure kubectl for Backend cluster"
  value       = "aws eks update-kubeconfig --name eks-${module.eks_backend.cluster_name} --region ${var.aws_region}"
}

output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = module.vpc_peering.peering_connection_id
}
