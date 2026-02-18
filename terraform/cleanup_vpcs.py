import boto3
import sys

vpc_ids = ["vpc-083990bf71495ffcf", "vpc-045c28ac49829b850", "vpc-05453bb57660025d7", "vpc-0048f0bcfd77114aa"]
region = "us-west-2"
ec2 = boto3.client('ec2', region_name=region)

def cleanup_sg(sg_id):
    try:
        sg = ec2.describe_security_groups(GroupIds=[sg_id])['SecurityGroups'][0]
        if sg['IpPermissions']:
            ec2.revoke_security_group_ingress(GroupId=sg_id, IpPermissions=sg['IpPermissions'])
        if sg['IpPermissionsEgress']:
            ec2.revoke_security_group_egress(GroupId=sg_id, IpPermissions=sg['IpPermissionsEgress'])
        print(f"  Revoked rules for {sg_id}")
    except Exception as e:
        print(f"  Error revoking rules for {sg_id}: {e}")

def delete_vpc_resources(vpc_id):
    print(f"\nProcessing VPC: {vpc_id}")
    
    # 1. Non-default SGs
    sgs = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])['SecurityGroups']
    non_default_sgs = [sg['GroupId'] for sg in sgs if sg['GroupName'] != 'default']
    
    # First pass: revoke all rules
    for sg_id in non_default_sgs:
        cleanup_sg(sg_id)
        
    # Second pass: delete SGs
    for sg_id in non_default_sgs:
        try:
            ec2.delete_security_group(GroupId=sg_id)
            print(f"  Deleted SG {sg_id}")
        except Exception as e:
            print(f"  Failed to delete SG {sg_id}: {e}")

    # 2. Subnets
    subnets = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])['Subnets']
    for sn in subnets:
        sn_id = sn['SubnetId']
        try:
            ec2.delete_subnet(SubnetId=sn_id)
            print(f"  Deleted Subnet {sn_id}")
        except Exception as e:
            print(f"  Failed to delete Subnet {sn_id}: {e}")

    # 3. IGWs
    igws = ec2.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])['InternetGateways']
    for igw in igws:
        igw_id = igw['InternetGatewayId']
        try:
            ec2.detach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)
            ec2.delete_internet_gateway(InternetGatewayId=igw_id)
            print(f"  Deleted IGW {igw_id}")
        except Exception as e:
            print(f"  Failed to delete IGW {igw_id}: {e}")

    # 4. Route Tables (non-main)
    rts = ec2.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])['RouteTables']
    for rt in rts:
        is_main = any(assoc.get('Main', False) for assoc in rt.get('Associations', []))
        if not is_main:
            rt_id = rt['RouteTableId']
            try:
                ec2.delete_route_table(RouteTableId=rt_id)
                print(f"  Deleted RT {rt_id}")
            except Exception as e:
                print(f"  Failed to delete RT {rt_id}: {e}")

    # 5. Delete VPC
    try:
        ec2.delete_vpc(VpcId=vpc_id)
        print(f"DONE: Deleted VPC {vpc_id}")
    except Exception as e:
        print(f"FAILED to delete VPC {vpc_id}: {e}")

if __name__ == "__main__":
    for vpc in vpc_ids:
        delete_vpc_resources(vpc)
