for region in us-east-2 us-west-2; do  
  for eni in `aws ec2 describe-network-interfaces --region ${region} --output text --filters Name=status,Values=available --query 'NetworkInterfaces[*].{ENI:NetworkInterfaceId}'`; do
    echo "Deleting IP Address assigned to $eni in $region"
    aws ec2 delete-network-interface --network-interface-id ${eni}  --region ${region}
  done
done
