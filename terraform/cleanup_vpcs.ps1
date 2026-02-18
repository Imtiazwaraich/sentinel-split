$vpcIds = @("vpc-083990bf71495ffcf", "vpc-045c28ac49829b850", "vpc-05453bb57660025d7", "vpc-0048f0bcfd77114aa")

foreach ($vpc in $vpcIds) {
    Write-Host "`n>>> Processing VPC: $vpc <<<"
    
    # 1. Non-default Security Groups
    $sgs = (aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text --no-cli-pager).Split([char]32, [char]9, [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($sgs) {
        Write-Host "  Found non-default SGs: $sgs"
        foreach ($sg in $sgs) {
            Write-Host "  Revoking all rules for SG: $sg"
            $rules = (aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$sg" --query "SecurityGroupRules[*].SecurityGroupRuleId" --output text --no-cli-pager).Split([char]32, [char]9, [System.StringSplitOptions]::RemoveEmptyEntries)
            foreach ($rule in $rules) {
                if ($rule -like "sgr-*") {
                    $isEgress = aws ec2 describe-security-group-rules --security-group-rule-ids $rule --query "SecurityGroupRules[0].IsEgress" --output text --no-cli-pager
                    if ($isEgress -eq "True") {
                        aws ec2 revoke-security-group-egress --group-id $sg --security-group-rule-ids $rule --no-cli-pager 2>$null
                    } else {
                        aws ec2 revoke-security-group-ingress --group-id $sg --security-group-rule-ids $rule --no-cli-pager 2>$null
                    }
                }
            }
        }
        foreach ($sg in $sgs) {
            Write-Host "  Deleting SG: $sg"
            aws ec2 delete-security-group --group-id $sg --no-cli-pager 2>$null
        }
    }

    # 2. Subnets
    $subnets = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query "Subnets[*].SubnetId" --output text --no-cli-pager).Split([char]32, [char]9, [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($s in $subnets) { 
        if ($s) { 
            Write-Host "  Deleting Subnet: $s"
            aws ec2 delete-subnet --subnet-id $s --no-cli-pager 2>$null 
        } 
    }

    # 3. Internet Gateways
    $igws = (aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[*].InternetGatewayId" --output text --no-cli-pager).Split([char]32, [char]9, [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($i in $igws) { 
        if ($i) { 
            Write-Host "  Detaching/Deleting IGW: $i"
            aws ec2 detach-internet-gateway --internet-gateway-id $i --vpc-id $vpc --no-cli-pager 2>$null
            aws ec2 delete-internet-gateway --internet-gateway-id $i --no-cli-pager 2>$null
        }
    }

    # 4. Final VPC deletion
    Write-Host "  Final attempt to delete VPC: $vpc"
    aws ec2 delete-vpc --vpc-id $vpc --no-cli-pager
}
