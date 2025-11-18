import json
import boto3
import urllib.parse
from datetime import datetime
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('data-processing-table-w1c9wxc2')

def lambda_handler(event, context):
    """
    Lambda function to process S3 events and store data in DynamoDB.
    
    This function is triggered when files are uploaded to S3.
    It reads the file metadata and content, then stores information in DynamoDB.
    """
    
    try:
        # Process each record in the event
        for record in event['Records']:
            # Get S3 bucket and object information
            bucket_name = record['s3']['bucket']['name']
            object_key = urllib.parse.unquote_plus(record['s3']['object']['key'], encoding='utf-8')
            object_size = record['s3']['object']['size']
            event_name = record['eventName']
            
            logger.info(f"Processing {event_name} for object {object_key} in bucket {bucket_name}")
            
            # Get object metadata
            try:
                response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
                content_type = response.get('ContentType', 'unknown')
                last_modified = response.get('LastModified', datetime.utcnow()).isoformat()
                etag = response.get('ETag', '').strip('"')
            except Exception as e:
                logger.error(f"Error getting object metadata: {str(e)}")
                content_type = 'unknown'
                last_modified = datetime.utcnow().isoformat()
                etag = 'unknown'
            
            # Try to read file content for text files (optional - for demonstration)
            file_content_preview = None
            if content_type and ('text' in content_type or 'json' in content_type or 'csv' in content_type):
                try:
                    # Only read first 1000 characters for preview
                    obj_response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
                    content = obj_response['Body'].read(1000).decode('utf-8', errors='ignore')
                    file_content_preview = content[:500]  # Store only first 500 chars
                except Exception as e:
                    logger.warning(f"Could not read file content: {str(e)}")
                    file_content_preview = "Could not read content"
            
            # Prepare item for DynamoDB
            timestamp = datetime.utcnow().isoformat()
            item = {
                'file_key': object_key,
                'timestamp': timestamp,
                'bucket_name': bucket_name,
                'file_size': object_size,
                'content_type': content_type,
                'last_modified': last_modified,
                'etag': etag,
                'event_name': event_name,
                'processed_at': timestamp
            }
            
            # Add content preview if available
            if file_content_preview:
                item['content_preview'] = file_content_preview
            
            # Store in DynamoDB
            try:
                table.put_item(Item=item)
                logger.info(f"Successfully stored data for {object_key} in DynamoDB")
            except Exception as e:
                logger.error(f"Error storing data in DynamoDB: {str(e)}")
                raise
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully processed {len(event["Records"])} records',
                'processed_files': [record['s3']['object']['key'] for record in event['Records']]
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing S3 event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to process S3 event'
            })
        }