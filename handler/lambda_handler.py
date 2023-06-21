import os
import logging

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def delete(event, context):
    """ Remove malware files in bucket """
    s3 = boto3.resource('s3')

    logger.info(f"Received alerts: {len(event)}")

    for item in event:
        bucket = item['resource']['resourceId']
        logger.info(f"Bucket: {bucket}")

        key = item['resource']['resourceName']
        logger.info(f"Object key: {key}")

        response = s3.Object(bucket, key).delete()
    
        logger.info(response)


def quarantine(event, context):
    """ Move malware objects to a quarantine bucket. """
    s3 = boto3.resource('s3')

    quarantine_bucket = s3.Bucket(os.environ['S3_QUARANTINE_BUCKET_NAME'])
    
    logger.info(f"Received alerts: {len(event)}")

    for item in event:
        copy_source = {
            "Bucket": item['resource']['resourceId'],
            "Key": item['resource']['resourceName']
        }
        logger.info(f"Malware file source: {copy_source}")

        quarantine_object = quarantine_bucket.Object(copy_source['Key'])
        
        response = quarantine_object.copy(copy_source)

        logger.info("Object copied: ", response)
        source_object = s3.Object(copy_source['Bucket'], copy_source['Key'])
        response = source_object.delete()

        logger.info("Object deleted in source bucket: ", response)

        _tag_file(os.environ['S3_QUARANTINE_BUCKET_NAME'], copy_source['Key'],{
            "TagSet": [
                {
                    "Key": "PrismaCloud:ScanStatus",
                    "Value": "malware"
                },
                {
                    "Key": "PrismaCloud:AlertId",
                    "Value": item['alertId']
                },
                {
                    "Key": "PrismaCloud:SourceBucket",
                    "Value": item['resource']['resourceId']
                },
                {
                    "Key": "PrismaCloud:AlertGeneratedAt",
                    "Value": item['generatedAtTs']
                }
            ]
        } )


def _tag_file(bucket_name, key, tags):
    """ Adds TagSet to bucket object. """
    client = boto3.client('s3')

    response = client.put_object_tagging(
        Bucket=bucket_name,
        Key=key,
        Tagging=tags
    )

    logger.info(response)

    