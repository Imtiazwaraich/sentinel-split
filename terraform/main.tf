##############################################
# Gateway VPC
##############################################
module "vpc_gateway" {
  source = "./modules/vpc"

  name_prefix = "${var.resource_prefix}-gateway"
  vpc_cidr    = var.gateway_vpc_cidr
  tags        = var.tags
}

##############################################
# Backend VPC
##############################################
module "vpc_backend" {
  source = "./modules/vpc"

  name_prefix = "${var.resource_prefix}-backend"
  vpc_cidr    = var.backend_vpc_cidr
  tags        = var.tags
}

##############################################
# VPC Peering
##############################################
module "vpc_peering" {
  source = "./modules/vpc-peering"

  name_prefix = "${var.resource_prefix}-gateway-backend"

  vpc_id_requester = module.vpc_gateway.vpc_id
  vpc_id_accepter  = module.vpc_backend.vpc_id

  requester_vpc_cidr = module.vpc_gateway.vpc_cidr
  accepter_vpc_cidr  = module.vpc_backend.vpc_cidr

  requester_route_table_ids = module.vpc_gateway.private_route_table_ids
  accepter_route_table_ids  = module.vpc_backend.private_route_table_ids

  tags = var.tags
}

##############################################
# Gateway EKS Cluster
##############################################
module "eks_gateway" {
  source = "./modules/eks"

  cluster_name    = "${var.resource_prefix}-${var.gateway_cluster_name}"
  cluster_version = var.eks_version
  vpc_id          = module.vpc_gateway.vpc_id
  subnet_ids      = module.vpc_gateway.private_subnet_ids

  instance_type    = var.node_instance_type
  desired_capacity = var.node_desired_size
  min_capacity     = var.node_min_size
  max_capacity     = var.node_max_size

  peer_vpc_cidr = module.vpc_backend.vpc_cidr

  tags = var.tags

  depends_on = [module.vpc_peering]
}

##############################################
# Backend EKS Cluster
##############################################
module "eks_backend" {
  source = "./modules/eks"

  cluster_name    = "${var.resource_prefix}-${var.backend_cluster_name}"
  cluster_version = var.eks_version
  vpc_id          = module.vpc_backend.vpc_id
  subnet_ids      = module.vpc_backend.private_subnet_ids

  instance_type    = var.node_instance_type
  desired_capacity = var.node_desired_size
  min_capacity     = var.node_min_size
  max_capacity     = var.node_max_size

  peer_vpc_cidr = module.vpc_gateway.vpc_cidr

  tags = var.tags

  depends_on = [module.vpc_peering]
}
