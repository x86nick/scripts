#!/usr/bin/env python

import argparse
import boto3
import botocore.exceptions
import logging
import os
import platform
import subprocess
import sys
from distutils.version import LooseVersion, StrictVersion
from pprint import pprint

# Make it actually work then add all the validation

def check_os_version():
	system, node, release, version, machine, processor = platform.uname()

	if (system == "Linux"):
		bad_version_error = "Your version of {} is too old. Please use {} {} or greater."
		dist, version, codename = platform.dist()
		req_version = "6.8"
		if system == "Linux":
			if dist == 'redhat':
				if LooseVersion(version) < LooseVersion(req_version):
					logger.fatal(bad_version_error.format(dist.title(), dist.title(), req_version))
					sys.exit(1)
			else:
				logger.fatal("Your system is Linux but is the {} distribution. Only Redhat is supported at this time.".format(dist.title()))
				sys.exit(1)
	else:
		logger.fatal("Detected {} type OS. This OS is not supported. Please use Linux or Darwin.".format(system))
		sys.exit(1)

def check_python_version(req_version):
	cur_version = sys.version_info
	if cur_version <= req_version:
		logger.fatal("Your Python interpreter is too old. Please upgrade to {}.{} or greater.".format(req_version[0], req_version[1]))
		sys.exit(1)

def check_environment():
	logger.info("Validating your environment.")
	check_os_version()
	check_python_version((2, 6))

def configure_logger(debug=False):
	level = logging.DEBUG if debug == True else logging.INFO
	logger = logging.getLogger()
	handler = logging.StreamHandler()
	formatter = logging.Formatter("%(levelname)s %(message)s")
	handler.setFormatter(formatter)
	logger.addHandler(handler)
	logger.setLevel(level)
	logger.propagate = False
	return logger

def configure():
	parser = argparse.ArgumentParser(description="Sync an s3-based yum repository.")
	parser.add_argument("--bucket", "-b", help="The name of the s3 bucket housing your repository.", action="store", required=True)
	parser.add_argument("--local", "-l", help="The absolute path to the local directory to sync the remote yum repository with.", action="store", required=True)
	parser.add_argument("--remote", "-r", help="The path to the remote s3 repository. This is the directory containing the various architecture directories.", action="store", required=True)
	parser.add_argument("--no-sync-from-s3", help="Do not sync from s3 first.", action="store_true", required=False)
	parser.add_argument("--no-update-repo", help="Do not update the local repo.", action="store_true", required=False)
	parser.add_argument("--no-sync-to-s3", help="Do not sync to s3 after updating the local repo.", action="store_true", required=False)
	args = parser.parse_args()
	return args

def which(command):
	def is_exe(fpath):
		return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

	fpath, fname = os.path.split(command)
	if fpath:
		if is_exe(command):
			return command

	else:
		for path in os.environ["PATH"].split(os.pathsep):
			path = path.strip('"')
			exe_file = os.path.join(path,command)
			if is_exe(exe_file):
				return exe_file
	return None

def bucket_exists(bucket=None):
	try:
		resp = s3client.head_bucket(Bucket=bucket)
		return True
	except:
		return False

def path_exists(bucket=None, path=None):
	s3 = boto3.resource('s3')
	resp = s3client.head_bucket(Bucket=bucket)
	paginator = s3client.get_paginator('list_objects')
	pageresponse = paginator.paginate(Bucket=bucket)
	for pageobject in pageresponse:
		if 'Contents' in pageobject.keys():
			for file in pageobject['Contents']:
				pprint(file)
				itemtocheck = s3.ObjectSummary(bucket, file['Key'])

				keylist = file['Key'].split('/')
				if len(keylist) == 1:
					dirsizedict['.'] += itemtocheck.size
	#path = "{}/".format(path)
	#resp = s3client.put_object(Bucket=bucket, Body="", Key=path)

	#prefix = path + "/"
	#resp = s3client.head_object(Bucket=bucket, Key="yum/x86_64")
	pprint(resp);sys.exit()
	try:
		resp = s3client.get_object(Bucket=bucket, Key=path)
		pprint(resp)
		return True
	except:
		return False

def validate_remote():
	logger.info("Validating the specified bucket.")
	if bucket_exists(bucket=args.bucket) == False:
		logger.error("The bucket {} does not exist.".format(args.bucket))
		sys.exit(1)

	#logger.info("Validating the specified remote path.")
	#if path_exists(bucket=args.bucket, path=args.remote) == False:
	#	logger.error("The remote path {} does not exist in the bucket {}.".format(args.remote, args.bucket))
	#	sys.exit(1)

def check_prereqs():
	logger.info("Validating prerequisites.")
	prereqs = ["aws", "createrepo"]
	errors = []
	for command in prereqs:
		if which(command) == None:
			errors.append(message = "The file {} could not be found. Please fix this and try again.".format(command))
	if len(errors) > 0:
		for error in errors:
			logger.error(error)
		sys.exit(1)

def create_directories():
	logger.info("Creating directories.")
	directories = [ args.local ]
	errors = []

	for directory in directories:
		try:
			os.makedirs(directory)
		except OSError as e:
			if e.errno == 17:
				pass
			else:
				errors.append("Failed to create the directory {}: {}.".format(directory, str(e)))

	if len(errors) > 0:
		for error in errors:
			logger.error(error)
		sys.exit(1)

def sync_from_s3():
	logger.info("Syncing s3://{}/{} to {}.".format(args.bucket, args.remote, args.local))
	command = "aws s3 sync s3://{}/{} {}/".format(args.bucket, args.remote, args.local)
	subprocess.call(command, shell=True)

def update_repo():
	for arch in next(os.walk(args.local))[1]:
		arch_dir = "{}/{}".format(args.local, arch)
		logger.info("Updating {}.".format(arch_dir))
		update = ""
		if os.path.isdir("{}/repodata".format(arch_dir)):
			update = "--update"
		command = "createrepo {} {}".format(update, arch_dir)
		subprocess.call(command, shell=True)

def sync_to_s3():
	for arch in next(os.walk(args.local))[1]:
		src = "{}/{}".format(args.local, arch)
		dest = "s3://{}/{}/{}".format(args.bucket, args.remote, arch)
		logger.info("Syncing {} to {}.".format(src, dest))
		command = "aws s3 sync {} {} --delete --acl public-read".format(src, dest)
		subprocess.call(command, shell=True)

logger = configure_logger()
args = configure()
check_environment()

try:
	session = boto3.session.Session(profile_name="default")
	boto3.setup_default_session(profile_name="default")
except (botocore.exceptions.ClientError, botocore.exceptions.ProfileNotFound, botocore.exceptions.NoCredentialsError) as e:
	logger.error("There was a problem with your AWS profile: {}".format(str(e)))
	sys.exit(1)

s3client = boto3.client("s3", region_name="us-west-2")

#validate_remote()
check_prereqs()
create_directories()
if not args.no_sync_from_s3:
	sync_from_s3()
if not args.no_update_repo:
	update_repo()
sync_to_s3()
