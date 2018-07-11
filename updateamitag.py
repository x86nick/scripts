import boto3
import sys
# New key-value pairs for tags of AMIs that are secure
KEY1 = ''
VALUE1 = ''
KEY2 = ''
VALUE2 = ''

def get_ami_name(ami):
  client = boto3.client("ec2")
  response = client.describe_images(ImageIds = [ ami ])
  name = response['Images'][0]['Name']
  return name

def get_copies(name, ec2):
  response = ec2.describe_images(
             Filters=[
                 {'Name':'tag:Name','Values':[name]}
               ]
             )
  ami_list = [image['ImageId'] for image in response['Images']]
  return ami_list

def get_region_list():
  client = boto3.client('ec2')
  regions_info = client.describe_regions()['Regions']
  region_list = [region['RegionName'] for region in regions_info] # all regions for service
  return region_list

def update_tags_in_region(ami_list, ec2):
  response = ec2.create_tags( # Creates/ updates existing tags
    Resources= ami_list,
    Tags=[
      {
        'Key': KEY1,
        'Value': VALUE1
      },
      {
        'Key': KEY2,
        'Value': VALUE2
      }
    ]
  )

def get_tags(ami_list, ec2):
  response = ec2.describe_images( ImageIds= ami_list )
  for image in response["Images"]:
    for tags in image["Tags"]:
      if tags["Key"] == KEY1 or tags["Key"] == KEY2:
        val = tags["Value"]
        if val == "":
          val = "<Empty String>"
        print(tags["Key"], val)

def update_copies_all_regions(ami):
  name = get_ami_name(ami) # the Name which is common in all copies
  region_list = get_region_list()
  for region in region_list:
    ec2 = boto3.client('ec2', region_name = region)
    ami_in_region = get_copies(name, ec2)
    if ami_in_region == []:
      continue
    print(region, ami_in_region)
    get_tags(ami_in_region, ec2)
    update_tags_in_region(ami_in_region, ec2) # update tags
    get_tags(ami_in_region, ec2)
    print("--------")

if __name__=="__main__":
    args = sys.argv
    update_copies_all_regions(args[1])
