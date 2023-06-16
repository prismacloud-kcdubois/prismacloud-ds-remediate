import logging

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def delete(event, context):
    """ Remove malware files in bucket """
    s3_resource = boto3.resource('s3')

    logger.info(f"Received alerts: {len(event)}")

    for item in event:
        bucket = f"arn:aws:s3:::{item['resource']['resourceId']}"
        logger.info(f"Bucket ARN: {bucket}")

        name = item['resource']['resourceName']
        logger.info(f"Object key: {name}")

        response = s3_resource.delete_object(Bucket=bucket, Key=name)
        
        logger.info(response)