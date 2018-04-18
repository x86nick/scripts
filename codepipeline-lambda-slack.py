from __future__ import print_function

import boto3
import json
import logging
import os

from base64 import b64decode
from urllib2 import Request, urlopen, URLError, HTTPError

HOOK_URL = os.environ['slackHookUrl']
# The Slack channel to send a message to stored in the slackChannel environment variable
SLACK_CHANNEL = os.environ['slackChannel']

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info("Event: " + str(event))
    pipeline_name = event['detail']['pipeline']
    pipeline_state = event['detail']['state']
    
    items = [{'color': 'good', 'text': pipeline_name + ' - ' + pipeline_state}]
    if pipeline_state == "FAILED":
        items = [{'color': 'danger', 'text': pipeline_name + ' - ' + pipeline_state}]
        
    slack_message = {
        'channel': SLACK_CHANNEL,
        'attachments': items
    }

    req = Request(HOOK_URL, json.dumps(slack_message))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
