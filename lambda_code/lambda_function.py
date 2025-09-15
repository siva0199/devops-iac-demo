import json
import boto3
import base64

s3 = boto3.client('s3')

def lambda_handler(event, context):
    if event['httpMethod'] == 'POST':
        body = base64.b64decode(event['body'])
        s3.put_object(Bucket='demo-upload-bucket', Key='uploaded_file.txt', Body=body)
        return {
            'statusCode': 200,
            'body': json.dumps('File uploaded!')
        }
    return {'statusCode': 400}
