#!/bin/bash
keypair=$USER
publickeyfile=$HOME/.ssh/id_rsa.pub
regions=$(aws ec2 describe-regions \
  --output text \
  --query 'Regions[*].RegionName')

for region in $regions; do
  echo $region
  aws ec2 import-key-pair \
    --region "$region" \
    --key-name "$keypair" \
    --public-key-material "file://$publickeyfile"
done
